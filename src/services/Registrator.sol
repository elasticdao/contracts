// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../models/Ecosystem.sol';
import '../models/ElasticModule.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for registering ElasticDAO modules
/// @dev ElasticDAO network contracts can read/write from this contract
contract Registrator {
  function registerModule(
    address _moduleAddress,
    string memory _name,
    Ecosystem.Instance memory _ecosystem
  ) external {
    ElasticModule elasticModuleStorage = ElasticModule(_ecosystem.elasticModuleModelAddress);
    ElasticModule.Instance memory elasticModule;
    elasticModule.dao = DAO(_ecosystem.daoModelAddress).deserialize(msg.sender, _ecosystem);
    elasticModule.name = _name;
    elasticModule.uuid = _moduleAddress; // TODO: Check against TBD whitelist
    elasticModuleStorage.serialize(elasticModule);
  }
}
