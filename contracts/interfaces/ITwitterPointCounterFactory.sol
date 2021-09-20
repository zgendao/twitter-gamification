// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface ITwitterPointCounterFactory {
  function deleteCounter(string memory _tweetId) external;
}
