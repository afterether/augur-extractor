package main

import (
	"log"
	"os"
	"fmt"

	"github.com/gin-gonic/gin"
	"github.com/ethereum/go-ethereum/ethclient"
	//"github.com/ethereum/go-ethereum/common"
	//"github.com/ethereum/go-ethereum/accounts/abi"
	//"github.com/ethereum/go-ethereum/accounts/abi/bind"

	. "augur-extractor/primitives"
)
var (
	RPC_URL = os.Getenv("AUGUR_ETH_NODE_RPC_URL")
	rpcclient *ethclient.Client

	augur_srv *AugurServer

	// contracts
	all_contracts map[string]interface{}

/*discontinued
	dai_addr common.Address
	rep_addr common.Address
*/
	caddrs *ContractAddresses

	ctrct_dai_token *DAICash
	ctrct_rep_token *RepTok

	// thes variables should be removed on the next code reorg task
	market_order_id int64 = 0
	fill_order_id int64 = 0

	Error   *log.Logger
	Info    *log.Logger
)
func initialize() {

	/*discontinued
	contract_addresses := new(ContractAddresses)
	contract_addresses.Dai_addr = &dai_addr
	contract_addresses.Reputation_addr = &rep_addr
	Init_contract_addresses(contract_addresses)
	*/
	caddrs_obj,err := augur_srv.storage.Get_contract_addresses()
	if err!=nil {
		Fatalf("Can't find contract addresses in 'contract_addresses' table")
	}
	caddrs=&caddrs_obj

}
func main() {

	Info = log.New(os.Stdout,"INFO: ",log.Ldate|log.Ltime|log.Lshortfile)
	Error = log.New(os.Stderr,"ERROR: ",log.Ldate|log.Ltime|log.Lshortfile)

	augur_srv = create_augur_server(&market_order_id)

	initialize()

	if len(RPC_URL) == 0 {
		fmt.Printf("Configuration error: RPC URL of Ethereum node is not set."+
			"Calls to contracts are disabled. " +
			" Please set AUGUR_ETH_NODE_RPC environment variable")
	} else {
		var err error
		rpcclient, err = ethclient.Dial(RPC_URL)
		if err != nil {
			log.Fatal(err)
		}
		// init contracts
		fmt.Println("init DAI contract with addr %v\n",caddrs.Dai_addr.String())
		ctrct_dai_token,err = NewDAICash(caddrs.Dai_addr,rpcclient)
		if err != nil {
			Fatalf("Couldn't initialize DAI Cash contract: %v\n",err)
		}

		fmt.Println("init REP contract with addr %v\n",caddrs.Reputation_addr.String())
		ctrct_rep_token,err = NewRepTok(caddrs.Reputation_addr,rpcclient)
		if err != nil {
			Fatalf("Couldn't initialize Rep Token contract: %v\n",err)
		}
	}

	port_plain := os.Getenv("AUGUR_HTTP_PORT")
	port_secure := os.Getenv("AUGUR_HTTPS_PORT")

	if port_plain == "" {
		port_plain = "9090"
		log.Printf("Defaulting plain HTTP to port %s", port_plain)
	}
	if port_secure== "" {
		port_secure= "9443"
		log.Printf("Defaulting secure protocol to port %s", port_secure)
	}


	r := gin.New()
	r.LoadHTMLGlob("html/templates/*html")
	r.Use(gin.Logger())

	// Main HTML
	r.GET("/", main_page)
	r.GET("/index.html", main_page)
	r.GET("/index.htm", main_page)
	r.GET("/INDEX.HTM", main_page)

	// All the other dynamic HTML pages
	r.GET("/markets.html",markets)
	r.GET("/statistics.html",statistics)
	r.GET("/categories.html",categories)
	r.GET("/explorer.html",explorer)
	r.GET("/market/:market",  market_info)
	r.GET("/fulltradelist/:market",  full_trade_list)
	r.GET("/mdepth/:market/:outcome", market_depth)
	r.GET("/deptha/:market_aid/:outcome", market_depth_ajax)
	r.GET("/mphist/:market/:outcome", market_price_history)
	r.GET("/search", search)
	r.GET("/money/:addr",  read_money)
	r.GET("/order/:order",  order)
	r.GET("/category/:catid",  category)
	r.GET("/user/:addr",  user_info)
	r.GET("/fullreports/:addr",  full_reports)
	r.GET("/umarkets/:addr",  user_markets)
	r.GET("/udw/:addr",  user_deposits_withdrawals)
	r.GET("/block/:block_num",  block_info)
	r.GET("/topusers.html",top_users)
	r.GET("/mdstat/:market_aid/:outcome_idx/:last_oo_id",market_depth_status)

	r.Static("/imgs", "./html/imgs")
	r.Static("/res", "./html/res")			// resources (static)
	r.StaticFile("/favicon.ico", "./html/res/favicon.ico")

	// Listen and serve on defined port
	log.Printf("Listening on port %s", port_plain)
	r.Run(":" + port_plain)
}
