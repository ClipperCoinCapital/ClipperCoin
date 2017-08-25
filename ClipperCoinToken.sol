//////////////////////////////////////////////////////////////////////////////////////////
//																						//
//	Title: 						Vanilla Clipper Coin									//
//	Author: 					Marko Valentin Micic									//
//	Version: 					v0.2													//
//	Date of current version:	2017/08/24												//
//	Brief Description:			Standard ERC20 token built for the Ethereum 			//
//								Blockchain, for use in the ICO of Clipper Coin 			//
//								Ventures. Supports standard transactions, limited 		//
//								to 200 million Clipper Coins. Additional 				//
//								functionality may be added at a later date, but only 	//
//								before final distribution of the Clipper Coin -- once 	//
//								Clipper Coin is created and verified on the Ethereum 	//
//								blockchain, it cannot be modified further, and a new 	//
//								token will be required to implement different and new	//
//								functionality. Some provisions are made in the code		//
//								for the ICO sale, including lockdown periods and 		//
//								ownership of the minted coins.							//
//																						//
//////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.4.11;

import "./StandardToken.sol";
import "./SafeMath.sol";

contract ClipperCoin is StandardToken {
    using SafeMath for uint;

    /// Constant token specific fields
    string public constant name = "Clipper Coin";
    string public constant symbol = "CCC";
    uint public constant decimals = 18;

    /// Total supply of Clipper Coin
    uint public constant MAX_TOTAL_TOKEN_AMOUNT = 200000000 ether;

    /// Fields that are only changed in 
    /// constructor Clipper Coin ICO Smart contract
    address public minter; 
    /// ICO start time
    uint public startTime;
    /// ICO end time
    uint public endTime;

    /// Fields that can be changed by functions
    mapping (address => uint) lockedBalances;
    
    /*
     * MODIFIERS
     */

    modifier onlyMinter {
    	  assert(msg.sender == minter);
    	  _;
    }

    modifier isLaterThan (uint x){
    	  assert(now > x);
    	  _;
    }

    modifier maxCCCAmountNotReached (uint amount){
    	  assert(totalSupply.add(amount) <= MAX_TOTAL_TOKEN_AMOUNT);
    	  _;
    }
    
    /**
     * CONSTRUCTOR 
     * 
     * @dev Initialize the Clipper Coin
     * @param _minter The Clipper Coin Smart Contract for the ICO distribution     
     * @param _startTime ICO start time
     * @param _endTime ICO End Time
     */
    function ClipperCoin(address _minter, uint _startTime, uint _endTime){
    	  minter = _minter;
    	  startTime = _startTime;
    	  endTime = _endTime;
    }

    /**
     * EXTERNAL FUNCTION 
     * 
     * @dev ICO minting of tokens
     * @param recipient The destination account that will own the minted coins    
     * @param amount The amount of minted coins to be sent to this address.
     */    
    function mintCoin(address recipient, uint amount)
        external
        onlyMinter
        maxCCCNotReached(amount)
        returns (bool)
    {
      	lockedBalances[recipient] = lockedBalances[recipient].add(amount);
      	totalSupply = totalSupply.add(amount);
      	return true;
    }

    /*
     * PUBLIC FUNCTIONS
     */

    /// @dev Locking period has passed - Locked tokens have become tradeable
    ///      All tokens owned by recipient will be tradeable
    function claimTokens(address recipient)
        isLaterThan(endTime)
    {
      	balances[recipient] = balances[recipient].add(lockedBalances[recipient]);
      	lockedBalances[recipient] = 0;
    }

    /// @dev Transfer Clipper Coin from msg.sender. 
    ///      Prevent transfers until ICO period is over.
    /// @notice ERC20 interface
    function transfer(address recipient, uint amount)
        isLaterThan(endTime)
        returns (bool)
    {
      	return super.transfer(recipient, amount);
    }
    
    /// @dev Transfer Clipper Coin from arbitrary address. 
    ///      Prevent transfers until ICO period is over.
    /// @notice ERC20 interface
    function transferFrom(address sender, address recipient, uint amount)
        isLaterThan(endTime)
        returns (bool success)
    {
        return super.transferFrom(sender, recipient, amount);
    } 
    
        /*
     * CONSTANT METHODS
     */
    function lockedBalanceOf(address _owner) constant returns (uint balance) {
        return lockedBalances[_owner];
    }
} 
