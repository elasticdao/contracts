// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import './EternalStorage.sol';
import './ElasticStorage.sol';
import './libraries/ElasticMathLib.sol';
import './libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing Elastic Ballot data
/// @dev ElasticDAO network contracts can read/write from this contract
/// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract ElasticBallotStorage is EternalStorage {
  constructor(address _owner) EternalStorage(_owner) {}

  modifier onlyOwnerOrVoteModule() {
    address voteModuleAddress = getAddress('dao.vote.address');
    require(
      msg.sender == owner || msg.sender == voteModuleAddress,
      'ElasticDAO: Not authorized to call that function.'
    );
    _;
  }

  /**
   * @dev Gets the vote ballot
   * @param _uuid - the unique user Id
   * @param _id - the specific voteId
   * @return voteBallot VoteBallot
   */
  function getVoteBallot(address _uuid, uint256 _id)
    external
    view
    onlyOwnerOrVoteModule
    returns (ElasticStorage.VoteBallot memory)
  {
    return _deserializeVoteBallot(_uuid, _id);
  }

  /**
   * @dev penalizes a Non voter for a given vote
   * @param _uuid - unique user ID
   * @param _id - the ID of the vote
   * voteLambda - The user's shares used for this vote
   *
   * Essentially, if the vote has a penalty on it, followed by which if the userID
   * hasn't been already penalized and voteLamda is 0, calculates deltaLambda and
   * decreases the user's shares by deltaLambda
   *
   * deltaLambda - The change in the amount of shares
   * deltaLambda = (lambda * penalty)
   */
  function penalizeNonVoter(
    address _uuid,
    uint256 _id,
    uint256 _penalty
  ) external onlyOwnerOrVoteModule {
    ElasticStorage elasticStorage = ElasticStorage(owner);
    uint256 voteLambda = getUint(keccak256(abi.encode('dao.vote.', _id, _uuid, '.lambda')));
    uint256 existingPenalty = getUint(keccak256(abi.encode('dao.vote.', _id, _uuid, '.penalty')));

    if (voteLambda == 0 && existingPenalty == 0) {
      ElasticStorage.AccountBalance memory accountBalance = elasticStorage.getAccountBalance(_uuid);
      uint256 deltaLambda = ElasticMathLib.wmul(accountBalance.lambda, _penalty);
      setUint(keccak256(abi.encode('dao.vote.', _id, _uuid, '.penalty')), deltaLambda);
      elasticStorage.updateBalance(_uuid, false, deltaLambda);
    }
  }

  /**
   * @dev records the casting of a vote
   * @param _uuid - Unique user ID
   * @param _id - the ID of the vote
   * @param _yna - (abbr) Yes No Abstain -  0 1 2 values respectively
   *
   * Essentially allows _uuid to cast vote, and if _uuid has already cast the vote,
   * also allows the change of the value of _yna
   */
  function recordVote(
    address _uuid,
    uint256 _id,
    uint256 _yna
  ) external onlyOwnerOrVoteModule {
    ElasticStorage elasticStorage = ElasticStorage(owner);
    ElasticStorage.VoteBallot memory voteBallot = _deserializeVoteBallot(_uuid, _id);

    if (voteBallot.lambda > 0) {
      if (voteBallot.yna == 0) {
        elasticStorage.recordBallotChange(_id, voteBallot.lambda, false, '.yesLambda');
      } else if (voteBallot.yna == 1) {
        elasticStorage.recordBallotChange(_id, voteBallot.lambda, false, '.noLambda');
      } else {
        elasticStorage.recordBallotChange(_id, voteBallot.lambda, false, '.abstainLambda');
      }
    }

    voteBallot.lambda = _getVoteBalance(msg.sender, _id);
    voteBallot.yna = _yna;

    if (voteBallot.yna == 0) {
      elasticStorage.recordBallotChange(_id, voteBallot.lambda, true, '.yesLambda');
    } else if (voteBallot.yna == 1) {
      elasticStorage.recordBallotChange(_id, voteBallot.lambda, true, '.noLambda');
    } else {
      elasticStorage.recordBallotChange(_id, voteBallot.lambda, true, '.abstainLambda');
    }

    _serializeVoteBallot(voteBallot);
  }

  /**
   * @dev sets the vote module
   * @param _voteModuleAddress - the addresss of the vote module
   */
  function setVoteModule(address _voteModuleAddress) external onlyOwner {
    setAddress('dao.vote.address', _voteModuleAddress);
  }

  function _deserializeVoteBallot(address _uuid, uint256 _id)
    internal
    view
    returns (ElasticStorage.VoteBallot memory voteBallot)
  {
    voteBallot.lambda = getUint(keccak256(abi.encode('dao.vote.', _id, _uuid, '.lambda')));
    voteBallot.uuid = _uuid;
    voteBallot.voteId = _id;
    voteBallot.yna = getUint(keccak256(abi.encode('dao.vote.', _id, _uuid, '.yna')));
    return voteBallot;
  }

  function _getVoteBalance(address _uuid, uint256 _id) internal view returns (uint256 voteLambda) {
    ElasticStorage elasticStorage = ElasticStorage(owner);
    ElasticStorage.Vote memory vote = elasticStorage.getVote(_id);

    ElasticStorage.AccountBalance memory accountBalance = elasticStorage.getAccountBalance(_uuid);
    voteLambda = vote.maxSharesPerAccount;

    if (accountBalance.lambda < voteLambda) {
      voteLambda = accountBalance.lambda;
    }

    uint256 blockLambda = elasticStorage.getBalanceAtBlock(_uuid, vote.startOnBlock);
    if (blockLambda < voteLambda) {
      voteLambda = blockLambda;
    }

    return voteLambda;
  }

  function _serializeVoteBallot(ElasticStorage.VoteBallot memory voteBallot) internal {
    setUint(
      keccak256(abi.encode('dao.vote.', voteBallot.voteId, voteBallot.uuid, '.lambda')),
      voteBallot.lambda
    );
    setUint(
      keccak256(abi.encode('dao.vote.', voteBallot.voteId, voteBallot.uuid, '.yna')),
      voteBallot.lambda
    );
  }
}
