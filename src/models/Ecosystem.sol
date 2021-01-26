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
    address daoAddress;
    // Models
    address balanceModelAddress;
    address balanceMultipliersModelAddress;
    address daoModelAddress;
    address ecosystemModelAddress;
    address tokenHolderModelAddress;
    address tokenModelAddress;
    // Services
    address configuratorAddress;
    // Tokens
    address governanceTokenAddress;
  }

  /**
   * @dev deserializes Instance struct
   * @param _daoAddress - address of the unique user ID
   * @return record Instance
   */
  function deserialize(address _daoAddress) external view returns (Instance memory record) {
    if (_exists(_daoAddress)) {
      record.daoAddress = _daoAddress;
      record.balanceModelAddress = getAddress(
        keccak256(abi.encode(record.daoAddress, 'balanceModelAddress'))
      );
      record.balanceMultipliersModelAddress = getAddress(
        keccak256(abi.encode(record.daoAddress, 'balanceMultipliersModelAddress'))
      );
      record.configuratorAddress = getAddress(
        keccak256(abi.encode(record.daoAddress, 'configuratorAddress'))
      );
      record.daoModelAddress = getAddress(
        keccak256(abi.encode(record.daoAddress, 'daoModelAddress'))
      );
      record.ecosystemModelAddress = address(this);
      record.governanceTokenAddress = getAddress(
        keccak256(abi.encode(record.daoAddress, 'governanceTokenAddress'))
      );
      record.tokenHolderModelAddress = getAddress(
        keccak256(abi.encode(record.daoAddress, 'tokenHolderModelAddress'))
      );
      record.tokenModelAddress = getAddress(
        keccak256(abi.encode(record.daoAddress, 'tokenModelAddress'))
      );
    }

    return record;
  }

  /**
   * @dev checks if @param _daoAddress and @param _name exist
   * @param _daoAddress - address of the unique user ID
   * @return recordExists bool
   */
  function exists(address _daoAddress) external view returns (bool recordExists) {
    return _exists(_daoAddress);
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    bool recordExists = _exists(record.daoAddress);

    require(
      msg.sender == record.daoAddress ||
        msg.sender == record.configuratorAddress ||
        (record.daoAddress == address(0) && !recordExists),
      'ElasticDAO: Unauthorized'
    );

    setAddress(
      keccak256(abi.encode(record.daoAddress, 'balanceModelAddress')),
      record.balanceModelAddress
    );
    setAddress(
      keccak256(abi.encode(record.daoAddress, 'balanceMultipliersModelAddress')),
      record.balanceMultipliersModelAddress
    );
    setAddress(
      keccak256(abi.encode(record.daoAddress, 'configuratorAddress')),
      record.configuratorAddress
    );
    setAddress(keccak256(abi.encode(record.daoAddress, 'daoModelAddress')), record.daoModelAddress);
    setAddress(
      keccak256(abi.encode(record.daoAddress, 'governanceTokenAddress')),
      record.governanceTokenAddress
    );
    setAddress(
      keccak256(abi.encode(record.daoAddress, 'tokenHolderModelAddress')),
      record.tokenHolderModelAddress
    );
    setAddress(
      keccak256(abi.encode(record.daoAddress, 'tokenModelAddress')),
      record.tokenModelAddress
    );

    setBool(keccak256(abi.encode(record.daoAddress, 'exists')), true);
  }

  function _exists(address _daoAddress) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode(_daoAddress, 'exists')));
  }
}
