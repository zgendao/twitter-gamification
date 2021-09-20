// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "witnet-ethereum-bridge/contracts/requests/WitnetRequest.sol";

// The bytecode of the TwitterLikes request that will be sent to Witnet
contract TwitterLikesRequest is WitnetRequest {
  constructor () WitnetRequest(hex"0a870108d3e6968a061259124968747470733a2f2f6170692d6d6964646c6577617265732e76657263656c2e6170702f6170692f747769747465722f7477656574732f303030303030303030303030303030303030301a0c821877821865656c696b65731a110a0d08051209fb3ff199999999999a100322110a0d08051209fb3ff199999999999a100310c0843d180a20e80728333080c8afa025") { }
}
