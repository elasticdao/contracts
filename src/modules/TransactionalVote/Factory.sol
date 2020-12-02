// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../../core/ElasticDAO.sol';
import './Manager.sol';

contract TransactionalVoteFactory {
  event ManagerDeployed(address indexed managerAddress);

  function deployManager(
    address _ballotModelAddress,
    address payable _elasticDAOAddress,
    address _settingsModelAddress,
    address payable _vaultAddress,
    address _voteModelAddress,
    address _votingTokenAddress,
    bool _hasPenalty,
    uint256[10] memory _settings
  ) external {
    // creates the manager of the informationalVote Module
    TransactionalVoteManager manager = new TransactionalVoteManager(
      _ballotModelAddress,
      _settingsModelAddress,
      _vaultAddress,
      _voteModelAddress
    );

    // initializes the informationalVoteModule via the manager
    manager.initialize(_votingTokenAddress, _hasPenalty, _settings);

    // register the module in ElasticDAO
    ElasticDAO elasticDAO = ElasticDAO(_elasticDAOAddress);
    elasticDAO.initializeModule(address(manager), 'TransactionalVoteModule');

    emit ManagerDeployed(address(manager));
  }
}
