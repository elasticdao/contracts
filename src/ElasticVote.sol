// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

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
    external
    onlyVoteCreators
  {
    ElasticStorage.AccountBalance memory accountBalance = elasticStorage.getAccountBalance(
      msg.sender
    );
    ElasticStorage.VoteSettings memory voteSettings = elasticStorage.getVoteSettings();
    require(
      accountBalance.lambda >= voteSettings.minSharesToCreate,
      'ElasticDAO: Insufficient funds'
    );

    ElasticStorage.VoteType memory voteType = elasticStorage.getVoteType('information');
    ElasticStorage.Vote memory vote;
    vote.startOnBlock = block.number;
    vote.endOnBlock = _finalBlockNumber;
    require(voteType.minBlocks >= SafeMath.sub(vote.endOnBlock, vote.startOnBlock));

    // all vote settings
    vote.approval = voteSettings.approval;
    vote.maxSharesPerAccount = voteSettings.maxSharesPerAccount;
    vote.minBlocksForPenalty = voteSettings.minBlocksForPenalty;
    vote.penalty = voteSettings.penalty;
    vote.quorum = voteSettings.quorum;
    vote.reward = voteSettings.reward;
    vote.voteType = voteType.name;

    vote.hasPenalty = voteType.hasPenalty;
    vote.id = voteSettings.counter;

    ElasticStorage.VoteInformation memory voteInformation;
    voteInformation.id = vote.id;
    voteInformation.proposal = _voteProposal;

    elasticStorage.createVoteInformation(vote, voteInformation, voteSettings);
  }

  function getVote(uint256 _id) public view returns (ElasticStorage.Vote memory vote) {
    return elasticStorage.getVote(_id);
  }

  function getVoteInformation(uint256 _id)
    public
    view
    returns (ElasticStorage.VoteInformation memory voteInformation)
  {
    return elasticStorage.getVoteInformation(_id);
  }

  function vote(uint256 _id, uint256 _yna) public {
    require(_yna <= 2, 'ElasticDAO: Invalid Vote Value - 0:Yes, 1:NO, 2:ABSTAIN');
  }
}
