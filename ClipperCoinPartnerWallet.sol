pragma solidity ^0.4.10;
import "./StandardToken.sol";
// requires 40000000 CCC to be deposited here
contract CCC_Partner_Wallet {
  mapping (address => uint256) allocations;
  uint256 public unlockDate;
  address public CCC;
  uint256 public constant exponent = 10**18;

  function CCC_Incentive_Wallet(address _CCC) {
    CCC = _CCC;
    /// 3 month period lockdown
    unlockDate = now + 3 * 30 days; 
    /// TODO: Insert allocation for partners
    allocations[0x0000000000000000000000000000000000000000] = xxxx;
    			
  }

  function unlock() external {
  	/// Check whether lockdown period has expired
    require(now >= unlockDate);
    uint256 entitled = allocations[msg.sender];
    allocations[msg.sender] = 0;
    require(StandardToken(CCC).transfer(msg.sender, entitled * exponent));
  }

}