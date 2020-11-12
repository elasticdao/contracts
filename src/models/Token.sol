// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './Ecosystem.sol';
import './EternalModel.sol';
import '../libraries/SafeMath.sol';

import '../tokens/ElasticGovernanceToken.sol';

import 'hardhat/console.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing token data
/// @dev ElasticDAO network contracts can read/write from this contract
/// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract Token is EternalModel {
  struct Instance {
    address uuid;
    string name;
    string symbol;
    uint256 capitalDelta;
    uint256 counter; // passed as ID to balance multipliers
    uint256 elasticity;
    uint256 k;
    uint256 lambda;
    uint256 m;
    uint256 maxLambdaPurchase;
    uint256 numberOfTokenHolders;
    Ecosystem.Instance ecosystem;
  }

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

    if (_exists(_uuid)) {
      record.capitalDelta = getUint(keccak256(abi.encode(_uuid, 'capitalDelta')));
      record.counter = getUint(keccak256(abi.encode(_uuid, 'counter')));
      record.elasticity = getUint(keccak256(abi.encode(_uuid, 'elasticity')));
      record.k = getUint(keccak256(abi.encode(_uuid, 'k')));
      record.lambda = getUint(keccak256(abi.encode(_uuid, 'lambda')));
      record.m = getUint(keccak256(abi.encode(_uuid, 'm')));
      record.maxLambdaPurchase = getUint(keccak256(abi.encode(_uuid, 'maxLambdaPurchase')));
      record.name = getString(keccak256(abi.encode(_uuid, 'name')));
      record.numberOfTokenHolders = getUint(keccak256(abi.encode(_uuid, 'numberOfTokenHolders')));
      record.symbol = getString(keccak256(abi.encode(_uuid, 'symbol')));
    }

    return record;
  }

  function exists(address _uuid, Ecosystem.Instance memory) external view returns (bool) {
    return _exists(_uuid);
  }

  function incrementCounter(address _uuid) external {
    uint256 counter = getUint(keccak256(abi.encode(_uuid, 'counter')));
    setUint(keccak256(abi.encode(_uuid, 'counter')), SafeMath.add(counter, 1));
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setString(keccak256(abi.encode(record.uuid, 'name')), record.name);
    setString(keccak256(abi.encode(record.uuid, 'symbol')), record.symbol);
    setUint(keccak256(abi.encode(record.uuid, 'capitalDelta')), record.capitalDelta);
    setUint(keccak256(abi.encode(record.uuid, 'elasticity')), record.elasticity);
    setUint(keccak256(abi.encode(record.uuid, 'k')), record.k);
    setUint(keccak256(abi.encode(record.uuid, 'lambda')), record.lambda);
    setUint(keccak256(abi.encode(record.uuid, 'm')), record.m);
    setUint(keccak256(abi.encode(record.uuid, 'maxLambdaPurchase')), record.maxLambdaPurchase);

    setBool(keccak256(abi.encode(record.uuid, 'exists')), true);
  }

  function updateNumberOfTokenHolders(Instance memory record, uint256 numberOfTokenHolders)
    external
  {
    setUint(keccak256(abi.encode(record.uuid, 'numberOfTokenHolders')), numberOfTokenHolders);
  }

  function _exists(address _uuid) internal view returns (bool) {
    return getBool(keccak256(abi.encode(_uuid, 'exists')));
  }
}
