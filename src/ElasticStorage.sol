// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import './EternalStorage.sol';
import './libraries/ElasticMathLib.sol';
import './libraries/SafeMath.sol';
import './libraries/StringLib.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing Elastic data
/// @dev ElasticDAO network contracts can read/write from this contract
/// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract ElasticStorage is EternalStorage {
  struct AccountBalance {
    address uuid;
    uint256 counter;
    uint256 e;
    uint256 k;
    uint256 lambda;
    uint256 m;
    uint256 t;
  }

  struct DAO {
    bool summoned;
    string name;
    uint256 lambda;
  }

  struct MathData {
    uint256 capitalDelta;
    uint256 e;
    uint256 elasticity;
    uint256 k;
    uint256 lambda;
    uint256 m;
    uint256 maxSharesPerAccount;
    uint256 t;
  }

  struct ShareUpdate {
    address uuid;
    bool isIncreasing;
    uint256 blockNumber;
    uint256 counter;
    uint256 deltaLambda;
    uint256 deltaT;
    uint256 k;
    uint256 m;
  }

  struct Token {
    address uuid;
    string name;
    string symbol;
    uint256 capitalDelta;
    uint256 elasticity;
    uint256 k;
    uint256 m;
  }

  struct Vote {
    bool hasPenalty;
    bool hasReachedQuorum;
    bool isActive;
    bool isApproved;
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

  struct VoteBallot {
    address uuid;
    uint256 lambda;
    uint256 voteId;
    uint256 yna;
  }

  struct VoteInformation {
    string proposal;
    uint256 id;
  }

  struct VoteSettings {
    uint256 approval;
    uint256 counter;
    uint256 maxSharesPerAccount;
    uint256 minBlocksForPenalty;
    uint256 minSharesToCreate;
    uint256 penalty;
    uint256 quorum;
    uint256 reward;
  }

  struct VoteType {
    string name;
    bool hasPenalty;
    uint256 minBlocks;
  }

  /**
   * @dev grants a specific address the ability to create a vote
   * @param _uuid is the address the permission is to be granted to
   * lambda - the the total shares of the DAO
   * minSharesToCreate - the minimum number of shares required to create a vote in the DAO
   * checks if lambda >= minSharesToCreate
   * @return hasPermission bool
   */
  function canCreateVote(address _uuid) external view returns (bool hasPermission) {
    uint256 lambda = getUint(keccak256(abi.encode('dao.shares', _uuid)));
    uint256 minSharesToCreate = getUint('dao.vote.minSharesToCreate');
    return lambda >= minSharesToCreate;
  }

  /**
   * @dev creates the vote information
   * @param _vote is the vote itself
   * @param _voteInformation is the information regarding the current vote
   * @param _voteSettings are the settings which the current vote has to follow
   * The function takes in params and serializes vote, voteInformation
   * and sets the DAO's Vote counter.
   */
  function createVoteInformation(
    Vote memory _vote,
    VoteInformation memory _voteInformation,
    VoteSettings memory _voteSettings
  ) external {
    _serializeVote(_vote);
    _serializeVoteInformation(_voteInformation);
    setUint('dao.vote.counter', _voteSettings.counter);
  }

  /**
   * @dev returns the current state of the DAO with respect to summoning
   * @return isSummoned bool
   */
  function daoSummoned() external view returns (bool isSummoned) {
    return getBool('dao.summoned');
  }

  /**
   * @dev returns the account balance of a specific user
   * @param _uuid - Unique User ID - the address of the user
   * @return accountBalance AccountBalance
   */
  function getAccountBalance(address _uuid)
    external
    view
    returns (AccountBalance memory accountBalance)
  {
    return _deserializeAccountBalance(_uuid);
  }

  /**
   * @dev returns the balance of a specific address at a specific block
   * @param _uuid the unique user identifier - the User's address
   * @param _blockNumber the blockNumber at which the user wants the account balance
   * Essentially the function locally instantiates the counter and shareUpdate,
   * Then using a while loop, loops through shareUpdate's blocks and then
   * checks if the share value is increasing or decreasing,
   * if increasing it updates t ( the balance of the tokens )
   * by adding deltaT ( the change in the amount of tokens ), else
   * if decreasing it reduces the value of t by deltaT.
   * @return t uint256 - the balance at that block
   */
  function getBalanceAtBlock(address _uuid, uint256 _blockNumber)
    internal
    view
    returns (uint256 t)
  {
    uint256 i = 0;
    t = 0;

    uint256 counter = getUint(keccak256(abi.encode('dao.shares.counter', _uuid)));

    ShareUpdate memory shareUpdate = _deserializeShareUpdate(_uuid, i);

    while (i <= counter && shareUpdate.blockNumber != 0 && shareUpdate.blockNumber < _blockNumber) {
      if (shareUpdate.isIncreasing) {
        t = SafeMath.add(t, shareUpdate.deltaT);
      } else {
        t = SafeMath.sub(t, shareUpdate.deltaT);
      }

      i = SafeMath.add(i, 1);

      shareUpdate = _deserializeShareUpdate(_uuid, i);
    }

    return t;
  }

  /**
   * @dev Gets the DAO's data
   * @return dao DAO
   */
  function getDAO() external view returns (DAO memory dao) {
    return _deserializeDAO();
  }

  /**
   * @dev Gets the Math data
   * @param e - Eth value
   * @return mathData MathData
   */
  function getMathData(uint256 e) external view returns (MathData memory mathData) {
    return _deserializeMathData(e);
  }

  /**
   * @dev Gets the Token
   * @param token - The token of the DAO
   * @return token Token
   */
  function getToken() external view returns (Token memory token) {
    return _deserializeToken();
  }

  /**
   * @dev Gets the vote using it's ID
   * @param _id - The id of the vote requested
   * @return vote Vote
   */
  function getVote(uint256 _id) external view returns (Vote memory vote) {
    return _deserializeVote(_id);
  }

  /**
   * @dev Gets the vote ballot
   * @param _uuid - the unique user Id
   * @param _id - the specific voteId
   * @return voteBallot VoteBallot
   */
  function getVoteBallot(address _uuid, uint256 _id) external view returns (VoteBallot memory) {
    return _deserializeVoteBallot(_uuid, _id);
  }

  /**
   * @dev Gets the vote information
   * @param _id - The id of the vote
   * @return voteInformation VoteInformation
   */
  function getVoteInformation(uint256 _id)
    external
    view
    returns (VoteInformation memory voteInformation)
  {
    return _deserializeVoteInformation(_id);
  }

  /**
   * @dev Gets the Vote settings
   * @return voteSettings VoteSettings
   */
  function getVoteSettings() external view returns (VoteSettings memory voteSettings) {
    return _deserializeVoteSettings();
  }

  /**
   * @dev Gets the voteType based on its name
   * @param _name - The name of the vote
   * @return voteType VoteType
   */
  function getVoteType(string memory _name) external view returns (VoteType memory voteType) {
    return _deserializeVoteType(_name);
  }

  /**
   * @dev checks whether given address is a summoner
   * @param _account - The address of the account
   * @return accountIsSummoner bool
   */
  function isSummoner(address _account) external view returns (bool accountIsSummoner) {
    return getBool(keccak256(abi.encode('dao.summoner', _account)));
  }

  /**
   * @dev checks whether the vote is active or not
   * @param _id - the ID of the vote
   * @return bool
   */
  function isVoteActive(uint256 _id) external view returns (bool) {
    return _isVoteActive(_id);
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
  function penalizeNonVoter(address _uuid, uint256 _id) external {
    bool hasPenalty = getBool(keccak256(abi.encode('dao.vote.', _id, '.hasPenalty')));

    if (hasPenalty) {
      uint256 voteLambda = getUint(keccak256(abi.encode('dao.vote.', _id, _uuid, '.lambda')));
      uint256 existingPenalty = getUint(keccak256(abi.encode('dao.vote.', _id, _uuid, '.penalty')));

      if (voteLambda == 0 && existingPenalty == 0) {
        uint256 penalty = getUint(keccak256(abi.encode('dao.vote.', _id, '.penalty')));
        uint256 lambda = getUint(keccak256(abi.encode('dao.shares', _uuid)));
        uint256 deltaLambda = ElasticMathLib.wmul(lambda, penalty);
        setUint(keccak256(abi.encode('dao.vote.', _id, _uuid, '.penalty')), deltaLambda);
        _updateBalance(_uuid, false, deltaLambda);
      }
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
  ) external {
    VoteBallot memory voteBallot = _deserializeVoteBallot(_uuid, _id);

    if (voteBallot.lambda > 0) {
      if (voteBallot.yna == 0) {
        _recordBallotChange(_id, voteBallot.lambda, false, '.yesLambda');
      } else if (voteBallot.yna == 1) {
        _recordBallotChange(_id, voteBallot.lambda, false, '.noLambda');
      } else {
        _recordBallotChange(_id, voteBallot.lambda, false, '.abstainLambda');
      }
    }

    voteBallot.lambda = _getVoteBalance(msg.sender, _id);
    voteBallot.yna = _yna;

    if (voteBallot.yna == 0) {
      _recordBallotChange(_id, voteBallot.lambda, true, '.yesLambda');
    } else if (voteBallot.yna == 1) {
      _recordBallotChange(_id, voteBallot.lambda, true, '.noLambda');
    } else {
      _recordBallotChange(_id, voteBallot.lambda, true, '.abstainLambda');
    }

    _serializeVoteBallot(voteBallot);
  }

  /**
   * @dev Sets the DAO
   * @param dao - The data of the DAO
   */
  function setDAO(DAO memory dao) external {
    _serializeDAO(dao);
  }

  /**
   * @dev Sets the MathData
   * @param mathData - The mathData required by the DAO
   */
  function setMathData(MathData memory mathData) external {
    _serializeMathData(mathData);
  }

  /**
   * @dev Sets the summoned state of the DAO to true
   */
  function setSummoned() external {
    setBool('dao.summoned', true);
  }

  /**
   * @dev sets the vote module
   * @param _voteModule - the addresss of the vote module
   */
  function setVoteModule(address _voteModule) external {
    setAddress('dao.vote', _voteModule);
  }

  /**
   * @dev Sets the summoners of the DAO
   * @param _summoners - an address array of all the summoners
   * @param _initialSummonerShare - the intitial share each summoner gets
   */
  function setSummoners(address[] calldata _summoners, uint256 _initialSummonerShare) external {
    for (uint256 i = 0; i < _summoners.length; i++) {
      setBool(keccak256(abi.encode('dao.summoner', _summoners[i])), true);
      _updateBalance(_summoners[i], true, _initialSummonerShare);
    }
  }

  /**
   * @dev Sets the token of the DAO
   * @param token - The token itself that has to be set for the DAO
   */
  function setToken(Token memory token) external {
    _serializeToken(token);
  }

  /**
   * @dev Sets the vote settings
   * @param voteSettings - the vote settings which have to be set
   */
  function setVoteSettings(VoteSettings memory voteSettings) external {
    _serializeVoteSettings(voteSettings);
  }

  /**
   * @dev Sets the type of the vote
   * @param voteType - the type of the vote itself
   */
  function setVoteType(VoteType memory voteType) external {
    _serializeVoteType(voteType);
  }

  /**
   * @dev updates the balance of an address
   * @param _uuid - Unique User ID - the address of the user
   * @param _isIncreasing - whether the balance is increasing or not
   * @param _deltaLambda - the change in the number of shares
   */
  function updateBalance(
    address _uuid,
    bool _isIncreasing,
    uint256 _deltaLambda
  ) external {
    _updateBalance(_uuid, _isIncreasing, _deltaLambda);
  }

  function _deserializeAccountBalance(address _uuid)
    internal
    view
    returns (AccountBalance memory accountBalance)
  {
    accountBalance.counter = getUint(keccak256(abi.encode('dao.shares.counter', _uuid)));
    accountBalance.k = getUint('dao.token.constant');
    accountBalance.lambda = getUint(keccak256(abi.encode('dao.shares', _uuid)));
    accountBalance.m = getUint('dao.token.modifier');
    accountBalance.t = SafeMath.mul(
      SafeMath.mul(accountBalance.lambda, accountBalance.m),
      accountBalance.k
    );
    accountBalance.uuid = _uuid;
  }

  function _deserializeDAO() internal view returns (DAO memory dao) {
    dao.name = getString('dao.name');
    dao.summoned = getBool('dao.summoned');
    dao.lambda = getUint('dao.totalShares');
  }

  function _deserializeMathData(uint256 e) internal view returns (MathData memory mathData) {
    mathData.e = e;
    mathData.k = getUint('dao.token.constant');
    mathData.elasticity = getUint('dao.token.elasticity');
    mathData.lambda = getUint('dao.totalShares');
    mathData.m = getUint('dao.token.modifier');
    mathData.maxSharesPerAccount = getUint('dao.vote.maxSharesPerAccount');
    mathData.t = ElasticMathLib.t(mathData.lambda, mathData.k, mathData.m);
    if (mathData.e > 0) {
      mathData.capitalDelta = SafeMath.div(mathData.e, mathData.t);
    }
    return mathData;
  }

  function _deserializeShareUpdate(address _uuid, uint256 _counter)
    internal
    view
    returns (ShareUpdate memory shareUpdate)
  {
    shareUpdate.blockNumber = getUint(
      keccak256(abi.encode('dao.shares.blockNumber', _counter, _uuid))
    );
    shareUpdate.counter = _counter;
    shareUpdate.deltaLambda = getUint(
      keccak256(abi.encode('dao.shares.deltaLambda', _counter, _uuid))
    );
    shareUpdate.isIncreasing = getBool(
      keccak256(abi.encode('dao.shares.isIncreasing', _counter, _uuid))
    );
    shareUpdate.k = getUint(keccak256(abi.encode('dao.shares.constant', _counter, _uuid)));
    shareUpdate.m = getUint(keccak256(abi.encode('dao.shares.modifier', _counter, _uuid)));
    shareUpdate.deltaT = ElasticMathLib.t(shareUpdate.deltaLambda, shareUpdate.m, shareUpdate.k);

    shareUpdate.uuid = _uuid;
    return shareUpdate;
  }

  function _deserializeToken() internal view returns (Token memory token) {
    token.capitalDelta = getUint('dao.token.initialCapitalDelta');
    token.elasticity = getUint('dao.token.elasticity');
    token.k = getUint('dao.token.constant');
    token.m = getUint('dao.token.modifier');
    token.name = getString('dao.token.name');
    token.symbol = getString('dao.token.symbol');
    token.uuid = getAddress('dao.token.address');
    return token;
  }

  function _deserializeVote(uint256 _id) internal view returns (Vote memory vote) {
    vote.abstainLambda = getUint(keccak256(abi.encode('dao.vote.', _id, '.abstainLambda')));
    vote.approval = getUint(keccak256(abi.encode('dao.vote.', _id, '.approval')));
    vote.endOnBlock = getUint(keccak256(abi.encode('dao.vote.', _id, '.endOnBlock')));
    vote.hasPenalty = getBool(keccak256(abi.encode('dao.vote.', _id, '.hasPenalty')));
    vote.hasReachedQuorum = false;
    vote.id = _id;
    vote.isActive = _isVoteActive(vote.id);
    vote.isApproved = false;
    vote.maxSharesPerAccount = getUint(
      keccak256(abi.encode('dao.vote.', _id, '.maxSharesPerAccount'))
    );
    vote.minBlocksForPenalty = getUint(
      keccak256(abi.encode('dao.vote.', _id, '.minBlocksForPenalty'))
    );
    vote.noLambda = getUint(keccak256(abi.encode('dao.vote.', _id, '.noLambda')));
    vote.penalty = getUint(keccak256(abi.encode('dao.vote.', _id, '.penalty')));
    vote.quorum = getUint(keccak256(abi.encode('dao.vote.', _id, '.quorum')));
    vote.reward = getUint(keccak256(abi.encode('dao.vote.', _id, '.reward')));
    vote.startOnBlock = getUint(keccak256(abi.encode('dao.vote.', _id, '.startOnBlock')));
    vote.voteType = getString(keccak256(abi.encode('dao.vote.', _id, '.voteType')));
    vote.yesLambda = getUint(keccak256(abi.encode('dao.vote.', _id, '.yesLambda')));

    uint256 lambda = getUint('dao.totalShares');
    uint256 minimumQuorumLambda = ElasticMathLib.wmul(lambda, getUint('dao.vote.quorum'));
    uint256 minimumYesLambda = ElasticMathLib.wmul(lambda, getUint('dao.vote.approval'));
    uint256 quorumLambda = SafeMath.add(
      vote.yesLambda,
      SafeMath.add(vote.noLambda, vote.abstainLambda)
    );

    if (quorumLambda >= minimumQuorumLambda) {
      vote.hasReachedQuorum = true;
    }

    if (vote.yesLambda >= minimumYesLambda) {
      vote.isApproved = true;
    }

    return vote;
  }

  function _deserializeVoteBallot(address _uuid, uint256 _id)
    internal
    view
    returns (VoteBallot memory voteBallot)
  {
    voteBallot.lambda = getUint(keccak256(abi.encode('dao.vote.', _id, _uuid, '.lambda')));
    voteBallot.uuid = _uuid;
    voteBallot.voteId = _id;
    voteBallot.yna = getUint(keccak256(abi.encode('dao.vote.', _id, _uuid, '.yna')));
    return voteBallot;
  }

  function _deserializeVoteInformation(uint256 _id)
    internal
    view
    returns (VoteInformation memory voteInformation)
  {
    voteInformation.id = _id;
    voteInformation.proposal = getString(
      keccak256(abi.encode('dao.vote.information.', _id, '.proposal'))
    );
    return voteInformation;
  }

  function _deserializeVoteSettings() internal view returns (VoteSettings memory voteSettings) {
    voteSettings.approval = getUint('dao.vote.approval');
    voteSettings.counter = getUint('dao.vote.counter');
    voteSettings.maxSharesPerAccount = getUint('dao.vote.maxSharesPerAccount');
    voteSettings.minBlocksForPenalty = getUint('dao.vote.minBlocksForPenalty');
    voteSettings.minSharesToCreate = getUint('dao.vote.minSharesToCreate');
    voteSettings.penalty = getUint('dao.vote.penalty');
    voteSettings.quorum = getUint('dao.vote.quorum');
    voteSettings.reward = getUint('dao.vote.reward');
    return voteSettings;
  }

  function _deserializeVoteType(string memory name)
    internal
    view
    returns (VoteType memory voteType)
  {
    voteType.name = name;
    voteType.hasPenalty = getBool(keccak256(abi.encode('dao.vote.type', name, 'hasPenalty')));
    voteType.minBlocks = getUint(keccak256(abi.encode('dao.vote.type', name, 'minBlocks')));
    return voteType;
  }

  function _getVoteBalance(address _uuid, uint256 _id) internal view returns (uint256 voteLambda) {
    voteLambda = getUint(keccak256(abi.encode('dao.vote.', _id, '.maxSharesPerAccount')));

    uint256 currentLambda = getUint(keccak256(abi.encode('dao.shares', _uuid)));
    if (currentLambda < voteLambda) {
      voteLambda = currentLambda;
    }

    uint256 startOnBlock = getUint(keccak256(abi.encode('dao.vote.', _id, '.startOnBlock')));
    uint256 blockLambda = getBalanceAtBlock(_uuid, startOnBlock);
    if (blockLambda < voteLambda) {
      voteLambda = blockLambda;
    }

    return voteLambda;
  }

  function _isVoteActive(uint256 _id) internal view returns (bool) {
    uint256 endOnBlock = getUint(keccak256(abi.encode('dao.vote.', _id, '.endOnBlock')));
    uint256 startOnBlock = getUint(keccak256(abi.encode('dao.vote.', _id, '.endOnBlock')));
    return block.number >= startOnBlock && block.number <= endOnBlock;
  }

  function _recordBallotChange(
    uint256 _id,
    uint256 _deltaLambda,
    bool _isIncreasing,
    string memory _ynaKey
  ) internal {
    bytes32 key = keccak256(abi.encode('dao.vote.', _id, _ynaKey));
    if (_isIncreasing) {
      setUint(key, SafeMath.add(getUint(key), _deltaLambda));
    } else {
      setUint(key, SafeMath.sub(getUint(key), _deltaLambda));
    }
  }

  function _serializeAccountBalance(AccountBalance memory accountBalance) internal {
    setUint(keccak256(abi.encode('dao.shares', accountBalance.uuid)), accountBalance.lambda);
    setUint(
      keccak256(abi.encode('dao.shares.counter', accountBalance.uuid)),
      accountBalance.counter
    );
  }

  function _serializeDAO(DAO memory dao) internal {
    setString('dao.name', dao.name);
    setBool('dao.summoned', dao.summoned);
    setUint('dao.totalShares', dao.lambda);
  }

  function _serializeMathData(MathData memory mathData) internal {
    setUint('dao.totalShares', mathData.lambda);
    setUint('dao.token.modifier', mathData.m);
  }

  function _serializeShareUpdate(ShareUpdate memory shareUpdate) internal {
    setBool(
      keccak256(abi.encode('dao.shares.isIncreasing', shareUpdate.counter, shareUpdate.uuid)),
      shareUpdate.isIncreasing
    );
    setUint(
      keccak256(abi.encode('dao.shares.blockNumber', shareUpdate.counter, shareUpdate.uuid)),
      shareUpdate.blockNumber
    );
    setUint(
      keccak256(abi.encode('dao.shares.deltaLambda', shareUpdate.counter, shareUpdate.uuid)),
      shareUpdate.deltaLambda
    );
    setUint(
      keccak256(abi.encode('dao.shares.modifier', shareUpdate.counter, shareUpdate.uuid)),
      shareUpdate.m
    );
    setUint(
      keccak256(abi.encode('dao.shares.constant', shareUpdate.counter, shareUpdate.uuid)),
      shareUpdate.k
    );
  }

  function _serializeToken(Token memory token) internal {
    Token memory currentToken = _deserializeToken();

    if (currentToken.uuid != address(0)) {
      return;
    }

    if (token.uuid != address(0)) {
      setAddress('dao.token.address', token.uuid);
      return;
    }

    setString('dao.token.name', token.name);
    setString('dao.token.symbol', token.symbol);
    setUint('dao.token.constant', token.k);
    setUint('dao.token.initialCapitalDelta', token.capitalDelta);
    setUint('dao.token.elasticity', token.elasticity);
    setUint('dao.token.modifier', token.m);
  }

  function _serializeVoteSettings(VoteSettings memory voteSettings) internal {
    setUint('dao.vote.approval', voteSettings.approval);
    setUint('dao.vote.counter', voteSettings.counter);
    setUint('dao.vote.maxSharesPerAccount', voteSettings.maxSharesPerAccount);
    setUint('dao.vote.minBlocksForPenalty', voteSettings.minBlocksForPenalty);
    setUint('dao.vote.minSharesToCreate', voteSettings.minSharesToCreate);
    setUint('dao.vote.penalty', voteSettings.penalty);
    setUint('dao.vote.quorum', voteSettings.quorum);
    setUint('dao.vote.reward', voteSettings.reward);
  }

  function _serializeVote(Vote memory vote) internal {
    setBool(keccak256(abi.encode('dao.vote.', vote.id, '.hasPenalty')), vote.hasPenalty);
    setString(keccak256(abi.encode('dao.vote.', vote.id, '.voteType')), vote.voteType);
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.abstainLambda')), vote.abstainLambda);
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.approval')), vote.approval);
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.endOnBlock')), vote.endOnBlock);
    setUint(
      keccak256(abi.encode('dao.vote.', vote.id, '.maxSharesPerAccount')),
      vote.maxSharesPerAccount
    );
    setUint(
      keccak256(abi.encode('dao.vote.', vote.id, '.minBlocksForPenalty')),
      vote.minBlocksForPenalty
    );
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.noLambda')), vote.noLambda);
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.penalty')), vote.penalty);
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.quorum')), vote.quorum);
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.reward')), vote.reward);
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.startOnBlock')), vote.startOnBlock);
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.yesLambda')), vote.yesLambda);
  }

  function _serializeVoteBallot(VoteBallot memory voteBallot) internal {
    setUint(
      keccak256(abi.encode('dao.vote.', voteBallot.voteId, voteBallot.uuid, '.lambda')),
      voteBallot.lambda
    );
    setUint(
      keccak256(abi.encode('dao.vote.', voteBallot.voteId, voteBallot.uuid, '.yna')),
      voteBallot.lambda
    );
  }

  function _serializeVoteInformation(VoteInformation memory voteInformation) internal {
    setString(
      keccak256(abi.encode('dao.vote.information.', voteInformation.id, '.proposal')),
      voteInformation.proposal
    );
  }

  function _serializeVoteType(VoteType memory voteType) internal {
    setBool(
      keccak256(abi.encode('dao.vote.type', voteType.name, 'hasPenalty')),
      voteType.hasPenalty
    );
    setUint(keccak256(abi.encode('dao.vote.type', voteType.name, 'minBlocks')), voteType.minBlocks);
  }

  function _updateBalance(
    address _uuid,
    bool _isIncreasing,
    uint256 _deltaLambda
  ) internal {
    AccountBalance memory accountBalance = _deserializeAccountBalance(_uuid);
    DAO memory dao;
    dao.lambda = getUint('dao.totalShares');

    if (_isIncreasing) {
      accountBalance.lambda = SafeMath.add(accountBalance.lambda, _deltaLambda);
      dao.lambda = SafeMath.add(dao.lambda, _deltaLambda);
    } else {
      accountBalance.lambda = SafeMath.sub(accountBalance.lambda, _deltaLambda);
      dao.lambda = SafeMath.sub(dao.lambda, _deltaLambda);
    }

    ShareUpdate memory shareUpdate;
    shareUpdate.blockNumber = block.number;
    shareUpdate.counter = accountBalance.counter;
    shareUpdate.deltaLambda = _deltaLambda;
    shareUpdate.isIncreasing = _isIncreasing;
    shareUpdate.k = accountBalance.k;
    shareUpdate.m = accountBalance.m;
    shareUpdate.uuid = _uuid;

    _serializeAccountBalance(accountBalance);
    _serializeShareUpdate(shareUpdate);
    setUint('dao.totalShares', dao.lambda);
  }
}
