// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './EternalModel.sol';
import '../libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing core Vote data
/// @dev ElasticDAO network contracts can read/write from this contract
contract Vote is EternalModel {
  constructor() EternalModel() {}

  struct Instance {
    bool hasPenalty;
    bool hasReachedQuorum;
    bool isActive;
    bool isApproved;
    string voteType;
    uint256 abstainLambda;
    uint256 approval;
    uint256 endOnBlock;
    uint256 id;
    uint256 maxSharesPerAccount;
    uint256 minBlocksForPenalty;
    uint256 noLambda;
    uint256 penalty;
    uint256 quorum;
    uint256 reward;
    uint256 startOnBlock;
    uint256 yesLambda;
  }

  function deserialize(address _uuid) external view returns (Instance memory record) {
    if (_exists(_uuid)) {
      record.abstainLambda = getUint(keccak256(abi.encode('abstainLambda', _uuid)));
      record.approval = getUint(keccak256(abi.encode('approval', _uuid)));
      record.endOnBlock = getUint(keccak256(abi.encode('endOnBlock', _uuid)));
      record.hasPenalty = getBool(keccak256(abi.encode('hasPenalty', _uuid)));
      record.hasReachedQuorum = getBool(keccak256(abi.encode('hasReachedQuorum', _uuid)));
      record.isActive = getBool(keccak256(abi.encode('isActive', _uuid)));
      record.isApproved = getBool(keccak256(abi.encode('isApproved', _uuid)));
      record.id = getUint(keccak256(abi.encode('id', _uuid)));
      record.maxSharesPerAccount = getUint(keccak256(abi.encode('maxSharesPerAccount', _uuid)));
      record.minBlocksForPenalty = getUint(keccak256(abi.encode('minBlocksForPenalty', _uuid)));
      record.noLambda = getUint(keccak256(abi.encode('noLambda', _uuid)));
      record.penalty = getUint(keccak256(abi.encode('penalty', _uuid)));
      record.quorum = getUint(keccak256(abi.encode('quorum', _uuid)));
      record.reward = getUint(keccak256(abi.encode('reward', _uuid)));
      record.startOnBlock = getUint(keccak256(abi.encode('startOnBlock', _uuid)));
      record.yesLambda = getUint(keccak256(abi.encode('yesLambda', _uuid)));
    }
  }

  function exists(address _uuid) external view returns (bool recordExists) {
    return _exists(_uuid);
  }

  function _exists(address _uuid) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists', _uuid)));
  }
}
