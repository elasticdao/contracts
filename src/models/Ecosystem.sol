// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './EternalModel.sol';
import '../libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing core dao data
/// @dev ElasticDAO network contracts can read/write from this contract
/// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract Ecosystem is EternalModel {
  struct Instance {
    address uuid; // dao uuid
    // Models
    address balanceChangeModelAddress;
    address daoModelAddress;
    address ecosystemModelAddress;
    address elasticModuleModelAddress;
    address tokenHolderModelAddress;
    address tokenModelAddress;
    // Services
    address configuratorAddress;
    address registratorAddress;
    // Tokens
    address governanceTokenAddress;
  }

  /**
   * @dev deserializes Instance struct
   * @param _uuid - address of the unique user ID
   * @return record Instance
   */
  function deserialize(address _uuid) external view returns (Instance memory record) {
    if (_exists(_uuid)) {
      record.uuid = _uuid;
      record.balanceChangeModelAddress = getAddress(
        keccak256(abi.encode('balanceChangeModelAddress', record.uuid))
      );
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

    return record;
  }

  /**
   * @dev checks if @param _uuid and @param _name exist
   * @param _uuid - address of the unique user ID
   * @return recordExists bool
   */
  function exists(address _uuid) external view returns (bool recordExists) {
    return _exists(_uuid);
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setAddress(
      keccak256(abi.encode('balanceChangeModelAddress', record.uuid)),
      record.balanceChangeModelAddress
    );
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

    setBool(keccak256(abi.encode('exists', record.uuid)), true);
  }

  function _exists(address _uuid) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists', _uuid)));
  }
}
