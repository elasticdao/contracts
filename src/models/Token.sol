// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './EternalModel.sol';
import '../libraries/SafeMath.sol';

import '../tokens/ElasticGovernanceToken.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing token data
/// @dev ElasticDAO network contracts can read/write from this contract
contract Token is EternalModel {
  constructor() EternalModel() {}

  struct Instance {
    address uuid;
    string name;
    string symbol;
    uint256 capitalDelta;
    uint256 elasticity;
    uint256 k;
    uint256 lambda;
    uint256 m;
    uint256 maxLambdaPurchase;
  }

  function deserialize(address _uuid) external view returns (Instance memory record) {
    if (_exists(_uuid)) {
      record.capitalDelta = getUint(keccak256(abi.encode('capitalDelta', _uuid)));
      record.elasticity = getUint(keccak256(abi.encode('elasticity', _uuid)));
      record.k = getUint(keccak256(abi.encode('k', _uuid)));
      record.lambda = getUint(keccak256(abi.encode('lambda', _uuid)));
      record.m = getUint(keccak256(abi.encode('m', _uuid)));
      record.maxLambdaPurchase = getUint(keccak256(abi.encode('maxLambdaPurchase', _uuid)));
      record.name = getString(keccak256(abi.encode('name', _uuid)));
      record.symbol = getString(keccak256(abi.encode('symbol', _uuid)));
      record.uuid = _uuid;
    }
  }

  function exists(address _uuid) external view returns (bool recordExists) {
    return _exists(_uuid);
  }

  function serialize(Instance memory record) external {
    setBool(keccak256(abi.encode('exists', record.uuid)), true);
    setString(keccak256(abi.encode('name', record.uuid)), record.name);
    setString(keccak256(abi.encode('symbol', record.uuid)), record.symbol);
    setUint(keccak256(abi.encode('capitalDelta', record.uuid)), record.capitalDelta);
    setUint(keccak256(abi.encode('elasticity', record.uuid)), record.elasticity);
    setUint(keccak256(abi.encode('k', record.uuid)), record.k);
    setUint(keccak256(abi.encode('lambda', record.uuid)), record.lambda);
    setUint(keccak256(abi.encode('m', record.uuid)), record.m);
    setUint(keccak256(abi.encode('maxLambdaPurchase', record.uuid)), record.maxLambdaPurchase);
  }

  function _exists(address _uuid) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists', _uuid)));
  }
}
