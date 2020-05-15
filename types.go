/// Global types, used anywhere in the package
package main
import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
)
const (
	MAX_BLOCKS_CHAIN_SPLIT = 128
)
type OrderType uint8
const (
	OrderTypeBid		OrderType = 0
	OrderTypeAsk		OrderType = 1
)
type OrderAction uint8
const(
	OrderActionCreate	OrderAction = 0
	OrderActionCancel	OrderAction = 1
	OrderActionFill		OrderAction = 2
)
type TokenType uint8
const(
	ReputationToken		TokenType = 0
	DisputeCrowdsourcer TokenType = 1
	ParticipationToken	TokenType = 2
)
type MarketStatus uint8
const (
	MktStatusTraded		MarketStatus = 0
	MktStatusReporting	MarketStatus = 1
	MktStatusReported	MarketStatus = 2
	MktStatusDisputing	MarketStatus = 3
	MktStatusFinalized	MarketStatus = 4
	MktStatusFinInvalid	MarketStatus = 5
)
type BlockNumber int64	// -1 is used to mark 'block not set' for the database

type EventSequencer struct {	// determines the order for contained events
	unordered_list		[]*types.Log
}
type ExtraInfo struct {
	Categories			[]string	`json:"categories"`
	Description			string		`json:"description"`
	Tags				[]string	`json:"tags"`
	LongDescription		string		`json:"longDescription"`
}
type MarketCreatedEvt struct {
	Universe             common.Address
	EndTime              *big.Int
	ExtraInfo            string
	Market               common.Address
	MarketCreator        common.Address
	DesignatedReporter   common.Address
	FeePerCashInAttoCash *big.Int
	Prices               []*big.Int
	MarketType           uint8
	NumTicks             *big.Int
	Outcomes             [][32]byte
	NoShowBond           *big.Int
	Timestamp            *big.Int
	Raw                  types.Log // Blockchain specific contextual infos
}
type MktOrderEvt struct {
	Universe     common.Address
	Market       common.Address
	EventType    uint8
	OrderType    uint8
	OrderId      [32]byte
	TradeGroupId [32]byte
	AddressData  []common.Address
	Uint256Data  []*big.Int
	Raw          types.Log // Blockchain specific contextual infos
}
type MarketOIChangedEvt struct {
	Universe common.Address
	Market   common.Address
	MarketOI *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}
type MktFinalizedEvt struct {
	Universe                common.Address
	Market                  common.Address
	Timestamp               *big.Int
	WinningPayoutNumerators []*big.Int
	Raw                     types.Log // Blockchain specific contextual infos
}
type InitialReportSubmittedEvt struct {
	Universe             common.Address
	Reporter             common.Address
	Market               common.Address
	InitialReporter      common.Address
	AmountStaked         *big.Int
	IsDesignatedReporter bool
	PayoutNumerators     []*big.Int
	Description          string
	NextWindowStartTime  *big.Int
	NextWindowEndTime    *big.Int
	Timestamp            *big.Int
	Raw                  types.Log // Blockchain specific contextual infos
}
type MktVolumeChangedEvt struct {
	Universe       common.Address
	Market         common.Address
	Volume         *big.Int
	OutcomeVolumes []*big.Int
	Timestamp      *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}
type DisputeCrowdsourcerContributionEvt struct {
	Universe            common.Address
	Reporter            common.Address
	Market              common.Address
	DisputeCrowdsourcer common.Address
	AmountStaked        *big.Int
	Description         string
	PayoutNumerators    []*big.Int
	CurrentStake        *big.Int
	StakeRemaining      *big.Int
	DisputeRound        *big.Int
	Timestamp           *big.Int
	Raw                 types.Log // Blockchain specific contextual infos
}
type TokensTransferred struct {
	Universe  common.Address
	Token     common.Address
	From      common.Address
	To        common.Address
	Value     *big.Int
	TokenType uint8
	Market    common.Address
	Raw       types.Log // Blockchain specific contextual infos
}
type TokenBalanceChanged struct {
	Universe  common.Address
	Owner     common.Address
	Token     common.Address
	TokenType uint8
	Market    common.Address
	Balance   *big.Int
	Outcome   *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}
type ShareTokenBalanceChanged struct {
	Universe common.Address
	Account  common.Address
	Market   common.Address
	Outcome  *big.Int
	Balance  *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}
type CancelZeroXOrder struct {
	Universe  common.Address
	Market    common.Address
	Account   common.Address
	Outcome   *big.Int
	Price     *big.Int
	Amount    *big.Int
	OrderType uint8
	OrderHash [32]byte
	Raw       types.Log // Blockchain specific contextual infos
}
type TransferBatch struct {
	Operator common.Address
	From     common.Address
	To       common.Address
	Ids      []*big.Int
	Values   []*big.Int
	Raw      types.Log // Blockchain specific contextual infos
}
type TransferSingle struct {
	Operator common.Address
	From     common.Address
	To       common.Address
	Id       *big.Int
	Value    *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}
type ProfitLossChanged struct {
	Universe       common.Address
	Market         common.Address
	Account        common.Address
	Outcome        *big.Int
	NetPosition    *big.Int
	AvgPrice       *big.Int
	RealizedProfit *big.Int
	FrozenFunds    *big.Int
	RealizedCost   *big.Int
	Timestamp      *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}
type Transfer struct {
	From  common.Address
	To    common.Address
	Value *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}
// 0x Exchange Events begin
type FillEvt struct {
	MakerAddress           common.Address
	FeeRecipientAddress    common.Address
	MakerAssetData         []byte
	TakerAssetData         []byte
	MakerFeeAssetData      []byte
	TakerFeeAssetData      []byte
	OrderHash              [32]byte
	TakerAddress           common.Address
	SenderAddress          common.Address
	MakerAssetFilledAmount *big.Int
	TakerAssetFilledAmount *big.Int
	MakerFeePaid           *big.Int
	TakerFeePaid           *big.Int
	ProtocolFeePaid        *big.Int
	Raw                    types.Log // Blockchain specific contextual infos
}
type OwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}
// 0x Exchange Events end
type TradingProceedsClaimed struct {
	Universe        common.Address
	Sender          common.Address
	Market          common.Address
	Outcome         *big.Int
	NumShares       *big.Int
	NumPayoutTokens *big.Int
	Fees            *big.Int
	Timestamp       *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}
type ApprovalForAll struct {
	Owner    common.Address
	Operator common.Address
	Approved bool
	Raw      types.Log // Blockchain specific contextual infos
}
type Approval struct {
	Owner   common.Address
	Spender common.Address
	Value   *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}
// Backend Types
type InfoMarket struct {
	MktAddr			string
	MktAddrSh		string	// short address (with .. in the middle)
	Signer			string
	SignerSh		string
	MktCreator		string
	MktCreatorSh	string	// short address (with .. in the middle)
	EndDate			string
	Description		string
	LongDesc		string
	Categories		string
	Outcomes		string
	MktType			string
	Status			string
	Fee				float64
	OpenInterest	float64
	CurVolume		float64
}
type InfoCategories struct {
	CatId			int64
	Category		string
	Subcategories	[]string
}
type MarketTrade struct {
	MktAddr			string
	MktAddrSh		string	// short address (with .. in the middle)
	FillerAddr		string
	FillerAddrSh	string	// short address (with .. in the middle)
	Type			string
	Direction		string
	Date			string
	Price			float64
	Amount			float64
	Outcome			int
	OutcomeStr		string
}
type OutcomeVol struct {
	Outcome			int
	OutcomeStr		string
	Volume			float64
	LastPrice		float64
	MktType			int
	MktAddr			string
}
type ZxMeshOrderSpec struct {
	Market			common.Address
	Price			*big.Int
	Outcome			uint8
	Type			uint8
}
type DepthEntry struct {
	Price			float64
	Volume			float64
	ExpiresTs		int64
	TotalBids		int32
	TotalAsks		int32
	TotalCancel		int32
	WalletAddr		string
	WalletAddrSh	string	// short version of the addr
	EOAAddr			string
	EOAAddrSh		string	// short version of the addr
	DateCreated		string
	Expires			string
}
type MarketDepth struct {
	Bids			[]DepthEntry
	Asks			[]DepthEntry
}
