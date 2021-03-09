// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './Ecosystem.sol';
import './EternalModel.sol';
import '../services/ReentryProtection.sol';
import '../tokens/ElasticGovernanceToken.sol';

/**
 * @title A data storage for EGT (Elastic Governance Token)
 * @notice More info about EGT could be found in ./tokens/ElasticGovernanceToken.sol
 * @notice This contract is used for storing token data
 * @dev ElasticDAO network contracts can read/write from this contract
 * Serialize - Translation of data from the concerned struct to key-value pairs
 * Deserialize - Translation of data from the key-value pairs to a struct
 */
contract Token is EternalModel, ReentryProtection {
  struct Instance {
    address uuid;
    string name;
    string symbol;
    uint256 eByL;
    uint256 elasticity;
    uint256 k;
    uint256 lambda;
    uint256 m;
    uint256 maxLambdaPurchase;
    uint256 numberOfTokenHolders;
    Ecosystem.Instance ecosystem;
  }

  event Serialized(address indexed uuid);

  /**
   * @dev deserializes Instance struct
   * @param _uuid - address of the unique user ID
   * @return record Instance
   */
  function deserialize(address _uuid, Ecosystem.Instance memory _ecosystem)
    external
    view
    returns (Instance memory record)
  {
    record.uuid = _uuid;
    record.ecosystem = _ecosystem;

    if (_exists(_uuid, _ecosystem.daoAddress)) {
      record.eByL = getUint(keccak256(abi.encode(_uuid, record.ecosystem.daoAddress, 'eByL')));
      record.elasticity = getUint(
        keccak256(abi.encode(_uuid, record.ecosystem.daoAddress, 'elasticity'))
      );
      record.k = getUint(keccak256(abi.encode(_uuid, record.ecosystem.daoAddress, 'k')));
      record.lambda = getUint(keccak256(abi.encode(_uuid, record.ecosystem.daoAddress, 'lambda')));
      record.m = getUint(keccak256(abi.encode(_uuid, record.ecosystem.daoAddress, 'm')));
      record.maxLambdaPurchase = getUint(
        keccak256(abi.encode(_uuid, record.ecosystem.daoAddress, 'maxLambdaPurchase'))
      );
      record.name = getString(keccak256(abi.encode(_uuid, record.ecosystem.daoAddress, 'name')));
      record.numberOfTokenHolders = getUint(
        keccak256(abi.encode(_uuid, record.ecosystem.daoAddress, 'numberOfTokenHolders'))
      );
      record.symbol = getString(
        keccak256(abi.encode(_uuid, record.ecosystem.daoAddress, 'symbol'))
      );
    }

    return record;
  }

  function exists(address _uuid, address _daoAddress) external view returns (bool) {
    return _exists(_uuid, _daoAddress);
  }

  /**
   * @dev serializes Instance struct
   * @param _record Instance
   */
  function serialize(Instance memory _record) external preventReentry {
    require(
      msg.sender == _record.uuid ||
        (msg.sender == _record.ecosystem.daoAddress &&
          _exists(_record.uuid, _record.ecosystem.daoAddress)),
      'ElasticDAO: Unauthorized'
    );

    setString(
      keccak256(abi.encode(_record.uuid, _record.ecosystem.daoAddress, 'name')),
      _record.name
    );
    setString(
      keccak256(abi.encode(_record.uuid, _record.ecosystem.daoAddress, 'symbol')),
      _record.symbol
    );
    setUint(
      keccak256(abi.encode(_record.uuid, _record.ecosystem.daoAddress, 'eByL')),
      _record.eByL
    );
    setUint(
      keccak256(abi.encode(_record.uuid, _record.ecosystem.daoAddress, 'elasticity')),
      _record.elasticity
    );
    setUint(keccak256(abi.encode(_record.uuid, _record.ecosystem.daoAddress, 'k')), _record.k);
    setUint(
      keccak256(abi.encode(_record.uuid, _record.ecosystem.daoAddress, 'lambda')),
      _record.lambda
    );
    setUint(keccak256(abi.encode(_record.uuid, _record.ecosystem.daoAddress, 'm')), _record.m);
    setUint(
      keccak256(abi.encode(_record.uuid, _record.ecosystem.daoAddress, 'maxLambdaPurchase')),
      _record.maxLambdaPurchase
    );

    setBool(keccak256(abi.encode(_record.uuid, _record.ecosystem.daoAddress, 'exists')), true);

    emit Serialized(_record.uuid);
  }

  function updateNumberOfTokenHolders(Instance memory _record, uint256 numberOfTokenHolders)
    external
    preventReentry
  {
    require(
      msg.sender == _record.uuid && _exists(_record.uuid, _record.ecosystem.daoAddress),
      'ElasticDAO: Unauthorized'
    );

    setUint(
      keccak256(abi.encode(_record.uuid, _record.ecosystem.daoAddress, 'numberOfTokenHolders')),
      numberOfTokenHolders
    );
  }

  function _exists(address _uuid, address _daoAddress) internal view returns (bool) {
    return getBool(keccak256(abi.encode(_uuid, _daoAddress, 'exists')));
  }
}
