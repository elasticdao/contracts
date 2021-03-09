// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import './Ecosystem.sol';
import './EternalModel.sol';
import './Token.sol';

/**
 * @title a data storage for Token holders
 * @author ElasticDAO - https://ElasticDAO.org
 * @notice This contract is used for storing token data
 * @dev ElasticDAO network contracts can read/write from this contract
 * Serialize - Translation of data from the concerned struct to key-value pairs
 * Deserialize - Translation of data from the key-value pairs to a struct
 */
contract TokenHolder is EternalModel, ReentrancyGuard {
  struct Instance {
    address account;
    uint256 lambda;
    Ecosystem.Instance ecosystem;
    Token.Instance token;
  }

  event Serialized(address indexed account, address indexed token);

  function deserialize(
    address _account,
    Ecosystem.Instance memory _ecosystem,
    Token.Instance memory _token
  ) external view returns (Instance memory record) {
    record.account = _account;
    record.ecosystem = _ecosystem;
    record.token = _token;

    if (_exists(_account, _token)) {
      record.lambda = getUint(keccak256(abi.encode(record.token.uuid, record.account, 'lambda')));
    }

    return record;
  }

  function exists(address _account, Token.Instance memory _token) external view returns (bool) {
    return _exists(_account, _token);
  }

  /**
   * @dev serializes Instance struct
   * @param _record Instance
   */
  function serialize(Instance memory _record) external nonReentrant {
    require(msg.sender == _record.token.uuid, 'ElasticDAO: Unauthorized');

    setUint(keccak256(abi.encode(_record.token.uuid, _record.account, 'lambda')), _record.lambda);
    setBool(keccak256(abi.encode(_record.token.uuid, _record.account, 'exists')), true);

    emit Serialized(_record.account, _record.token.uuid);
  }

  function _exists(address _account, Token.Instance memory _token) internal view returns (bool) {
    return getBool(keccak256(abi.encode(_token.uuid, _account, 'exists')));
  }
}
