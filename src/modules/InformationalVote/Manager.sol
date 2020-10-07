// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './models/Ballot.sol';
import './models/Settings.sol';
import './models/Vote.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for interacting with informational votes
/// @dev ElasticDAO network contracts can read/write from this contract
contract Manager {
  address ballotModelAddress;
  address settingsModelAddress;
  address voteModelAddress;
  bool initialized;

  constructor(
    address _ballotModelAddress,
    address _settingsModelAddress,
    address _voteModelAddress
  ) {
    ballotModelAddress = _ballotModelAddress;
    initialized = false;
    settingsModelAddress = _settingsModelAddress;
    voteModelAddress = _voteModelAddress;
  }

  function initialize(
    address _votingToken,
    bool _hasPenalty,
    uint256[8] memory _settings
  ) external {
    require(initialized == false, 'ElasticDAO: Informational Vote Manager already initialized.');
    Settings settingsContract = Settings(settingsModelAddress);
    Settings.Instance memory settings;
    settings.uuid = address(this);
    settings.votingToken = _votingToken;
    settings.hasPenalty = _hasPenalty;
    settings.approval = _settings[0];
    settings.counter = 0;
    settings.maxSharesPerTokenHolder = _settings[1];
    settings.minBlocksForPenalty = _settings[2];
    settings.minDurationInBlocks = _settings[3];
    settings.minSharesToCreate = _settings[4];
    settings.penalty = _settings[5];
    settings.quorum = _settings[6];
    settings.reward = _settings[7];
    settingsContract.serialize(settings);
    initialized = true;
  }

  
}
