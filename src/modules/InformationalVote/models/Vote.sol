// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../../../models/EternalModel.sol';
import '../../../libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing information vote data
/// @dev ElasticDAO network contracts can read/write from this contract
// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract Vote is EternalModel {
  struct Instance {
    address uuid;
    bool hasPenalty;
    bool hasReachedQuorum;
    bool isActive;
    bool isApproved;
    string proposal;
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

  /**
   * @dev deserializes Instance struct
   * @param _uuid - address of the unique manager instance
   * @param _id - the counter value of this vote
   * @return record Instance
   */
  function deserialize(address _uuid, uint256 _id) external view returns (Instance memory record) {
    record.id = _id;
    record.uuid = _uuid;

    if (_exists(_uuid, _id)) {
      record.abstainLambda = getUint(keccak256(abi.encode('abstainLambda', _uuid, _id)));
      record.approval = getUint(keccak256(abi.encode('approval', _uuid, _id)));
      record.endOnBlock = getUint(keccak256(abi.encode('endOnBlock', _uuid, _id)));
      record.hasPenalty = getBool(keccak256(abi.encode('hasPenalty', _uuid, _id)));
      record.hasReachedQuorum = getBool(keccak256(abi.encode('hasReachedQuorum', _uuid, _id)));
      record.isActive = getBool(keccak256(abi.encode('isActive', _uuid, _id)));
      record.isApproved = getBool(keccak256(abi.encode('isApproved', _uuid, _id)));
      record.maxSharesPerAccount = getUint(
        keccak256(abi.encode('maxSharesPerAccount', _uuid, _id))
      );
      record.minBlocksForPenalty = getUint(
        keccak256(abi.encode('minBlocksForPenalty', _uuid, _id))
      );
      record.noLambda = getUint(keccak256(abi.encode('noLambda', _uuid, _id)));
      record.penalty = getUint(keccak256(abi.encode('penalty', _uuid, _id)));
      record.proposal = getString(keccak256(abi.encode('proposal', _uuid, _id)));
      record.quorum = getUint(keccak256(abi.encode('quorum', _uuid, _id)));
      record.reward = getUint(keccak256(abi.encode('reward', _uuid, _id)));
      record.startOnBlock = getUint(keccak256(abi.encode('startOnBlock', _uuid, _id)));
      record.voteType = getString(keccak256(abi.encode('voteType', _uuid, _id)));
      record.yesLambda = getUint(keccak256(abi.encode('yesLambda', _uuid, _id)));
    }

    return record;
  }

  function exists(address _uuid, uint256 _id) external view returns (bool recordExists) {
    return _exists(_uuid, _id);
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setBool(keccak256(abi.encode('hasPenalty', record.uuid, record.id)), record.hasPenalty);
    setBool(
      keccak256(abi.encode('hasReachedQuorum', record.uuid, record.id)),
      record.hasReachedQuorum
    );
    setBool(keccak256(abi.encode('isActive', record.uuid, record.id)), record.isActive);
    setBool(keccak256(abi.encode('isApproved', record.uuid, record.id)), record.isApproved);
    setString(keccak256(abi.encode('proposal', record.uuid, record.id)), record.proposal);
    setString(keccak256(abi.encode('voteType', record.uuid, record.id)), record.voteType);
    setUint(keccak256(abi.encode('abstainLambda', record.uuid, record.id)), record.abstainLambda);
    setUint(keccak256(abi.encode('approval', record.uuid, record.id)), record.approval);
    setUint(keccak256(abi.encode('endOnBlock', record.uuid, record.id)), record.endOnBlock);
    setUint(
      keccak256(abi.encode('maxSharesPerAccount', record.uuid, record.id)),
      record.maxSharesPerAccount
    );
    setUint(
      keccak256(abi.encode('minBlocksForPenalty', record.uuid, record.id)),
      record.minBlocksForPenalty
    );
    setUint(keccak256(abi.encode('noLambda', record.uuid, record.id)), record.noLambda);
    setUint(keccak256(abi.encode('penalty', record.uuid, record.id)), record.penalty);
    setUint(keccak256(abi.encode('quorum', record.uuid, record.id)), record.quorum);
    setUint(keccak256(abi.encode('reward', record.uuid, record.id)), record.reward);
    setUint(keccak256(abi.encode('startOnBlock', record.uuid, record.id)), record.startOnBlock);
    setUint(keccak256(abi.encode('yesLambda', record.uuid, record.id)), record.yesLambda);

    setBool(keccak256(abi.encode('exists', record.uuid, record.id)), true);
  }

  function _exists(address _uuid, uint256 _id) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists', _uuid, _id)));
  }
}
