//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @author : deelight-del
/// Everytime, there is a deposit or withdrawal change, the reward is recalculated for
/// all users in the pool.
contract StakeEther {

  uint constant TIMEINTERVAL = 1 days;
  uint constant DECIMALPLACES = 5;

  struct StakeInformation {
    uint amount;
    uint expirationTime;
    bool staked;
  }
  
  uint private lastTimeMinted;
  address private _owner;
  address[] private listOfAddresses;

  mapping(address => uint) rewardBalances;

  mapping(address => StakeInformation) stakers;
  uint private totalStaked = 0;

  event DepositSuccessful(uint _amouunt, address _sender);
  event WithdrawSuccessful(uint _amouunt);

  constructor() {
    _owner = msg.sender;
    lastTimeMinted = block.timestamp;
  }

  modifier onlyOwner() {
    require(msg.sender == _owner, "You are not the owner of the contract.");
    _;
  }

  function depositEther(uint _days) external payable {
    require(_days > 0, "You must stake for a minimum of a day");
    require(msg.value > 0, "You cannot deposit 0 ether");
    require(msg.sender != address(0), "Address 0 detected");

    // Foe everytime, there is a new deposit, we compare the last time minted.
    // And the current time. The value here will tell us the number of intervals
    // that our reward should have been minted, and hence update every address with some
    // respective reward.
    uint mintReward = ((block.timestamp - lastTimeMinted) / TIMEINTERVAL);
    if (mintReward > 0) {
      // Update the lastTimeMinted as we will be updating the rewardBalance into the reward.
      lastTimeMinted = block.timestamp;
      // Loop through all addresses and update each user reward based on their.
      // principal contribution.
      for (uint i = 0; i < listOfAddresses.length; i++) {
        address userAddress = listOfAddresses[i];
        // Calculate and update reward based on principal contribution.
        rewardBalances[userAddress] += ((rewardBalances[userAddress] * DECIMALPLACES / totalStaked) * mintReward); // DECIMALPLACES TO CARE FOR NO DECIMAL PLACES IN SOLIDITY.
      }
    }

    // Deposit into the contract(this) and update stakers information.
    // address(this).call{value: uint128(_value)}("");
    // StakeInformation memory staker;
    stakers[msg.sender].amount += msg.value;
    totalStaked += msg.value;

    // For now, when you stake multiple times, you will only extend your 
    // day of withdrawl by the new amount of days you specify.
    stakers[msg.sender].expirationTime += (_days * 1 days);

    // uodate stateVariables.
    if (stakers[msg.sender].staked != true) {
      listOfAddresses.push(msg.sender);
      stakers[msg.sender].staked = true;
    }

    emit DepositSuccessful(msg.value, msg.sender);
  }

  receive() payable external {
  }

  /// Let us also withdrea.
  function withdrawEther(uint _value) external {

    require(stakers[msg.sender].expirationTime < block.timestamp, "You time for staking has not elapsed yet.");
    require(stakers[msg.sender].amount >= _value, "Insufficient Balance!");
    require(_value > 0, "You cannot withDraw 0 ether");
    require(msg.sender != address(0), "Address 0 detected");

    // Foe everytime, there is a new withDraw, we compare the last time minted.
    // And the current time. The value here will tell us the number of intervals
    // that our reward should have been minted, and hence update every address with some
    // respective reward.
    uint mintReward = ((block.timestamp - lastTimeMinted) / TIMEINTERVAL);
    if (mintReward > 0) {
      // Update the lastTimeMinted as we will be updating the rewardBalance into the reward.
      lastTimeMinted = block.timestamp;
      // Loop through all addresses and update each user reward based on their.
      // principal contribution.
      for (uint i = 0; i < listOfAddresses.length; i++) {
        address userAddress = listOfAddresses[i];
        // Calculate and update reward based on principal contribution.
        rewardBalances[userAddress] += ((rewardBalances[userAddress] * DECIMALPLACES / totalStaked) * mintReward); // DECIMALPLACES TO CARE FOR NO DECIMAL PLACES IN SOLIDITY.
      }
    }

    // Withdraw from the contract and update stakers information.
    stakers[msg.sender].amount -= _value;
    totalStaked -= _value;
    (bool success,) = msg.sender.call{value: uint128(_value)}("");
    require(success == true, "Unable to withdraw from the contract");

    // uodate stateVariables; Change staked to not staked.
    if (stakers[msg.sender].staked == true) {
      // listOfAddresses.push(msg.sender);
      stakers[msg.sender].staked = false;
    }

    emit WithdrawSuccessful(_value);
  }

  function myEtherBalance() external view returns (uint) {
    return stakers[msg.sender].amount;
  }

  function etherbalanceOf(address _user) external view onlyOwner returns (uint){
    return stakers[_user].amount;
  }

  function myRewardBalnce() external view returns (uint) {
    return rewardBalances[msg.sender];
  }

  /// @notice : This will serve as the withdawal means for users, where
  /// they can transfer their reward to other users/addresses (for some value).
  /// This does not implement other properties of this behaviour, apart from transferring
  /// to another address.
  function transferReward(uint _amount, address _to) external {
    require(stakers[msg.sender].expirationTime < block.timestamp, "You time for staking has not elapsed yet.");
    require(_amount > 0, "You cannot withDraw 0 ether");
    require(rewardBalances[msg.sender] >= _amount, "Insufficient Reward Balance!");
    require(msg.sender != address(0), "Address 0 detected");

    rewardBalances[msg.sender] -= _amount;
    rewardBalances[_to] += _amount;
  }

  /// @notice : This will attract some penalty/fine and the penalty fees goes 
  // to the owner.
  function emergencyEtherWithdrawal() external pure returns (string memory) {
    return("Function is not implemented yet");
  }
}

/// What if a user stakes multiple times at different interval?
/// Potential bug of using array of users to track and update each user.
//TODO: Seperate when the ether is expired or not. When expiration time is reached, such funds should not yield rewards any more.
