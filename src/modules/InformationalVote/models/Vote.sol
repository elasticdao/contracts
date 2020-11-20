// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../../../models/EternalModel.sol';
import '../../../libraries/SafeMath.sol';
import './Settings.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing information vote data
/// @dev ElasticDAO network contracts can read/write from this contract
// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract InformationalVote is EternalModel {
  struct Instance {
    address author;
    address votingToken;
    bool hasPenalty;
    bool hasReachedQuorum;
    bool isActive;
    bool isApproved;
    string proposal;
    uint256 abstainLambda;
    uint256 approval;
    uint256 endOnBlock;
    uint256 index;
    uint256 maxSharesPerTokenHolder;
    uint256 minBlocksForPenalty;
    uint256 minPenaltyInShares;
    uint256 minRewardInShares;
    uint256 noLambda;
    uint256 penalty;
    uint256 quorum;
    uint256 quorumLambda;
    uint256 reward;
    uint256 startOnBlock;
    uint256 yesLambda;
    InformationalVoteSettings.Instance settings;
  }

  function deserialize(uint256 _index, InformationalVoteSettings.Instance memory _settings)
    external
    view
    returns (Instance memory record)
  {
    record.index = _index;
    record.settings = _settings;

    if (_exists(_index, _settings)) {
      record.abstainLambda = getUint(keccak256(abi.encode(_settings.uuid, _index, 'abstainLambda')));
      record.approval = getUint(keccak256(abi.encode(_settings.uuid, _index, 'approval')));
      record.author = getAddress(keccak256(abi.encode(_settings.uuid, _index, 'author')));
      record.endOnBlock = getUint(keccak256(abi.encode(_settings.uuid, _index, 'endOnBlock')));
      record.hasPenalty = getBool(keccak256(abi.encode(_settings.uuid, _index, 'hasPenalty')));
      record.hasReachedQuorum = getBool(keccak256(abi.encode(_settings.uuid, _index, 'hasReachedQuorum')));
      record.isActive = getBool(keccak256(abi.encode(_settings.uuid, _index, 'isActive')));
      record.isApproved = getBool(keccak256(abi.encode(_settings.uuid, _index, 'isApproved')));
      record.maxSharesPerTokenHolder = getUint(
        keccak256(abi.encode(_settings.uuid, _index, 'maxSharesPerTokenHolder'))
      );
      record.minBlocksForPenalty = getUint(
        keccak256(abi.encode(_settings.uuid, _index, 'minBlocksForPenalty'))
      );
      record.minPenaltyInShares = getUint(keccak256(abi.encode(_settings.uuid, _index, 'minPenaltyInShares')));
      record.minRewardInShares = getUint(keccak256(abi.encode(_settings.uuid, _index, 'minRewardInShares')));
      record.noLambda = getUint(keccak256(abi.encode(_settings.uuid, _index, 'noLambda')));
      record.penalty = getUint(keccak256(abi.encode(_settings.uuid, _index, 'penalty')));
      record.proposal = getString(keccak256(abi.encode(_settings.uuid, _index, 'proposal')));
      record.quorum = getUint(keccak256(abi.encode(_settings.uuid, _index, 'quorum')));
      record.quorumLambda = getUint(keccak256(abi.encode(_settings.uuid, _index, 'quorumLambda')));
      record.reward = getUint(keccak256(abi.encode(_settings.uuid, _index, 'reward')));
      record.startOnBlock = getUint(keccak256(abi.encode(_settings.uuid, _index, 'startOnBlock')));
      record.votingToken = getAddress(keccak256(abi.encode(_settings.uuid, _index, 'votingToken')));
      record.yesLambda = getUint(keccak256(abi.encode(_settings.uuid, _index, 'yesLambda')));
    }

    return record;
  }

  function exists(uint256 _index, InformationalVoteSettings.Instance memory _settings) external view returns (bool recordExists) {
    return _exists(_index, _settings);
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setAddress(keccak256(abi.encode(record.settings.uuid, record.index, 'author')), record.author);
    setAddress(keccak256(abi.encode(record.settings.uuid, record.index, 'votingToken')), record.votingToken);
    setBool(keccak256(abi.encode(record.settings.uuid, record.index, 'hasPenalty')), record.hasPenalty);
    setBool(
      keccak256(abi.encode(record.settings.uuid, record.index, 'hasReachedQuorum')),
      record.hasReachedQuorum
    );
    setBool(keccak256(abi.encode(record.settings.uuid, record.index, 'isActive')), record.isActive);
    setBool(keccak256(abi.encode(record.settings.uuid, record.index, 'isApproved')), record.isApproved);
    setString(keccak256(abi.encode(record.settings.uuid, record.index, 'proposal')), record.proposal);
    setUint(
      keccak256(abi.encode(record.settings.uuid, record.index, 'abstainLambda')),
      record.abstainLambda
    );
    setUint(keccak256(abi.encode(record.settings.uuid, record.index, 'approval')), record.approval);
    setUint(keccak256(abi.encode(record.settings.uuid, record.index, 'endOnBlock')), record.endOnBlock);
    setUint(
      keccak256(abi.encode(record.settings.uuid, record.index, 'maxSharesPerTokenHolder')),
      record.maxSharesPerTokenHolder
    );
    setUint(
      keccak256(abi.encode(record.settings.uuid, record.index, 'minBlocksForPenalty')),
      record.minBlocksForPenalty
    );
    setUint(
      keccak256(abi.encode(record.settings.uuid, record.index, 'minPenaltyInShares')),
      record.minPenaltyInShares
    );
    setUint(
      keccak256(abi.encode(record.settings.uuid, record.index, 'minRewardInShares')),
      record.minRewardInShares
    );
    setUint(keccak256(abi.encode(record.settings.uuid, record.index, 'noLambda')), record.noLambda);
    setUint(keccak256(abi.encode(record.settings.uuid, record.index, 'penalty')), record.penalty);
    setUint(keccak256(abi.encode(record.settings.uuid, record.index, 'quorum')), record.quorum);
    setUint(keccak256(abi.encode(record.settings.uuid, record.index, 'quorumLambda')), record.quorumLambda);
    setUint(keccak256(abi.encode(record.settings.uuid, record.index, 'reward')), record.reward);
    setUint(keccak256(abi.encode(record.settings.uuid, record.index, 'startOnBlock')), record.startOnBlock);
    setUint(keccak256(abi.encode(record.settings.uuid, record.index, 'yesLambda')), record.yesLambda);

    setBool(keccak256(abi.encode(record.settings.uuid, record.index, 'exists')), true);
  }

  function _exists(uint256 _index, InformationalVoteSettings.Instance memory _settings) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode(_settings.uuid, _index, 'exists')));
  }
}
