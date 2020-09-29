// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import './EternalModel.sol';
import '../libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing token data
/// @dev ElasticDAO network contracts can read/write from this contract
contract TokenHolder is EternalModel {
  struct BalanceChange {
    bool isIncreasing;
    uint256 blockNumber;
    uint256 deltaLambda;
    uint256 id; // counter
    uint256 k;
    uint256 m;
  }

  struct Instance {
    address uuid;
    address tokenAddress;
    uint256 counter;
    uint256 lambda;
    BalanceChange[] balanceChanges;
  }

  function deserialize(address _uuid, address _tokenAddress)
    external
    view
    returns (Instance memory record)
  {
    if (_exists(_uuid, _tokenAddress)) {
      record.uuid = _uuid;
      record.tokenAddress = _tokenAddress;
      record.counter = getUint(keccak256(abi.encode(_tokenAddress, 'counter', _uuid)));
      record.lambda = getUint(keccak256(abi.encode(_tokenAddress, 'lambda', _uuid)));

      for (uint256 i = 0; i < record.counter; SafeMath.add(i, 1)) {
        record.balanceChanges[i].id = i;
        record.balanceChanges[i].isIncreasing = getBool(
          keccak256(abi.encode(record.tokenAddress, 'balanceChange', record.uuid, 'counter', i))
        );
        record.balanceChanges[i].blockNumber = getUint(
          keccak256(abi.encode(record.tokenAddress, 'balanceChange', record.uuid, 'blockNumber', i))
        );
        record.balanceChanges[i].deltaLambda = getUint(
          keccak256(abi.encode(record.tokenAddress, 'balanceChange', record.uuid, 'deltaLambda', i))
        );
        record.balanceChanges[i].k = getUint(
          keccak256(abi.encode(record.tokenAddress, 'balanceChange', record.uuid, 'k', i))
        );
        record.balanceChanges[i].m = getUint(
          keccak256(abi.encode(record.tokenAddress, 'balanceChange', record.uuid, 'm', i))
        );
      }
    }
  }

  function exists(address _uuid, address _tokenAddress) external view returns (bool recordExists) {
    return _exists(_uuid, _tokenAddress);
  }

  function serialize(Instance memory record) external {
    setUint(keccak256(abi.encode(record.tokenAddress, 'counter', record.uuid)), record.counter);
    setUint(keccak256(abi.encode(record.tokenAddress, 'lambda', record.uuid)), record.lambda);

    for (uint256 i = 0; i < record.counter; SafeMath.add(i, 1)) {
      setBool(
        keccak256(abi.encode(record.tokenAddress, 'balanceChange', record.uuid, 'isIncreasing', i)),
        record.balanceChanges[i].isIncreasing
      );
      setUint(
        keccak256(abi.encode(record.tokenAddress, 'balanceChange', record.uuid, 'blockNumber', i)),
        record.balanceChanges[i].blockNumber
      );
      setUint(
        keccak256(abi.encode(record.tokenAddress, 'balanceChange', record.uuid, 'deltaLambda', i)),
        record.balanceChanges[i].deltaLambda
      );
      setUint(
        keccak256(abi.encode(record.tokenAddress, 'balanceChange', record.uuid, 'k', i)),
        record.balanceChanges[i].k
      );
      setUint(
        keccak256(abi.encode(record.tokenAddress, 'balanceChange', record.uuid, 'm', i)),
        record.balanceChanges[i].m
      );
    }
  }

  function _exists(address _uuid, address _tokenAddress) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists', _uuid, _tokenAddress)));
  }
}
