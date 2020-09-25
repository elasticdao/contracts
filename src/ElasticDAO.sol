// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

// Contracts
import './ElasticStorage.sol';
import './ElasticVote.sol';
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
    address[] memory _summoners,
    string[3] memory _stringData,
    bool[4] memory _boolData,
    uint256[15] memory _uintData
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

  /**
   * @dev joins the DAO
   * @param _deltaLambda - The change in the amount of shares
   *
   * capitalDelta is the Eth/Egt ratio
   * deltaE - amount of ETH required to purchase @param _deltaLambda shares
   * k is a constant, initially set by the DAO
   * lambdaDash - total shares after the purchase
   * m - current share modifier
   * mDash - share modifier after the purchase of shares, i.e new share modifier
   *
   * deltaE =  ( capitalDelta * k ( ( lambdaDash * mDash * ( 1 + elasticity ) ) - lambda * m )
   * lambdaDash = ( mDash/m ) * lambda
   *
   * Essentially the function takes @param _deltaLambda calculates lambdadash,
   * checks if that many shares can be purchased, and if so purchases it after checking if the
   * correct amount of Eth was given to purchase @param _deltaLambda shares, i.e deltaE
   *
   */
  function joinDAO(uint256 _deltaLambda) public payable onlyAfterSummoning {
    ElasticStorage.AccountBalance memory accountBalance = elasticStorage.getAccountBalance(
      msg.sender
    );
    ElasticStorage.MathData memory mathData = elasticStorage.getMathData(address(this).balance);

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
    elasticStorage.setMathData(mathData);
  }

  /**
   * @dev does seed summoning of the DAO, can only be done by summoners
   * deltaE - amount of ETH required to purchase deltaLambda shares
   * deltaLambda - The change in the amount of shares
   */
  function seedSummoning() public payable onlyBeforeSummoning onlySummoners {
    ElasticStorage.Token memory token = elasticStorage.getToken();

    uint256 deltaE = msg.value;
    uint256 deltaLambda = SafeMath.div(SafeMath.div(deltaE, token.capitalDelta), token.k);
    elasticStorage.updateBalance(msg.sender, true, deltaLambda);
  }

  /**
   * @dev summons the DAO
   * checks if DAO hasn't already been summoned, and that only summoners can summon the DAO
   */
  function summon() public onlyBeforeSummoning onlySummoners {
    require(address(this).balance > 0, 'ElasticDAO: Please seed DAO with ETH to set ETH:EGT ratio');

    ElasticStorage.Token memory token = elasticStorage.getToken();

    token.uuid = address(new ElasticGovernanceToken(address(elasticStorage)));
    elasticStorage.setToken(token);

    ElasticVote voteModule = new ElasticVote(address(elasticStorage));
    elasticStorage.setVoteModule(address(voteModule));

    elasticStorage.setSummoned();
  }
}
