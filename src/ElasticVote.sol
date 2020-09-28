// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

// Contracts
import './ElasticBallotStorage.sol';
import './ElasticStorage.sol';
import './ElasticVoteStorage.sol';

contract ElasticVote {
  ElasticBallotStorage internal elasticBallotStorage;
  ElasticVoteStorage internal elasticVoteStorage;

  modifier onlyVoteCreators() {
    require(
      elasticVoteStorage.canCreateVote(msg.sender),
      'ElasticDAO: Not enough shares to create a vote'
    );
    _;
  }

  constructor(address _elasticVoteStorageAddress, address _elasticBallotStorageAddress) {
    elasticBallotStorage = ElasticBallotStorage(_elasticBallotStorageAddress);
    elasticVoteStorage = ElasticVoteStorage(_elasticVoteStorageAddress);
  }

  /**
   * @dev creates the vote information
   * @param _voteProposal - the vote proposal
   * @param _finalBlockNumber - the block number on which the vote ends
   * Essentially checks if voteProposer (msg.sender) has the
   * minimum shares required to create a vote, if so, then records all the Vote settings
   */
  function createVoteInformation(string calldata _voteProposal, uint256 _finalBlockNumber)
    external
    onlyVoteCreators
  {
    ElasticStorage.VoteSettings memory voteSettings = elasticVoteStorage.getVoteSettings();
    ElasticStorage.VoteType memory voteType = elasticVoteStorage.getVoteType('information');
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

    elasticVoteStorage.createVoteInformation(vote, voteInformation, voteSettings);
  }

  /**
   * @dev Gets the vote
   * @param _id - is the vote ID
   * @return vote Vote
   */
  function getVote(uint256 _id) public view returns (ElasticStorage.Vote memory vote) {
    return elasticVoteStorage.getVote(_id);
  }

  /**
   * @dev Gets the vote ballot
   * @param _id - is the vote ID
   * @return voteBallot VoteBallot
   */
  function getVoteBallot(uint256 _id)
    public
    view
    returns (ElasticStorage.VoteBallot memory voteBallot)
  {
    return elasticBallotStorage.getVoteBallot(msg.sender, _id);
  }

  /**
   * @dev Gets the vote information
   * @param _id - is the vote ID
   * @return voteInformation VoteInformation
   */
  function getVoteInformation(uint256 _id)
    public
    view
    returns (ElasticStorage.VoteInformation memory voteInformation)
  {
    return elasticVoteStorage.getVoteInformation(_id);
  }

  /**
   * @dev penalizes non voter
   * @param _uuidsToPenalize - the unique user ID's to be penalized
   * @param _numberOfUuidsToPenalize - the number of unique user ID's to be penalized
   * @param _id - the ID of the vote
   * If the vote has a penalty, the vote has ended and has not reached quoroum
   * the _uuidsToPenalize are penalized
   */
  function penalizeNonVoter(
    address[] calldata _uuidsToPenalize,
    uint256 _numberOfUuidsToPenalize,
    uint256 _id
  ) external {
    ElasticStorage.Vote memory vote = elasticVoteStorage.getVote(_id);
    if (vote.hasPenalty && block.number > vote.endOnBlock && vote.hasReachedQuorum == false) {
      for (uint256 i = 0; i < _numberOfUuidsToPenalize; i = SafeMath.add(i, 1)) {
        elasticBallotStorage.penalizeNonVoter(_uuidsToPenalize[i], _id, vote.penalty);
      }
    }
  }

  /**
   * @dev records the vote
   * @param _id - the ID of the vote
   * @param _yna - (abbr) Yes No Abstain -  0 1 2 values respectively
   * If the vote is currently active, records the _yna value with respect to _id
   */
  function vote(uint256 _id, uint256 _yna) public {
    require(elasticVoteStorage.isVoteActive(_id), 'ElasticDAO: Vote is not active');
    require(_yna <= 2, 'ElasticDAO: Invalid Vote Value - 0:Yes, 1:NO, 2:ABSTAIN');
    elasticBallotStorage.recordVote(msg.sender, _id, _yna);
  }
}
