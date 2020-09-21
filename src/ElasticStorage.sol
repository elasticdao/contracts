// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import './EternalStorage.sol';
import './libraries/SafeMath.sol';
import './libraries/StringLib.sol';

contract ElasticStorage is EternalStorage {
  struct AccountBalance {
    address account;
    uint256 counter;
    uint256 e;
    uint256 lambda;
    uint256 t;
  }

  struct DAO {
    bool summoned;
    string name;
  }

  struct ShareUpdate {
    address account;
    bool isIncreasing;
    uint256 blockNumber;
    uint256 counter;
    uint256 deltaLambda;
  }

  struct Token {
    address uuid;
    string name;
    string symbol;
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

  constructor() EternalStorage() {}

  function daoSummoned() external view returns (bool isSummoned) {}

  function getDAO() external view returns (DAO memory dao) {
    return _deserializeDao();
  }

  function getToken() external view returns (Token memory token) {
    return _deserializeToken();
  }

  function getVoteSettings() external view returns (VoteSettings memory voteSettings) {
    return _deserializeVoteSettings();
  }

  function getVoteType(string memory name) external view returns (VoteType memory voteType) {
    return _deserializeVoteType(name);
  }

  function isSummoner(address _account) external view returns (bool accountIsSummoner) {
    return getBool(keccak256(abi.encode('dao.summoner', _account)));
  }

  function setDAO(DAO memory dao) external {
    _serializeDao(dao);
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

  function _setVoteType(VoteType memory voteType) external {
    _serializeVoteType(voteType);
  }

  function _updateBalance(
    address _account,
    bool _isIncreasing,
    uint256 _deltaLambda // amount
  ) internal {
    uint256 lambda = getUint(keccak256(abi.encode('dao.totalShares')));
    AccountBalance memory accountBalance = _deserializeAccountBalance(_account);

    if (_isIncreasing) {
      accountBalance.lambda = SafeMath.add(accountBalance.lambda, _deltaLambda);
      lambda = SafeMath.add(lambda, _deltaLambda);
    } else {
      accountBalance.lambda = SafeMath.sub(accountBalance.lambda, _deltaLambda);
      lambda = SafeMath.sub(lambda, _deltaLambda);
    }

    ShareUpdate memory shareUpdate;
    shareUpdate.account = _account;
    shareUpdate.blockNumber = block.number;
    shareUpdate.counter = accountBalance.counter;
    shareUpdate.deltaLambda = _deltaLambda;
    shareUpdate.isIncreasing = _isIncreasing;

    _serializeAccountBalance(accountBalance);
    _serializeShareUpdate(shareUpdate);
  }

  function _deserializeAccountBalance(address _account)
    internal
    view
    returns (AccountBalance memory accountBalance)
  {
    accountBalance.account = _account;
    accountBalance.counter = getUint(keccak256(abi.encode('dao.shares.counter', _account)));
    accountBalance.lambda = getUint(keccak256(abi.encode('dao.shares', _account)));
  }

  function _deserializeDao() internal view returns (DAO memory dao) {
    dao.name = getString('dao.name');
    dao.summoned = getBool('dao.summoned');
  }

  function _deserializeShareUpdate(address _account, uint256 _counter)
    internal
    view
    returns (ShareUpdate memory shareUpdate)
  {
    shareUpdate.account = _account;
    shareUpdate.blockNumber = getUint(
      keccak256(abi.encode('dao.shares.blockNumber', _counter, _account))
    );
    shareUpdate.counter = _counter;
    shareUpdate.deltaLambda = getUint(
      keccak256(abi.encode('dao.shares.deltaLambda', _counter, _account))
    );
    shareUpdate.isIncreasing = getBool(
      keccak256(abi.encode('dao.shares.isIncreasing', _counter, _account))
    );
    return shareUpdate;
  }

  function _deserializeToken() internal view returns (Token memory token) {
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
    setUint(keccak256(abi.encode('dao.shares', accountBalance.account)), accountBalance.lambda);
    setUint(
      keccak256(abi.encode('dao.shares.counter', accountBalance.account)),
      accountBalance.counter
    );
  }

  function _serializeDao(DAO memory dao) internal {
    setString('dao.name', dao.name);
    setBool('dao.summoned', dao.summoned);
  }

  function _serializeShareUpdate(ShareUpdate memory shareUpdate) internal {
    setBool(
      keccak256(abi.encode('dao.shares.isIncreasing', shareUpdate.counter)),
      shareUpdate.isIncreasing
    );
    setUint(
      keccak256(abi.encode('dao.shares.blockNumber', shareUpdate.counter)),
      shareUpdate.blockNumber
    );
    setUint(
      keccak256(abi.encode('dao.shares.deltaLambda', shareUpdate.counter)),
      shareUpdate.deltaLambda
    );
  }

  function _serializeToken(Token memory token) internal {
    setAddress('dao.token.address', token.uuid);
    setString('dao.token.name', token.name);
    setString('dao.token.symbol', token.symbol);
    setUint('dao.token.constant', token.k);
    setUint('dao.token.elasticity', token.elasticity);
    setUint('dao.token.modifier', token.m);
    return token;
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
