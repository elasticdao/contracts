// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import './EternalModel.sol';
import '../libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing core Vote data
/// @dev ElasticDAO network contracts can read/write from this contract

contract Vote is EternalModel {
  struct Instance {
    address uuid; // from VoteBallot struct
    bool hasPenalty;
    bool hasReachedQuorum;
    bool isActive;
    bool isApproved;
    string name; // from struct VoteType
    string proposal; // from struct voteInformation
    string voteType;
    uint256 abstainLambda;
    uint256 approval;
    uint256 endOnBlock;
    uint256 id;
    uint256 lambda;
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
      record.lambda = getUint(keccak256(abi.encode('lambda', _uuid)));
      record.maxSharesPerAccount = getUint(keccak256(abi.encode('maxSharesPerAccount', _uuid)));
      record.minBlocksForPenalty = getUint(keccak256(abi.encode('minBlocksForPenalty', _uuid)));
      record.name = getString(keccak256(abi.encode('name', _uuid)));
      record.noLambda = getUint(keccak256(abi.encode('noLambda', _uuid)));
      record.penalty = getUint(keccak256(abi.encode('penalty', _uuid)));
      record.proposal = getString(keccak256(abi.encode('proposal', _uuid)));
      record.quorum = getUint(keccak256(abi.encode('quorum', _uuid)));
      record.reward = getUint(keccak256(abi.encode('reward', _uuid)));
      record.startOnBlock = getUint(keccak256(abi.encode('startOnBlock', _uuid)));
      record.uuid = _uuid;
      record.yesLambda = getUint(keccak256(abi.encode('yesLambda', _uuid)));
    }
  }

  function exists(address _uuid) external view returns (bool recordExists) {
    return _exists(_uuid);
  }

  function _exists(address _uuid) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists.', _uuid)));
  }
}
