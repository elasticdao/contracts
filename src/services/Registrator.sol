// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../models/Ecosystem.sol';
import '../models/ElasticModule.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for registering ElasticDAO modules
/// @dev ElasticDAO network contracts can read/write from this contract
contract Registrator {
  function registerModule(address _moduleAddress, string memory _name) external {
    Ecosystem.Instance memory ecosystem = _getEcosystem(msg.sender);
    ElasticModule elasticModuleStorage = ElasticModule(ecosystem.elasticModuleModelAddress);
    ElasticModule.Instance memory elasticModule;
    elasticModule.uuid = msg.sender;
    elasticModule.name = _name;
    elasticModule.contractAddress = _moduleAddress; // TODO: Check against TBD whitelist
    elasticModuleStorage.serialize(elasticModule);
  }

  function _getEcosystem(address _uuid)
    internal
    view
    returns (Ecosystem.Instance memory ecosystem)
  {
    ecosystem = Ecosystem(_uuid).deserialize(msg.sender);
  }
}
