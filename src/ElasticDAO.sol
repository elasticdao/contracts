// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

// Contracts
import './ElasticStorage.sol';
import './tokens/ElasticGovernanceToken.sol';

// Libraries
import './libraries/ElasticMathLib.sol';
import './libraries/SafeMath.sol';
import './libraries/StringLib.sol';

contract ElasticDAO {
  ElasticStorage internal elasticStorage;

  modifier onlyAfterSummoning() {
    require(elasticStorage.daoSummoned(), 'ElasticDAO: DAO must be summoned');
    _;
  }
  modifier onlyBeforeSummoning() {
    require(elasticStorage.daoSummoned() == false, 'ElasticDAO: DAO must not be summoned');
    _;
  }
  modifier onlySummoners() {
    require(elasticStorage.isSummoner(msg.sender), 'ElasticDAO: Only summoners');
    _;
  }

  constructor(
    address[] calldata _summoners,
    string[3] calldata _stringData,
    bool[4] calldata _boolData,
    uint256[15] calldata _uintData
  ) {
    elasticStorage = new ElasticStorage();

    ElasticStorage.DAO memory dao;
    string memory name = _stringData[0];
    dao.name = name;
    dao.summoned = false;
    dao.lambda = 0;

    ElasticStorage.Token memory token;
    string memory tokenName = _stringData[1];
    string memory tokenSymbol = _stringData[2];
    token.elasticity = _uintData[2];
    token.capitalDelta = _uintData[1];
    token.k = _uintData[0];
    token.m = 1;
    token.name = tokenName;
    token.symbol = tokenSymbol;

    elasticStorage.setSummoners(_summoners, _uintData[3]);

    ElasticStorage.VoteSettings memory voteSettings;
    voteSettings.approval = _uintData[4];
    voteSettings.counter = 0;
    voteSettings.maxSharesPerAccount = _uintData[5];
    voteSettings.minBlocksForPenalty = _uintData[9];
    voteSettings.minSharesToCreate = _uintData[11];
    voteSettings.penalty = _uintData[12];
    voteSettings.quorum = _uintData[13];
    voteSettings.reward = _uintData[14];

    ElasticStorage.VoteType memory contractVoteType;
    contractVoteType.minBlocks = _uintData[6];
    contractVoteType.name = 'contract';
    contractVoteType.hasPenalty = _boolData[0];

    ElasticStorage.VoteType memory financeVoteType;
    financeVoteType.minBlocks = _uintData[7];
    financeVoteType.name = 'finance';
    financeVoteType.hasPenalty = _boolData[1];

    ElasticStorage.VoteType memory informationVoteType;
    informationVoteType.minBlocks = _uintData[8];
    informationVoteType.name = 'information';
    informationVoteType.hasPenalty = _boolData[2];

    ElasticStorage.VoteType memory permissionVoteType;
    permissionVoteType.minBlocks = _uintData[10];
    permissionVoteType.name = 'permission';
    permissionVoteType.hasPenalty = _boolData[3];

    elasticStorage.setDAO(dao);
    elasticStorage.setToken(token);
    elasticStorage.setVoteSettings(voteSettings);
    elasticStorage.setVoteType(contractVoteType);
    elasticStorage.setVoteType(financeVoteType);
    elasticStorage.setVoteType(informationVoteType);
    elasticStorage.setVoteType(permissionVoteType);
  }

  function joinDAO(uint256 _deltaLambda) public payable onlyAfterSummoning {
    ElasticStorage.AccountBalance accountBalance = elasticStorage.getAccountBalance(msg.sender);
    ElasticStorage.MathData mathData = elasticStorage.getMathData(address(this).balance);

    uint256 lambdaDash = SafeMath.add(_deltaLambda, accountBalance.lambda);

    require(
      lambdaDash <= mathData.maxSharesPerAccount,
      'ElasticDAO: Cannot purchase that many shares'
    );

    uint256 deltaE = ElasticMathLib.deltaE(
      _deltaLambda,
      mathData.capitalDelta,
      mathData.k,
      mathData.elasticity,
      mathData.lambda,
      mathData.m
    );

    require(deltaE == msg.value, 'ElasticDAO: Incorrect ETH amount');

    mathData.m = ElasticMathLib.mDash(lambdaDash, mathData.lambda, mathData.m);
    mathData.lambda = lambdaDash;

    elasticStorage.updateBalance(accountBalance.uuid, true, _deltaLambda);
    elasticStorage.updateMathData(mathData);
  }

  function seedSummoning() public payable onlyBeforeSummoning onlySummoners {
    ElasticStorage.AccountBalance accountBalance = elasticStorage.getAccountBalance(msg.sender);
    ElasticStorage.Token token = elasticStorage.getToken();

    uint256 deltaE = msg.value;
    uint256 deltaLambda = SafeMath.div(SafeMath.div(deltaE, token.capitalDelta), token.k);
    elasticStorage.updateBalance(msg.sender, true, deltaLambda);
  }

  function summon() public onlyBeforeSummoning onlySummoners {
    require(address(this).balance > 0, 'ElasticDAO: Please seed DAO with ETH to set ETH:EGT ratio');

    ElasticStorage.Token memory token = elasticStorage.getToken();

    token.uuid = new ElasticGovernanceToken(address(elasticStorage));

    elasticStorage.setToken(token);
    elasticStorage.setSummoned();
  }
}
