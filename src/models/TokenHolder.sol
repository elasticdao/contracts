// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './Ecosystem.sol';
import './EternalModel.sol';
import './Token.sol';
import '../libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing token data
/// @dev ElasticDAO network contracts can read/write from this contract
// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract TokenHolder is EternalModel {
  struct Instance {
    address account;
    uint256 counter;
    uint256 lambda;
    Ecosystem.Instance ecosystem;
    Token.Instance token;
  }

  function deserialize(
    address _account,
    Ecosystem.Instance memory _ecosystem,
    Token.Instance memory _token
  ) external view returns (Instance memory record) {
    record.account = _account;
    record.ecosystem = _ecosystem;
    record.token = _token;

    if (_exists(_account, _token.uuid)) {
      record.counter = getUint(keccak256(abi.encode(record.token.uuid, record.account, 'counter')));
      record.lambda = getUint(keccak256(abi.encode(record.token.uuid, record.account, 'lambda')));
    }

    return record;
  }

  function exists(
    address _account,
    Ecosystem.Instance memory _ecosystem,
    Token.Instance memory _token
  ) external view returns (bool recordExists) {
    return _exists(_account, _token.uuid);
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setUint(keccak256(abi.encode(record.tokenAddress, 'counter', record.uuid)), record.counter);
    setUint(keccak256(abi.encode(record.tokenAddress, 'lambda', record.uuid)), record.lambda);

    setBool(keccak256(abi.encode('exists', record.uuid, record.tokenAddress)), true);
  }

  function _exists(address _account, address _tokenAddress)
    internal
    view
    returns (bool recordExists)
  {
    return getBool(keccak256(abi.encode('exists', _account, _tokenAddress)));
  }
}
