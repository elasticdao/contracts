// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './EternalModel.sol';
import '../libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing core dao data
/// @dev ElasticDAO network contracts can read/write from this contract
contract Ecosystem is EternalModel {
  constructor() EternalModel() {}

  struct Instance {
    address uuid; // dao uuid
    // Models
    address daoModelAddress;
    address ecosystemModelAddress;
    address elasticModuleModelAddress;
    address tokenModelAddress;
    address tokenHolderModelAddress;
    // Services
    address configuratorAddress;
    address registratorAddress;
    // Tokens
    address governanceTokenAddress;
  }

  function deserialize(address _uuid) external view returns (Instance memory record) {
    if (_exists(_uuid)) {
      record.uuid = _uuid;
      record.configuratorAddress = getAddress(
        keccak256(abi.encode('configuratorAddress', record.uuid))
      );
      record.daoModelAddress = getAddress(keccak256(abi.encode('daoModelAddress', record.uuid)));
      record.ecosystemModelAddress = getAddress(
        keccak256(abi.encode('ecosystemModelAddress', record.uuid))
      );
      record.elasticModuleModelAddress = getAddress(
        keccak256(abi.encode('elasticModuleModelAddress', record.uuid))
      );
      record.governanceTokenAddress = getAddress(
        keccak256(abi.encode('governanceTokenAddress', record.uuid))
      );
      record.registratorAddress = getAddress(
        keccak256(abi.encode('registratorAddress', record.uuid))
      );
      record.tokenHolderModelAddress = getAddress(
        keccak256(abi.encode('tokenHolderModelAddress', record.uuid))
      );
      record.tokenModelAddress = getAddress(
        keccak256(abi.encode('tokenModelAddress', record.uuid))
      );
    }
  }

  function exists(address _uuid) external view returns (bool recordExists) {
    return _exists(_uuid);
  }

  function serialize(Instance memory record) external {
    setBool(keccak256(abi.encode('exists', record.uuid)), true);
    setAddress(
      keccak256(abi.encode('configuratorAddress', record.uuid)),
      record.configuratorAddress
    );
    setAddress(keccak256(abi.encode('daoModelAddress', record.uuid)), record.daoModelAddress);
    setAddress(
      keccak256(abi.encode('ecosystemModelAddress', record.uuid)),
      record.ecosystemModelAddress
    );
    setAddress(
      keccak256(abi.encode('elasticModuleModelAddress', record.uuid)),
      record.elasticModuleModelAddress
    );
    setAddress(
      keccak256(abi.encode('governanceTokenAddress', record.uuid)),
      record.governanceTokenAddress
    );
    setAddress(keccak256(abi.encode('registratorAddress', record.uuid)), record.registratorAddress);
    setAddress(
      keccak256(abi.encode('tokenHolderModelAddress', record.uuid)),
      record.tokenHolderModelAddress
    );
    setAddress(keccak256(abi.encode('tokenModelAddress', record.uuid)), record.tokenModelAddress);
  }

  function _exists(address _uuid) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists', _uuid)));
  }
}
