// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// Import the UsingWitnet library that enables interacting with Witnet
import "witnet-ethereum-bridge/contracts/UsingWitnet.sol";
// Import the WitnetRequest contract that enables creating requests on the spot
import "witnet-ethereum-bridge/contracts/requests/WitnetRequest.sol";

/// SocialMonitor using the Twitter oracle
/// @author Rick
contract SocialMonitor is UsingWitnet {
  struct Tweet {
    bool notEmpty;
    string id;
    uint64 likes;
    uint64 comments;
    uint64 retweets;
    uint256 witnetQueryId;
  }

  mapping(string => Tweet) public tweets;

  // Emits when found an error decoding request result
  event ResultError(string msg);

  /// Check whether the tweet doesn't exist
  modifier empty(string calldata _id) {
    require(!tweets[_id].notEmpty, "SocialMonitor: this tweet already exists");
    _;
  }

  /// Check whether the tweet exists
  modifier notEmpty(string calldata _id) {
    require(tweets[_id].notEmpty, "SocialMonitor: the tweet doesn't exist");
    _;
  }

  modifier checked(string calldata _id) {
    require(
      tweets[_id].witnetQueryId > 0,
      "SocialMonitor: like count needs to be checked"
    );
    _;
  }

  /// Check whether there is a pending update
  modifier notPending(string calldata _id) {
    require(
      _witnetCheckResultAvailability(tweets[_id].witnetQueryId),
      "SocialMonitor: like count is currently being checked"
    );
    _;
  }

  constructor(WitnetRequestBoard _wrb) UsingWitnet(_wrb) {}

  function addTweet(string calldata _id) external empty(_id) {
    tweets[_id].id = _id;
    tweets[_id].notEmpty = true;
  }

  /// Sends a data request to Witnet so as to get an attestation of the current viewcount of a video
  function checkLikes(string calldata _id) external payable notEmpty(_id) {
    WitnetRequest request = new WitnetRequest(
      bytes(
        abi.encodePacked(
          hex"0a870108edf2f889061259124968747470733a2f2f6170692d6d6964646c6577617265732e76657263656c2e6170702f6170692f747769747465722f7477656574732f",
          _id,
          hex"1a0c821877821865656c696b65731a110a0d08051209fb3ff199999999999a100322110a0d08051209fb3ff199999999999a100310c0843d180a20e80728333080c8afa025"
        )
      )
    );

    // Keerp track of the Witnet query ID
    tweets[_id].witnetQueryId = _witnetPostRequest(request);
  }

  function getLikes(string calldata _id)
    public
    notEmpty(_id)
    notPending(_id)
    checked(_id)
  {
    //Extracting data
    Witnet.Result memory result = _witnetReadResult(tweets[_id].witnetQueryId);

    if (witnet.isOk(result)) {
      // We got a valid like count!
      uint64 likeCount = witnet.asUint64(result);
      tweets[_id].likes = likeCount;
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

      // The Witnet query failed. Set query ID to 0 so it can be retried using `checkLikes()` again
      tweets[_id].witnetQueryId = 0;
      emit ResultError(errorMessage);
    }
  }
}
