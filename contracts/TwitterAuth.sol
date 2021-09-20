// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "witnet-ethereum-bridge/contracts/UsingWitnet.sol";
import "witnet-ethereum-bridge/contracts/requests/WitnetRequest.sol";

/// @title Linking a Twitter user to Ethereum address using the Twitter oracle
/// @author Rick
contract TwitterAuth is UsingWitnet {
  struct User {
    string twitterId;
    uint256 witnetQueryId;
    uint256 index;
  }

  mapping(address => User) public users;
  mapping(string => address) public addressFromId;
  mapping(uint256 => string) public idFromIndex;

  uint256 public numOfUsers;

  event ResultError(string msg);

  constructor(WitnetRequestBoard _wrb) UsingWitnet(_wrb) {}

  /// Check whether the twitter id is not being checked yet.
  modifier notChecked() {
    require(
      users[msg.sender].witnetQueryId == 0,
      "TwitterAuth: Twitter ID is already requested"
    );
    _;
  }

  /// Check whether the twitter id has already been requested.
  modifier checked() {
    require(
      users[msg.sender].witnetQueryId > 0,
      "TwitterAuth: Twitter ID needs to be requested"
    );
    _;
  }

  /// Check whether there is a pending update.
  modifier notPending() {
    require(
      _witnetCheckResultAvailability(users[msg.sender].witnetQueryId),
      "TwitterAuth: Twitter ID is currently being requested"
    );
    _;
  }

  ///@notice Sends a data request to Witnet so as to get the Twitter user id linked to the sender address
  ///@param _TweetId The tweet id wich contains the address in the text.
  function checkTwitterID(string calldata _TweetId)
    external
    payable
    notChecked
  {
    WitnetRequest request = new WitnetRequest(
      bytes(
        abi.encodePacked(
          hex"0a7608edf2f889061258124968747470733a2f2f6170692d6d6964646c6577617265732e76657263656c2e6170702f6170692f747769747465722f7477656574732f",
          _TweetId,
          hex"1a0b82187782186164617574681a090a050808120180100222090a050808120180100210c0843d180a20e80728333080c8afa025"
        )
      )
    );

    //increase the number of users
    if (users[msg.sender].index == 0) {
      users[msg.sender].index = numOfUsers;
      numOfUsers++;
    }

    // Keerp track of the Witnet query ID
    users[msg.sender].witnetQueryId = _witnetPostRequest(request);
  }

  ///@notice Deletes the queryId and the twitter id so it can be queried again.
  function deleteTwitterID() external checked {
    addressFromId[users[msg.sender].twitterId] = address(0);
    users[msg.sender].twitterId = "";
    idFromIndex[users[msg.sender].index] = "";
    users[msg.sender].witnetQueryId = 0;
  }

  ///@notice Reads the twitter id from the users mapping
  ///@param _user The address of the user
  ///@return The twitter id of the user
  function twitterIdFromAddress(address _user)
    external
    view
    returns (string memory)
  {
    return users[_user].twitterId;
  }

  ///@notice Extracts and saves the twitter id from the query
  function extractTwitterId() public notPending checked {
    //Extracting data
    Witnet.Result memory result = _witnetReadResult(
      users[msg.sender].witnetQueryId
    );

    if (witnet.isOk(result)) {
      // We got a valid id!
      string[] memory values = witnet.asStringArray(result);
      if (compareAddress(values[1], msg.sender)) {
        if (addressFromId[values[0]] == address(0)) {
          users[msg.sender].twitterId = values[0];
          addressFromId[values[0]] = msg.sender;
          idFromIndex[users[msg.sender].index] = values[0];
        } else {
          users[msg.sender].witnetQueryId = 0;
          emit ResultError("Twitter ID is already linked");
        }
      } else {
        users[msg.sender].witnetQueryId = 0;
        emit ResultError("Address is not matching");
      }
    } else {
      string memory errorMessage;
      // Try to read the value as an error message, catch error bytes if read fails
      try witnet.asErrorMessage(result) returns (
        Witnet.ErrorCodes,
        string memory e
      ) {
        errorMessage = e;
      } catch (bytes memory errorBytes) {
        errorMessage = string(errorBytes);
      }

      // The Witnet query failed. Set query ID to 0 so it can be retried using `checkTwitterID()` again
      users[msg.sender].witnetQueryId = 0;
      emit ResultError(errorMessage);
    }
  }

  ///@notice Compares a string to an address
  ///@param _addressStr An address in string form
  ///@param _address The address to be compared
  ///@return The match between the string and the address
  function compareAddress(string memory _addressStr, address _address)
    internal
    pure
    returns (bool)
  {
    bool matching = (keccak256(abi.encodePacked(_addressStr)) ==
      keccak256(abi.encodePacked(toAsciiString(_address))));
    return matching;
  }

  ///@notice Converts an Ethereum address to string
  ///@param _address The address to be converted
  ///@return The address in string form
  function toAsciiString(address _address)
    internal
    pure
    returns (string memory)
  {
    bytes memory s = new bytes(40);
    for (uint256 i = 0; i < 20; i++) {
      bytes1 b = bytes1(
        uint8(uint256(uint160(_address)) / (2**(8 * (19 - i))))
      );
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = char(hi);
      s[2 * i + 1] = char(lo);
    }
    return string(abi.encodePacked("0x", s));
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }
}
