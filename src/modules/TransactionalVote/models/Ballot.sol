// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../../../models/EternalModel.sol';
import '../../../libraries/SafeMath.sol';
import './Settings.sol';
import './Vote.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing information vote data
/// @dev ElasticDAO network contracts can read/write from this contract
// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract TransactionalVoteBallot is EternalModel {
  constructor() EternalModel() {}

  struct Instance {
    address voter;
    bool wasPenalized;
    uint256 lambda;
    uint256 yna;
    TransactionalVoteSettings.Instance settings;
    TransactionalVote.Instance vote;
  }

  function deserialize(
    address _voter,
    TransactionalVoteSettings.Instance memory _settings,
    TransactionalVote.Instance memory _vote
  ) external view returns (Instance memory record) {
    record.voter = _voter;
    record.settings = _settings;
    record.vote = _vote;

    if (_exists(_voter, _settings, _vote)) {
      record.lambda = getUint(
        keccak256(abi.encode(_settings.managerAddress, _vote.index, _voter, 'lambda'))
      );
      record.wasPenalized = getBool(
        keccak256(abi.encode(_settings.managerAddress, _vote.index, _voter, 'wasPenalized'))
      );
      record.yna = getUint(
        keccak256(abi.encode(_settings.managerAddress, _vote.index, _voter, 'yna'))
      );
    }

    return record;
  }

  function exists(
    address _voter,
    TransactionalVoteSettings.Instance memory _settings,
    TransactionalVote.Instance memory _vote
  ) external view returns (bool recordExists) {
    return _exists(_voter, _settings, _vote);
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setBool(
      keccak256(
        abi.encode(record.settings.managerAddress, record.vote.index, record.voter, 'wasPenalized')
      ),
      record.wasPenalized
    );
    setUint(
      keccak256(
        abi.encode(record.settings.managerAddress, record.vote.index, record.voter, 'lambda')
      ),
      record.lambda
    );
    setUint(
      keccak256(abi.encode(record.settings.managerAddress, record.vote.index, record.voter, 'yna')),
      record.yna
    );

    setBool(
      keccak256(
        abi.encode(record.settings.managerAddress, record.vote.index, record.voter, 'exists')
      ),
      true
    );
  }

  function _exists(
    address _voter,
    TransactionalVoteSettings.Instance memory _settings,
    TransactionalVote.Instance memory _vote
  ) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode(_settings.managerAddress, _vote.index, _voter, 'exists')));
  }
}
