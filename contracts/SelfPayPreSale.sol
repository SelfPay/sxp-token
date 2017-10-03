pragma solidity ^0.4.11;

import './SelfPayToken.sol';
import "./zeppelin-solidity/crowdsale/CappedCrowdsale.sol";
import "./zeppelin-solidity/crowdsale/FinalizableCrowdsale.sol";
import './zeppelin-solidity/math/SafeMath.sol';

contract SelfPayPreSale is CappedCrowdsale, FinalizableCrowdsale {

  // number of participants in the SelfPay Pre-Sale
  uint256 public numberOfPurchasers = 0;

  // Number of backers that have sent 10 or more ETH
  uint256 public nbBackerWithMoreOrEqualTen = 0;

  // Total SXP
  uint256 public sxpNumber = 0;

  // Ensure the gold level bonus can only be used once
  bool public goldLevelBonusIsUsed = false;

  function SelfPayPreSale(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _goal, uint256 _cap, address _wallet)
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    Crowdsale(_startTime, _endTime, _rate, _wallet) public
  {
    // As goal needs to be met for a successful crowdsale the value needs to be less
    // than or equal than a cap which is limit for accepted funds
    require(_goal <= _cap);
  }

  function createTokenContract() internal returns (MintableToken) {
   return new SelfPayToken();
  }

  /**
   * @dev Calculates the amount of SXP coins the buyer gets
   * @param weiAmount uint the amount of wei send to the contract
   * @return uint the amount of tokens the buyer gets
   */
  function computeTokenWithBonus(uint256 weiAmount, address beneficiary) internal returns(uint256) {
    // standard rate: 1 ETH : 300 SXP
    uint256 tokens_ = weiAmount.mul(rate);

    // Hardcoded address of the specific gold level beneficiary
    if (beneficiary == address(0x2157a35ce381175946d564ef64e22735286e61ea) && weiAmount >= 50 ether && !goldLevelBonusIsUsed) {

      // Gold level bonus: Exclusive bonus of 100% for one specific investor
      tokens_ = tokens_.mul(200).div(100);
      goldLevelBonusIsUsed = true;

    } else if (weiAmount >= 10 ether && nbBackerWithMoreOrEqualTen < 10) {

      // Silver level bonus: the first 10 participants that transfer 10 ETH or more will get 75% SXP bonus
      tokens_ = tokens_.mul(175).div(100);
      nbBackerWithMoreOrEqualTen++;

    } else {

      // Bronze level bonus: +60% bonus for everyone else during PRE SALE
      tokens_ = tokens_.mul(160).div(100);

    }

    return tokens_;
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // Calculate the number of tokens and any bonus tokens
    uint256 tokens = computeTokenWithBonus(weiAmount, beneficiary);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    // update state
    weiRaised = weiRaised.add(weiAmount);
    numberOfPurchasers = numberOfPurchasers + 1;
    sxpNumber = sxpNumber.add(tokens);

    forwardFunds();
  }

  function finalization() internal {
    token.transferOwnership(owner);
  }

}