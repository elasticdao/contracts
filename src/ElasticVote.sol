// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;

// Contracts
import './ElasticStorage.sol';

contract ElasticVote {
  ElasticStorage internal elasticStorage;

  modifier onlyVoteCreators() {
    require(
      elasticStorage.canCreateVote(msg.sender),
      'ElasticDAO: Not enough shares to create a vote'
    );
    _;
  }

  constructor(address _elasticStorageAddress) {
    elasticStorage = ElasticStorage(_elasticStorageAddress);
  }

  function createVoteInformation(string calldata _voteProposal, uint256 _finalBlockNumber)
    public
    view
    onlyVoteCreators
  {
    ElasticStorage.AccountBalance memory accountBalance = elasticStorage.getAccountBalance(
      msg.sender
    );
    ElasticStorage.VoteSettings memory voteSettings = elasticStorage.getVoteSettings();
    ElasticStorage.VoteType memory voteType = elasticStorage.getVoteType('information');

    // all vote settings
  }
}
