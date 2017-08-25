//////////////////////////////////////////////////////////////////////////////////////////
//																						//
//	Title: 						Clipper Capital ICO Smart Contract						//
//	Author: 					Marko Valentin Micic									//
//	Version: 					v0.1													//
//	Date of current version:	2017/08/24												//
//	Brief Description:			This is the smart contract that dictates how Clipper	//
//								Coin will be issued.									//
//																						//
//////////////////////////////////////////////////////////////////////////////////////////



import "./SafeMath.sol";
import "./Owned.sol";
import "./ClipperCoinStandardToken.sol";


contract ClipperCoinICO is Owned {
    using SafeMath for uint;

    /// Constant fields
    /// Total supply of Clipper Coins
    /// Maximum Duration of ICO
	uint public constant CCC_TOTAL_SUPPLY = 200000000 ether;
    uint public constant MAX_ICO_DURATION = 3 weeks;

    /// General Exchange Rate: 1 ether exchange 630 CCC
    /// Exchange rates for normal phase
    uint public constant PRICE_RATE_NORMAL = 630;
    /// Exchange rates for discount phase
    uint public constant PRICE_RATE_DISCOUNT = 787.5;   //(630 * 100 / 80);

    /// ------------------------------------------------------------------------------------
    /// |                                   |          |            |            |         |
    /// | PUBLIC SALE (PRESALE + OPEN SALE) | Partners |  Exchange	| Incentive  | Reserve |
    /// |               50%                 |   20%    |     15%    |     10%    |    5%   |
    /// ------------------------------------------------------------------------------------
    /// OPEN_SALE_STAKE + PRESALE_STAKE = 50; 50% sale for public
    uint public constant OPEN_SALE_STAKE = 25;  	// 25%  for open sale
    uint public constant PRESALE_STAKE = 25;     	// 25%  for presale (at a discount)

    // Reserved stakes
    uint public constant PARTNER_STAKE = 20;   		// 20%  for private sale
    uint public constant EXCHANGE_STAKE = 15; 		// 15%  sold to exchanges
    uint public constant INCENTIVE_STAKE = 10;     	// 10%  given to employees
    uint public constant RESERVE_STAKE = 5			// 5%   held in reserve

    uint public constant DIVISOR_STAKE = 100;

    /// Holder address for presale and reserved tokens
    /// TODO: change address to main net address before deploying
    /// TODO: create addresses to hold each of the various tokens
    address public constant PRESALE_HOLDER = 0xAd487A8b4b7283c7B4F432EF58FEE369fD1F8Ed7;

    // Addresses of Patrons                   
    address public constant PARTNER_HOLDER = 0x0000000000000000000000000000000000000000;
    address public constant EXCHANGE_HOLDER = 0x0000000000000000000000000000000000000000;
    address public constant INCENTIVE_HOLDER = 0x0000000000000000000000000000000000000000;
    address public constant RESERVE_HOLDER = 0x0000000000000000000000000000000000000000;

    uint public MAX_OPEN_SOLD = CCC_TOTAL_SUPPLY * OPEN_SALE_STAKE / DIVISOR_STAKE;
    ///**************************** CONFUSED ***************************************///
    uint public MAX_PARTNER_LIMIT = CCC_TOTAL_SUPPLY * (OPEN_SALE_STAKE / 3) / DIVISOR_STAKE;    
	///**************************** CONFUSED ***************************************///
	
    /// Fields that are only changed in constructor    
    /// All deposited ETH will be instantly forwarded to this address.
    address public cccport;
    /// Contribution start time
    uint public startTime;
    /// Contribution end time
    uint public endTime;

    /// Fields that can be changed by functions
    /// Accumulator for open sale sold tokens
    uint openSoldTokens;
    /// Normal sold tokens
    uint normalSoldTokens;
    ///**************************** CONFUSED ***************************************///
    /// The sum of reserved tokens for ICO stage 1
    uint public partnerReservedSum;
    ///**************************** CONFUSED ***************************************///
    /// Due to an emergency, set this to true to halt the contribution
    bool public halted; 
    /// ERC20 compliant Clipper Coin contract instance
    ClipperCoin public clipperCoin; 

    /// Quota for partners
    mapping (address => uint256) public partnersLimit;
    /// Accumulator for partner sold
    mapping (address => uint256) public partnersBought;
	
	///**************************** CONFUSED ***************************************///
    uint256 public normalBuyLimit = 60 ether;
	///**************************** CONFUSED ***************************************///
	
    /*
     * EVENTS
     */

    event NewSale(address indexed destAddress, uint ethCost, uint gotTokens);
    event PartnerAddressQuota(address indexed partnerAddress, uint quota);

    /*
     * MODIFIERS
     */

    modifier onlyWallet {
        require(msg.sender == cccport);
        _;
    }

    modifier notHalted() {
        require(!halted);
        _;
    }

    modifier initialized() {
        require(address(cccport) != 0x0);
        _;
    }    

    modifier notEarlierThan(uint x) {
        require(now >= x);
        _;
    }

    modifier earlierThan(uint x) {
        require(now < x);
        _;
    }

    modifier ceilingNotReached() {
        require(openSoldTokens < MAX_OPEN_SOLD);
        _;
    }  

    /**
     * CONSTRUCTOR 
     * 
     * @dev Initialize the Wanchain contribution contract
     * @param _cccport The escrow account address, all ethers will be sent to this address.
     * @param _startTime ICO start time
     */
    function ClipeprCoinContribution(address _wanport, uint _startTime){
    	require(_wanport != 0x0);

        halted = false;
    	cccport = _cccport;
    	startTime = _startTime;
    	endTime = startTime + MAX_CONTRIBUTION_DURATION;
        openSoldTokens = 0;
        ///**************************** CONFUSED ***************************************///
        partnerReservedSum = 0;
        ///**************************** CONFUSED ***************************************///
        normalSoldTokens = 0;
        /// Create Clipper Coin contract instance
    	clipperCoin = new ClipperCoin(this,startTime, endTime);

        /// Reserve tokens according Clipper Coin Capital ICO rules
    	uint stakeMultiplier = CCC_TOTAL_SUPPLY / DIVISOR_STAKE;
    	clipperCoin.mintToken(PRESALE_HOLDER, PRESALE_STAKE * stakeMultiplier);
        clipperCoin.mintToken(PARTNER_HOLDER, PARTNER_STAKE * stakeMultiplier);
        clipperCoin.mintToken(EXCHANGE_HOLDER, EXCHANGE_STAKE * stakeMultiplier);
        clipperCoin.mintToken(INCENTIVE_HOLDER, INCENTIVE_STAKE * stakeMultiplier);
        clipperCoin.mintToken(RESERVE_HOLDER, RESERVE_STAKE * stakeMultiplier);
    }

    /**
     * Fallback function 
     * 
     * @dev If anybody sends Ether directly to this  contract, they are purchasing
     * 		Clipper Coins
     */
    function () public payable notHalted ceilingNotReached{
    	buyClipperCoin(msg.sender);
    }

    /*
     * PUBLIC FUNCTIONS
     */

   function setNormalBuyLimit(uint256 limit)
        public
        initialized
        onlyOwner
        earlierThan(endTime)
    {
        normalBuyLimit = limit;
    }
	
	///**************************** CONFUSED ***************************************///
    /// @dev Sets the limit for a partner address. All the partner addresses
    /// will be able to get Clipper Coins during the contribution period within their
    /// own specific limit.
    /// This method should be called by the owner after the initialization
    /// and before the contribution end.
    /// @param setPartnerAddress Partner address
    /// @param limit Limit for the partner address,the limit is CCC not ETHER
    function setPartnerQuota(address setPartnerAddress, uint256 limit) 
        public 
        initialized 
        onlyOwner
        earlierThan(endTime)
    {
        require(limit > 0 && limit <= MAX_PARTNER_LIMIT);
        partnersLimit[setPartnerAddress] = limit;
        partnerReservedSum += limit;
        PartnerAddressQuota(setPartnerAddress, limit);
    }
    ///**************************** CONFUSED ***************************************///

    /// @dev Exchange msg.value ether to CCC for account recepient
    /// @param recipient CCC tokens receiver
    function buyClipperCoin(address recipient) 
        public 
        payable 
        notHalted 
        initialized 
        ceilingNotReached 
        notEarlierThan(startTime)
        earlierThan(endTime)
        returns (bool) 
    {
    	require(recipient != 0x0);
    	require(msg.value >= 0.1 ether);

    	if (partnersLimit[recipient] > 0)
    		buyFromPartner(recipient);
    	else {
    		require(msg.value <= normalBuyLimit);
    		buyNormal(recipient);
    	}

    	return true;
    }

    /// @dev Emergency situation that requires contribution period to stop.
    /// Contributing not possible anymore.
    function halt() public onlyWallet{
        halted = true;
    }

    /// @dev Emergency situation resolved.
    /// Contributing becomes possible again within the outlined restrictions.
    function unHalt() public onlyWallet{
        halted = false;
    }

    /// @dev Emergency situation
    function changeWalletAddress(address newAddress) onlyWallet { 
        cccport = newAddress; 
    }

    /// @return true if sale has started, false otherwise.
    function saleStarted() constant returns (bool) {
        return now >= startTime;
    }

    /// @return true if sale has ended, false otherwise.
    function saleEnded() constant returns (bool) {
        return now > endTime || openSoldTokens >= MAX_OPEN_SOLD;
    }

    /// CONSTANT METHODS
    /// @dev Get current exchange rate
    function priceRate() public constant returns (uint) {
        // Two price tiers
        if (startTime <= now && now < startTime + 1 weeks)
            return PRICE_RATE_DISCOUNT;
        if (startTime + 2 weeks <= now && now < endTime)
            return PRICE_RATE_NORMAL;
        // Should not be called before or after contribution period
        assert(false);
    }

    /*
     * INTERNAL FUNCTIONS
     */

    /// @dev Buy Clipper Coins by partners
    function buyFromPartner(address recipient) internal {
    	uint partnerAvailable = partnersLimit[recipient].sub(partnersBought[recipient]);
	uint allAvailable = MAX_OPEN_SOLD.sub(openSoldTokens);
        partnerAvailable = partnerAvailable.min256(allAvailable);

    	require(partnerAvailable > 0);

    	uint toFund;
    	uint toCollect;
    	(toFund,  toCollect)= costAndBuyTokens(partnerAvailable);

    	partnersBought[recipient] = partnersBought[recipient].add(toCollect);
    	buyCommon(recipient, toFund, toCollect);
    }

    /// @dev Buy Clipper Coin normally
    function buyNormal(address recipient) internal {
        // Do not allow contracts to game the system
        require(!isContract(msg.sender));

        // protect partner quota in stage one
        uint tokenAvailable;
        if(startTime <= now && now < startTime + 1 weeks) {
            uint totalNormalAvailable = MAX_OPEN_SOLD.sub(partnerReservedSum);
            tokenAvailable = totalNormalAvailable.sub(normalSoldTokens);
        } else {
            tokenAvailable = MAX_OPEN_SOLD.sub(openSoldTokens);
        }

        require(tokenAvailable > 0);

    	uint toFund;
    	uint toCollect;
    	(toFund, toCollect) = costAndBuyTokens(tokenAvailable);
        buyCommon(recipient, toFund, toCollect);
        normalSoldTokens += toCollect;
    }

    /// @dev Utility function for buying Clipper Coins
    function buyCommon(address recipient, uint toFund, uint clipperCoinCollect) internal {
        require(msg.value >= toFund); // double check

        if(toFund > 0) {
            require(clipperCoin.mintToken(recipient, clipperCoinCollect));         
            cccport.transfer(toFund);
            openSoldTokens = openSoldTokens.add(clipperCoinCollect);
            NewSale(recipient, toFund, clipperCoinCollect);            
        }

        uint toReturn = msg.value.sub(toFund);
        if(toReturn > 0) {
            msg.sender.transfer(toReturn);
        }
    }

    /// @dev Utility function to calculate available tokens and corresponding ether cost
    function costAndBuyTokens(uint availableToken) constant internal returns (uint costValue, uint getTokens){
    	// all conditions checked in the caller functions
    	uint exchangeRate = priceRate();
    	getTokens = exchangeRate * msg.value;

    	if(availableToken >= getTokens){
    		costValue = msg.value;
    	} else {
    		costValue = availableToken / exchangeRate;
    		getTokens = availableToken;
    	}
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}