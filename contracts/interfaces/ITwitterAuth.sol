// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface ITwitterAuth {
  function twitterIdFromAddress(address _user)
    external
    returns (string memory);

  function addressFromId(string memory _twitterId) external returns (address);
}
