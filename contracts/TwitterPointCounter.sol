// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "witnet-ethereum-bridge/contracts/UsingWitnet.sol";
import "witnet-ethereum-bridge/contracts/requests/WitnetRequest.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITwitterAuth.sol";
import "./interfaces/ITwitterPointCounterFactory.sol";

contract TwitterPointCounter is UsingWitnet, Ownable {
  uint256 public newRequest;

  struct User {
    bool liked;
    bool received;
    bool subscribed;
  }

  mapping(address => User) public users;
  mapping(address => uint64) public received;
  string internal addressStr;
  string public tweetId;
  ITwitterAuth public immutable twitterAuth;
  ITwitterPointCounterFactory public immutable twitterPointCounterFactory;
  uint256 public reward;
  string[] internal liked;

  event ResultError(string msg);

  /// Check whether there is a pending update.
  modifier notPending() {
    require(
      _witnetCheckResultAvailability(newRequest),
      "TwitterPointCounter: Likers are currently being requested"
    );
    _;
  }

  /// Check whether there is a request.
  modifier requested() {
    require(newRequest > 0, "TwitterPointCounter: There is no new request");
    _;
  }

  ///@param _twitterAuthAddress Address of the TwitterAuth contract
  ///@param _tweetId Id of the tweet to be monitored
  ///@param _reward Amount of ETH for a like
  constructor(
    WitnetRequestBoard _wrb,
    address _twitterAuthAddress,
    address _factoryAddress,
    string memory _tweetId,
    uint256 _reward
  ) UsingWitnet(_wrb) {
    addressStr = toAsciiString(address(this));
    tweetId = _tweetId;
    twitterAuth = ITwitterAuth(_twitterAuthAddress);
    twitterPointCounterFactory = ITwitterPointCounterFactory(_factoryAddress);
    reward = _reward;
  }

  ///@notice Set a new reward for likes.
  ///@param _newReward The new amount of ETH given as reward for likes.
  function setReward(uint256 _newReward) external onlyOwner {
    reward = _newReward;
  }

  ///@notice Creates a new Witnet request to query the likes of a tweet
  ///@dev This process could take 10-15 minutes.
  function requestPoints() external payable {
    WitnetRequest request = new WitnetRequest(
      bytes(
        abi.encodePacked(
          hex"0a8e0108d3e6968a061270125f68747470733a2f2f6170692d6d6964646c6577617265732e76657263656c2e6170702f6170692f747769747465722f73746174732f",
          addressStr,
          hex"1a0d821877821861666c696b6572731a090a050808120180100222090a050808120180100210c0843d180a20e80728333080c8afa025"
        )
      )
    );

    // Keerp track of the Witnet query ID
    newRequest = _witnetPostRequest(request);
  }

  ///@notice Reads and stores the result of the Witnet request
  ///@dev requestPoints() has to be called before this and the result has to be ready.
  ///@dev The amount of users that can be processed at the same time is limited
  function getPoints() public requested notPending {
    //Extracting data
    Witnet.Result memory result = _witnetReadResult(newRequest);

    // prettier-ignore
    if (witnet.isOk(result)) {
      string[] memory values = witnet.asStringArray(result);
      for (uint256 i = 0; i < values.length; i++) {
        liked.push(values[i]);
        users[twitterAuth.addressFromId(values[i])].liked = true;
      }
      newRequest = 0;
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
      newRequest = 0;
      emit ResultError(errorMessage);
    }
  }

  ///@notice Send the reward to a user who liked the tweet.
  function withdrawReward() public {
    require(
      users[msg.sender].liked && !users[msg.sender].received,
      "TwitterPointCounter: Can't withdraw rewards"
    );
    users[msg.sender].received = true;
    payable(msg.sender).transfer(reward);
  }

  ///@notice Returns the twitter id of every user who liked the tweet and are already queried.
  ///@dev This array is for off-chain use only.
  ///@dev The array size is not bound by anything so DO NOT iterate over it on-chain.
  ///@return Array of twitter ids.
  function getLikers() external view returns (string[] memory) {
    return liked;
  }

  ///@notice Destroys the contract and sends the stored ETH to the owner.
  function removeFunds() external onlyOwner {
    twitterPointCounterFactory.deleteCounter(tweetId);
    selfdestruct(payable(owner()));
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

  receive() external payable {}
}
