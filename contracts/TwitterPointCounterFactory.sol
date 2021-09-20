// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./TwitterPointCounter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TwitterPointCounterFactory is Ownable {
  mapping(string => address) public pointCounterOfTweet;

  error AlreadyExists();
  error NotSelfdestruct();

  function createTwitterPointCounter(
    WitnetRequestBoard _wrb,
    address _twitterAuthAddress,
    string memory _tweetId,
    uint256 _reward
  ) external {
    if (pointCounterOfTweet[_tweetId] != address(0)) revert AlreadyExists();

    TwitterPointCounter twitterPointCounter = new TwitterPointCounter(
      _wrb,
      _twitterAuthAddress,
      address(this),
      _tweetId,
      _reward
    );
    twitterPointCounter.transferOwnership(msg.sender);
    pointCounterOfTweet[_tweetId] = address(twitterPointCounter);
  }

  function deleteCounter(string memory _tweetId) external {
    if (pointCounterOfTweet[_tweetId] != msg.sender) revert NotSelfdestruct();
    pointCounterOfTweet[_tweetId] = address(0);
  }
}
