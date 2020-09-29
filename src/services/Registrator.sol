// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import '../models/Ecosystem.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for registering ElasticDAO modules
/// @dev ElasticDAO network contracts can read/write from this contract
contract Registrator {
  // function registerModule(string name, address moduleAddress) external {
  //   Ecosystem memory ecosystem = _getEcosystem(msg.sender);
  // }

  function _getEcosystem(address _uuid)
    internal
    view
    returns (Ecosystem.Instance memory ecosystem)
  {
    ecosystem = Ecosystem(_uuid).deserialize(msg.sender);
  }
}
