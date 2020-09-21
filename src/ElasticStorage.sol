// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import './EternalStorage.sol';
import './libraries/ElasticMathLib.sol';
import './libraries/SafeMath.sol';
import './libraries/StringLib.sol';

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

  struct VoteSettings {
    uint256 approval;
    uint256 maxSharesPerAccount;
    uint256 minBlocksForPenalty;
    uint256 minSharesToCreate;
    uint256 penalty;
    uint256 quorum;
    uint256 reward;
  }

  struct VoteType {
    string name;
    bool penalty;
    uint256 minBlocks;
  }

  function daoSummoned() external view returns (bool isSummoned) {
    return getBool('dao.summoned');
  }

  function getAccountBalance(address _uuid)
    external
    view
    returns (AccountBalance memory accountBalance)
  {
    return _deserializeAccountBalance(_uuid);
  }

  function getBalanceAtBlock(address _uuid, uint256 _blockNumber)
    external
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

  function getDAO() external view returns (DAO memory dao) {
    return _deserializeDAO();
  }

  function getMathData(uint256 e) external view returns (MathData memory mathData) {
    return _deserializeMathData(e);
  }

  function getToken() external view returns (Token memory token) {
    return _deserializeToken();
  }

  function getVoteSettings() external view returns (VoteSettings memory voteSettings) {
    return _deserializeVoteSettings();
  }

  function getVoteType(string memory _name) external view returns (VoteType memory voteType) {
    return _deserializeVoteType(_name);
  }

  function isSummoner(address _account) external view returns (bool accountIsSummoner) {
    return getBool(keccak256(abi.encode('dao.summoner', _account)));
  }

  function setDAO(DAO memory dao) external {
    _serializeDAO(dao);
  }

  function setMathData(MathData memory mathData) external {
    _serializeMathData(mathData);
  }

  function setSummoned() external {
    setBool('dao.summoned', true);
  }

  function setSummoners(address[] calldata _summoners, uint256 _initialSummonerShare) external {
    for (uint256 i = 0; i < _summoners.length; i++) {
      setBool(keccak256(abi.encode('dao.summoner', _summoners[i])), true);
      _updateBalance(_summoners[i], true, _initialSummonerShare);
    }
  }

  function setToken(Token memory token) external {
    _serializeToken(token);
  }

  function setVoteSettings(VoteSettings memory voteSettings) external {
    _serializeVoteSettings(voteSettings);
  }

  function updateBalance(
    address _uuid,
    bool _isIncreasing,
    uint256 _deltaLambda
  ) external {
    _updateBalance(_uuid, _isIncreasing, _deltaLambda);
  }

  function _setVoteType(VoteType memory voteType) external {
    _serializeVoteType(voteType);
  }

  function _updateBalance(
    address _uuid,
    bool _isIncreasing,
    uint256 _deltaLambda
  ) internal {
    AccountBalance memory accountBalance = _deserializeAccountBalance(_uuid);
    DAO memory dao = _deserializeDAO();

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
    _serializeDAO(dao);
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

  function _deserializeVoteSettings() internal view returns (VoteSettings memory voteSettings) {
    voteSettings.approval = getUint('dao.vote.approval');
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
    voteType.penalty = getBool(keccak256(abi.encode('dao.vote.type', name)));
    voteType.minBlocks = getUint(keccak256(abi.encode('dao.vote.type', name)));
    return voteType;
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
    setUint('dao.vote.maxSharesPerAccount', voteSettings.maxSharesPerAccount);
    setUint('dao.vote.minBlocksForPenalty', voteSettings.minBlocksForPenalty);
    setUint('dao.vote.minSharesToCreate', voteSettings.minSharesToCreate);
    setUint('dao.vote.penalty', voteSettings.penalty);
    setUint('dao.vote.quorum', voteSettings.quorum);
    setUint('dao.vote.reward', voteSettings.reward);
  }

  function _serializeVoteType(VoteType memory voteType) internal {
    setBool(keccak256(abi.encode('dao.vote.type', voteType.name)), voteType.penalty);
    setUint(keccak256(abi.encode('dao.vote.type', voteType.name)), voteType.minBlocks);
  }
}
