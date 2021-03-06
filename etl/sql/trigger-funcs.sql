CREATE OR REPLACE FUNCTION on_oi_chg_insert() RETURNS trigger AS  $$ --updates open interest of the market
DECLARE
BEGIN

	UPDATE market SET open_interest = NEW.oi WHERE market.market_aid=NEW.market_aid;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_volume_insert() RETURNS trigger AS  $$ --updates volume of the market
DECLARE
BEGIN

	UPDATE market SET cur_volume = NEW.volume WHERE market.market_aid=NEW.market_aid;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_oorders_insert() RETURNS trigger AS  $$ --updates open order statistics
DECLARE
	v_cnt numeric;
BEGIN

	IF NEW.otype = 0 THEN
		UPDATE oostats AS s
			SET num_bids = (num_bids + 1)
			WHERE	(s.market_aid = NEW.market_aid) AND
					(s.eoa_aid = NEW.eoa_aid) AND
					(s.outcome_idx = NEW.outcome_idx);
		GET DIAGNOSTICS v_cnt = ROW_COUNT;
		IF v_cnt = 0 THEN
			INSERT	INTO oostats(market_aid,eoa_aid,outcome_idx,num_bids)
					VALUES(NEW.market_aid,NEW.eoa_aid,NEW.outcome_idx,1)
					ON CONFLICT(eoa_aid) DO NOTHING;

		END IF;
	END IF;
	IF NEW.otype = 1 THEN
		UPDATE oostats AS s
			SET num_asks = (num_asks + 1)
			WHERE	(s.market_aid = NEW.market_aid) AND
					(s.eoa_aid = NEW.eoa_aid) AND
					(s.outcome_idx = NEW.outcome_idx);
		GET DIAGNOSTICS v_cnt = ROW_COUNT;
		IF v_cnt = 0 THEN
			INSERT	INTO oostats(market_aid,eoa_aid,outcome_idx,num_asks)
					VALUES(NEW.market_aid,NEW.eoa_aid,NEW.outcome_idx,1)
					ON CONFLICT(eoa_aid) DO NOTHING;
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_oorders_delete() RETURNS trigger AS  $$ -- reverts order statistics on delete
DECLARE
BEGIN

	IF OLD.otype = 0 THEN
		UPDATE oostats AS s
			SET num_bids = (num_bids - 1)
			WHERE	(s.market_aid = OLD.market_aid) AND
					(s.eoa_aid = OLD.eoa_aid) AND
					(s.outcome_idx = OLD.outcome_idx);
	END IF;
	IF OLD.otype = 1 THEN
		UPDATE oostats AS s
			SET num_asks = (num_asks - 1)
			WHERE	(s.market_aid = OLD.market_aid) AND
					(s.eoa_aid = OLD.eoa_aid) AND
					(s.outcome_idx = OLD.outcome_idx);
	END IF;

	RETURN OLD;
END;
$$ LANGUAGE plpgsql;
-- update all the statistics on insertion into 'market' table
CREATE OR REPLACE FUNCTION on_market_insert() RETURNS trigger AS  $$
DECLARE
	v_cnt numeric;
BEGIN

	UPDATE ustats AS s
			SET markets_created = (markets_created + 1),
				validity_bonds = (validity_bonds + NEW.validity_bond)
			WHERE s.eoa_aid = NEW.eoa_aid;

	GET DIAGNOSTICS v_cnt = ROW_COUNT;
	IF v_cnt = 0 THEN
		INSERT	INTO ustats(eoa_aid,wallet_aid,markets_created,validity_bonds)
				VALUES(NEW.eoa_aid,NEW.wallet_aid,1,NEW.validity_bond);
	END IF;

	UPDATE main_stats
		SET markets_count = (markets_count + 1), active_count = (active_count +1);
	IF NEW.market_type = 0 THEN
		UPDATE main_stats SET yesno_count = (yesno_count + 1);
	END IF;
	IF NEW.market_type = 1 THEN
		UPDATE main_stats SET categ_count = (categ_count + 1);
	END IF;
	IF NEW.market_type = 2 THEN
		UPDATE main_stats SET scalar_count = (scalar_count + 1);
	END IF;

	UPDATE category set total_markets = (total_markets + 1) WHERE cat_id=NEW.cat_id;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_market_delete() RETURNS trigger AS  $$
DECLARE
	v_cnt numeric;
BEGIN

	UPDATE ustats AS s
			SET markets_created = markets_created - 1,
				validity_bonds = validity_bonds - OLD.validity_bond
			WHERE s.eoa_aid = OLD.eoa_aid;

	GET DIAGNOSTICS v_cnt = ROW_COUNT;
	IF v_cnt = 0 THEN	-- this condition won't be true during normal operation
		INSERT	INTO ustats(eoa_aid,wallet_aid,markets_created)
				VALUES(OLD.eoa_aid,OLD.wallet_aid,0);
	END IF;

	UPDATE main_stats
		SET markets_count = (markets_count - 1), active_count = (active_count - 1);
	IF OLD.market_type = 0 THEN
		UPDATE main_stats SET yesno_count = (yesno_count - 1);
	END IF;
	IF OLD.market_type = 1 THEN
		UPDATE main_stats SET categ_count = (categ_count - 1);
	END IF;
	IF OLD.market_type = 2 THEN
		UPDATE main_stats SET scalar_count = (scalar_count - 1);
	END IF;

	UPDATE category set total_markets = (total_markets - 1) WHERE cat_id=OLD.cat_id;

	RETURN OLD;
END;
$$ LANGUAGE plpgsql;
-- update all the statistics on insertion into 'mktord' table
CREATE OR REPLACE FUNCTION on_mktord_insert() RETURNS trigger AS  $$
DECLARE
	v_cnt numeric;
BEGIN

	-- Make sure user stats record exists
	INSERT INTO ustats(eoa_aid,wallet_aid) VALUES(NEW.eoa_aid,NEW.wallet_aid)
		ON CONFLICT(eoa_aid) DO NOTHING;
	INSERT INTO ustats(eoa_aid,wallet_aid) VALUES(NEW.eoa_fill_aid,NEW.wallet_fill_aid)
		ON CONFLICT(eoa_aid) DO NOTHING;

	-- Update statistics for the Creator of the Order (Seller)
	UPDATE trd_mkt_stats AS s
			SET total_trades = (total_trades + 1),
				volume_traded = (volume_traded + NEW.amount_filled)
			WHERE	s.eoa_aid = NEW.eoa_aid AND
					s.market_aid = NEW.market_aid;

	GET DIAGNOSTICS v_cnt = ROW_COUNT;
	IF v_cnt = 0 THEN
		INSERT	INTO trd_mkt_stats(eoa_aid,wallet_aid,market_aid,total_trades,volume_traded)
				VALUES(NEW.eoa_aid,NEW.wallet_aid,NEW.market_aid,1,NEW.amount_filled);
	END IF;
	UPDATE ustats
		SET total_trades = (total_trades + 1),
			volume_traded = (volume_traded + NEW.amount_filled)
		WHERE eoa_aid=NEW.eoa_aid;

	-- Update statistics for the Filler of the Order (Buyer)
	UPDATE trd_mkt_stats AS s
			SET total_trades = (total_trades + 1),
				volume_traded = (volume_traded + NEW.amount_filled)
			WHERE	s.eoa_aid = NEW.eoa_fill_aid AND
					s.market_aid = NEW.market_aid;

	GET DIAGNOSTICS v_cnt = ROW_COUNT;
	IF v_cnt = 0 THEN
		INSERT	INTO trd_mkt_stats(eoa_aid,wallet_aid,market_aid,total_trades,volume_traded)
				VALUES(NEW.eoa_fill_aid,NEW.wallet_fill_aid,NEW.market_aid,1,NEW.amount_filled);
	END IF;
	UPDATE ustats
		SET total_trades = (total_trades + 1),
			volume_traded = (volume_traded + 1)
		WHERE eoa_aid=NEW.eoa_fill_aid;

	-- Note: for Main statistics a trade between 2 users is counted as single trade (i.e its a +1)_
	-- 			but from the point of the User we have +1 for Creator and +1 for Filler (so, its 2 trades)
	UPDATE main_stats SET trades_count = (trades_count + 1);
	UPDATE market SET total_trades = (total_trades + 1) WHERE market_aid = NEW.market_aid;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_mktord_delete() RETURNS trigger AS  $$
DECLARE
	v_cnt numeric;
BEGIN

	-- Make sure user stats record exists
	INSERT INTO ustats(eoa_aid,wallet_aid) VALUES(OLD.eoa_aid,OLD.wallet_aid)
		ON CONFLICT(eoa_aid) DO NOTHING;
	INSERT INTO ustats(eoa_aid,wallet_aid) VALUES(OLD.eoa_fill_aid,OLD.wallet_fill_aid)
		ON CONFLICT(eoa_aid) DO NOTHING;

	-- Update statistics for the Creator of the Order (Seller)
	UPDATE trd_mkt_stats AS s
			SET total_trades = (total_trades - 1),
				volume_traded = (volume_traded - OLD.amount_filled)
			WHERE	s.eoa_aid = OLD.eoa_aid AND
					s.market_aid = OLD.market_aid;

	GET DIAGNOSTICS v_cnt = ROW_COUNT;
	IF v_cnt = 0 THEN	-- this condition won't be true during normal operation
		INSERT	INTO trd_mkt_stats(eoa_aid,wallet_aid,market_aid)
				VALUES(OLD.eoa_aid,OLD.wallet_aid,OLD.market_aid);
	END IF;

	-- Update statistics for the Filler of the Order (Buyer)
	UPDATE trd_mkt_stats AS s
			SET total_trades = (total_trades - 1),
				volume_traded = (volume_traded - OLD.amount_filled)
			WHERE	s.eoa_aid = OLD.eoa_fill_aid AND
					s.market_aid = OLD.market_aid;

	GET DIAGNOSTICS v_cnt = ROW_COUNT;
	IF v_cnt = 0 THEN
		INSERT	INTO trd_mkt_stats(eoa_aid,wallet_aid,market_aid)
				VALUES(OLD.eoa_fill_aid,OLD.wallet_fill_aid,OLD.market_aid);
	END IF;

	UPDATE main_stats SET trades_count = (trades_count - 1);
	UPDATE market SET total_trades = (total_trades - 1) WHERE market_aid = OLD.market_aid;

	RETURN OLD;
END;
$$ LANGUAGE plpgsql;
-- update all the statistics on insertion into 'trd_mkt_stats' table
CREATE OR REPLACE FUNCTION on_trd_mkt_stats_insert() RETURNS trigger AS  $$
DECLARE
	v_cnt numeric;
BEGIN

	RAISE NOTICE 'insert into trd_mkt_stats for % ',NEW.eoa_aid;
	-- Update statistics for the Creator of the Order (Seller)
	UPDATE ustats AS s
			SET markets_traded = (markets_traded + 1)
			WHERE	s.eoa_aid = NEW.eoa_aid;

	GET DIAGNOSTICS v_cnt = ROW_COUNT;
	IF v_cnt = 0 THEN
		RAISE EXCEPTION 'Corresponding row in ustats table doesnt exist';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_trd_mkt_stats_delete() RETURNS trigger AS  $$
DECLARE
	v_cnt numeric;
BEGIN

	-- Update statistics for the Creator of the Order (Seller)
	SELECT COUNT(*) AS num_rows
		FROM trd_mkt_stats AS s
		WHERE	s.eoa_aid = OLD.eoa_aid AND
				s.market_aid = OLD.market_aid INTO v_cnt;

	IF v_cnt = 0 THEN
		UPDATE ustats AS s
			SET markets_traded = (markets_traded - 1)
			WHERE	s.eoa_aid = OLD.eoa_aid;
	END IF;

	RETURN OLD;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_trd_mkt_stats_update() RETURNS trigger AS  $$
DECLARE
	v_cnt numeric;
BEGIN

	-- This function consoldates statistics from different per-User market records 
	-- into a single User statistics record

	-- Begin of update profit loss
	UPDATE ustats AS s
			SET profit_loss = (profit_loss + (NEW.profit_loss - OLD.profit_loss)),
				money_at_stake = (money_at_stake + (NEW.frozen_funds - OLD.frozen_funds))
			WHERE	s.eoa_aid = NEW.eoa_aid;

	GET DIAGNOSTICS v_cnt = ROW_COUNT;
	IF v_cnt = 0 THEN
		RAISE EXCEPTION 'Corresponding row in ustats table doesnt exist';
	END IF;
	-- End of update profit loss

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_mktfin_insert() RETURNS trigger AS  $$
DECLARE
	v_validity_bond decimal;
	v_eoa_aid bigint;
BEGIN

	UPDATE market
		SET fin_timestamp = NEW.fin_timestamp,
			winning_payouts=NEW.winning_payouts,
			winning_outcome=NEW.winning_outcome
		WHERE market.market_aid=NEW.market_aid;
	UPDATE main_stats SET active_count = (active_count - 1);
	SELECT eoa_aid,validity_bond FROM market WHERE market_aid = NEW.market_aid INTO v_eoa_aid,v_validity_bond;
	UPDATE ustats SET validity_bonds = validity_bonds - v_validity_bond
		WHERE eoa_aid = v_eoa_aid;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_mktfin_delete() RETURNS trigger AS  $$
DECLARE
	v_validity_bond decimal;
	v_eoa_aid bigint;
BEGIN

	UPDATE main_stats SET active_count = (active_count + 1);
	SELECT eoa_aid,validity_bond FROM market WHERE market_aid = OLD.market_aid INTO v_eoa_aid,v_validity_bond;
	UPDATE ustats SET validity_bonds = validity_bonds + v_validity_bond
		WHERE eoa_aid = v_eoa_aid;

	RETURN OLD;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_profit_loss_insert() RETURNS trigger AS  $$
DECLARE
BEGIN

	IF NEW.mktord_id > 0 THEN 
		IF NEW.closed_position = 0 THEN
			UPDATE trd_mkt_stats
				SET frozen_funds = (frozen_funds + NEW.frozen_funds),
					profit_loss = (profit_loss + NEW.immediate_profit)
				WHERE market_aid = NEW.market_aid AND eoa_aid = NEW.eoa_aid;
			UPDATE main_stats SET money_at_stake = money_at_stake + NEW.frozen_funds;
			UPDATE market
				SET money_at_stake = money_at_stake + NEW.frozen_funds WHERE market_aid = NEW.market_aid;
		END IF;
		IF NEW.closed_position = 1 THEN
			RAISE EXCEPTION 'You cant insert a record with closed_position = 1, undefined behavior';
		END IF;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_profit_loss_delete() RETURNS trigger AS  $$
DECLARE
BEGIN

	IF OLD.mktord_id > 0 THEN
		IF OLD.closed_position = 1 THEN
			UPDATE trd_mkt_stats AS s
				SET profit_loss = (profit_loss - OLD.realized_profit)
				WHERE	s.market_aid = OLD.market_aid AND
						s.eoa_aid = OLD.eoa_aid;
		END IF;
		IF OLD.closed_position = 0 THEN
			UPDATE trd_mkt_stats AS s
				SET frozen_funds = (frozen_funds + OLD.frozen_funds),
					profit_loss = (profit_loss - OLD.immediate_profits)
				WHERE market_aid = OLD.market_aid AND eoa_aid = OLD.eoa_aid;
			UPDATE main_stats SET money_at_stake = money_at_stake + OLD.frozen_funds;
			UPDATE market 
				SET money_at_stake = money_at_stake + OLD.frozen_funds WHERE market_aid = OLD.market_aid;
		END IF;
	END IF;

	RETURN OLD;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_profit_loss_update() RETURNS trigger AS  $$
DECLARE
BEGIN

	if NEW.mktord_id > 0 THEN
		IF NEW.closed_position != OLD.closed_position THEN
			IF NEW.closed_position = 1 THEN
				-- profit loss is realized, either by selling part of position or Market finalization
				-- Update statistics on profits
				-- Note: here frozen funds are substrated in total becase Augur updates this value in
				--		ProfitLoss event and this value is added during INSERT operation in profit_loss table
				--		(if we don't subtract it we are going to get duplicated amount of frozen funds)
				UPDATE trd_mkt_stats AS s
						SET profit_loss = (profit_loss + NEW.realized_profit + NEW.immediate_profit),
							frozen_funds = (frozen_funds - OLD.frozen_funds)
						WHERE	s.eoa_aid = NEW.eoa_aid AND
								s.market_aid = NEW.market_aid;
				UPDATE main_stats SET money_at_stake = money_at_stake - OLD.frozen_funds;
				UPDATE market
					SET money_at_stake = money_at_stake - OLD.frozen_funds WHERE market_aid = OLD.market_aid;
			END IF;
			IF NEW.closed_position = 0 THEN
				-- nobody should update closed_position from 1 to 0 , once it is closed it is forever
				RAISE EXCEPTION 'You cant change closed_position field by hand, undefined behaviur';
			END IF;
		END IF;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- reporting triggers
CREATE OR REPLACE FUNCTION on_report_insert() RETURNS trigger AS  $$ --updates volume of the market
DECLARE
	v_cnt numeric;
BEGIN

	-- Make sure user stats record exists
	INSERT INTO ustats(eoa_aid,wallet_aid) VALUES(NEW.eoa_aid,NEW.wallet_aid)
		ON CONFLICT(eoa_aid) DO NOTHING;
	-- Update statistics for the Reporter
	UPDATE trd_mkt_stats AS s
			SET total_reports = (total_reports + 1)
			WHERE	s.eoa_aid = NEW.eoa_aid AND
					s.market_aid = NEW.market_aid;
	GET DIAGNOSTICS v_cnt = ROW_COUNT;
	IF v_cnt = 0 THEN
		INSERT	INTO trd_mkt_stats(eoa_aid,wallet_aid,market_aid)
				VALUES(NEW.eoa_aid,NEW.wallet_aid,NEW.market_aid);
	END IF;
	UPDATE ustats
		SET total_reports = (total_reports + 1)
		WHERE	eoa_aid = NEW.eoa_aid;
	IF NEW.is_designated IS TRUE THEN
		UPDATE market
			SET designated_outcome = NEW.outcome_idx
			WHERE market_aid = NEW.market_aid;
		UPDATE ustats
			SET total_designated = (total_designated + 1)
			WHERE eoa_aid = NEW.eoa_aid;
	END IF;
	IF NEW.is_initial THEN
		UPDATE market
			SET initial_outcome = NEW.outcome_idx
			WHERE market_aid = NEW.market_aid;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_report_delete() RETURNS trigger AS  $$
DECLARE
	v_cnt numeric;
BEGIN

	-- Make sure user stats record exists
	INSERT INTO ustats(eoa_aid,wallet_aid) VALUES(OLD.eoa_aid,OLD.wallet_aid)
		ON CONFLICT(eoa_aid) DO NOTHING;
	-- Update statistics for the Reporter
	UPDATE trd_mkt_stats AS s
			SET total_reports = (total_reports - 1)
			WHERE	s.eoa_aid = OLD.eoa_aid AND
					s.market_aid = OLD.market_aid;
	GET DIAGNOSTICS v_cnt = ROW_COUNT;
	IF v_cnt = 0 THEN
		INSERT	INTO trd_mkt_stats(eoa_aid,wallet_aid,market_aid)
				VALUES(OLD.eoa_aid,OLD.wallet_aid,OLD.market_aid);
	END IF;
	UPDATE ustats
		SET total_reports = (total_reports - 1)
		WHERE	eoa_aid = OLD.eoa_aid;
	IF OLD.is_designated THEN
		UPDATE market
			SET designated_outcome = -1
			WHERE market_aid = OLD.market_aid;
		UPDATE ustats
			SET total_designated = (total_designated - 1)
			WHERE	eoa_aid = OLD.eoa_aid;
	END IF;
	IF OLD.is_initial THEN
		UPDATE market
			SET initial_outcome = -1
			WHERE market_aid = OLD.market_aid;
	END IF;
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_tx_insert() RETURNS trigger AS  $$
DECLARE
BEGIN

	UPDATE block
		SET  num_tx = num_tx + 1
		WHERE block_num=NEW.block_num;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_tx_delete() RETURNS trigger AS  $$
DECLARE
BEGIN

	UPDATE block
		SET  num_tx = num_tx - 1
		WHERE block_num=OLD.block_num;
	RETURN OLD;

END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_dai_transf_insert() RETURNS trigger AS  $$
DECLARE
	v_eoa_aid bigint;
	v_cnt numeric;
	v_augur bool;	-- true if this transfer is made to Augur Wallet account
BEGIN

	v_augur := false;
	SELECT eoa_aid FROM ustats WHERE wallet_aid = NEW.from_aid INTO v_eoa_aid;
	GET DIAGNOSTICS v_cnt = ROW_COUNT;
	IF v_cnt > 0 THEN
		v_augur := true;
	END IF;
	INSERT INTO dai_bal(block_num,tx_id,dai_transf_id,aid,amount,augur,internal)
			VALUES(NEW.block_num,NEW.tx_id,NEW.id,NEW.from_aid,-NEW.amount,v_augur,NEW.internal);


	v_augur := false;
	SELECT eoa_aid FROM ustats WHERE wallet_aid = NEW.to_aid INTO v_eoa_aid;
	GET DIAGNOSTICS v_cnt = ROW_COUNT;
	IF v_cnt > 0 THEN
		v_augur := true;
	END IF;
	INSERT INTO dai_bal(block_num,tx_id,dai_transf_id,aid,amount,augur,internal)
			VALUES(NEW.block_num,NEW.tx_id,NEW.id,NEW.to_aid,NEW.amount,v_augur,NEW.internal);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_dai_transf_delete() RETURNS trigger AS  $$
DECLARE
BEGIN

	DELETE FROM dai_bal WHERE dai_transf_id = OLD.id;
	RETURN OLD;

END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_ustats_insert() RETURNS trigger AS  $$
DECLARE
BEGIN

	-- The transfers of DAI can happen before wallet is created, so we fix it
	UPDATE dai_bal SET augur = true WHERE aid = NEW.wallet_aid;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_dai_bal_update() RETURNS trigger AS  $$
DECLARE
BEGIN

	IF OLD.augur != NEW.augur THEN
		IF NEW.augur THEN
			UPDATE block AS b
				SET cash_flow = (cash_flow + (NEW.balance - OLD.balance))
				WHERE	b.block_num = NEW.block_num;
		END IF;
	ELSE
		IF NEW.augur THEN
			UPDATE block AS b
				SET cash_flow = (cash_flow + (NEW.balance - OLD.balance))
				WHERE	b.block_num = NEW.block_num;
		END IF;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_claim_funds_insert() RETURNS trigger AS  $$
DECLARE
BEGIN

	UPDATE trd_mkt_stats
--		SET frozen_funds = (frozen_funds - NEW.unfrozen_funds),
		SET	profit_loss = (profit_loss + NEW.final_profit)
		WHERE market_aid = NEW.market_aid AND eoa_aid = NEW.eoa_aid;
--	UPDATE main_stats SET money_at_stake = money_at_stake - NEW.unfrozen_funds;
--	UPDATE market
--		SET money_at_stake = money_at_stake - NEW.unfrozen_funds WHERE market_aid = NEW.market_aid;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION on_claim_funds_delete() RETURNS trigger AS  $$
DECLARE
BEGIN

	UPDATE trd_mkt_stats
		SET frozen_funds = (frozen_funds + OLD.unfrozen_funds),
			profit_loss = (profit_loss - OLD.final_profit)
		WHERE market_aid = OLd.market_aid AND eoa_aid = OLD.eoa_aid;
--	UPDATE main_stats SET money_at_stake = (money_at_stake + OLD.unfrozen_funds);
--	UPDATE market
--		SET money_at_stake = money_at_stake + OLD.unfrozen_funds WHERE market_aid = OLD.market_aid;
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;
