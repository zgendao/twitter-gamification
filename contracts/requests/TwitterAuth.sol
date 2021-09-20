// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "witnet-ethereum-bridge/contracts/requests/WitnetRequest.sol";

// The bytecode of the TwitterAuth request that will be sent to Witnet
contract TwitterAuthRequest is WitnetRequest {
  constructor () WitnetRequest(hex"0a7608d3e6968a061258124968747470733a2f2f6170692d6d6964646c6577617265732e76657263656c2e6170702f6170692f747769747465722f7477656574732f303030303030303030303030303030303030301a0b82187782186164617574681a090a050808120180100222090a050808120180100210c0843d180a20e80728333080c8afa025") { }
}
