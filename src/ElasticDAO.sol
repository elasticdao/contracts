// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

// Contracts
import './EternalStorage.sol';
import './tokens/ElasticGovernanceToken.sol';

// Libraries
import './libraries/ElasticMathLib.sol';
import './libraries/StorageLib.sol';
import './libraries/StringLib.sol';
import './libraries/SafeMath.sol';

contract ElasticDAO {
  EternalStorage internal eternalStorage;

  modifier onlyAfterSummoning() {
    require(
      eternalStorage.getBool(StorageLib.formatLocation('dao.summoned')) == true,
      'ElasticDAO: DAO must be summoned'
    );
    _;
  }
  modifier onlyBeforeSummoning() {
    require(
      eternalStorage.getBool(StorageLib.formatLocation('dao.summoned')) == false,
      'ElasticDAO: DAO must not be summoned'
    );
    _;
  }
  modifier onlySummoners() {
    bool isSummoner = eternalStorage.getBool(StorageLib.formatAddress('dao.summoner', msg.sender));

    require(isSummoner, 'ElasticDAO: Only summoners');
    _;
  }

  constructor(
    address[] memory _summoners,
    string[3] memory _stringData,
    bool[4] memory _boolData,
    uint256[15] memory _uintData
  ) {
    eternalStorage = new EternalStorage();

    require(storeStringData(_stringData));
    require(storeBoolData(_boolData));
    require(storeUintDAOData(_uintData, _summoners));
    require(storeUintVoteData(_uintData));

    // Initialize DAO
    eternalStorage.setBool(StorageLib.formatLocation('dao.summoned'), false);
  }

  function joinDAO(uint256 shareAmountToPurchase) public payable onlyAfterSummoning {
    uint256 voteMaxSharesPerWallet = eternalStorage.getUint(
      StorageLib.formatLocation('dao.voteMaxSharesPerWallet')
    );
    uint256 walletLambda = eternalStorage.getUint(
      StorageLib.formatAddress('dao.shares', msg.sender)
    );
    uint256 k = eternalStorage.getUint(StorageLib.formatLocation('dao.baseTokenRatio'));
    uint256 lambda = eternalStorage.getUint(StorageLib.formatLocation('dao.totalShares'));

    require(
      SafeMath.add(shareAmountToPurchase, walletLambda) <= voteMaxSharesPerWallet,
      'ElasticDAO: Cannot purchase that many shares'
    );

    uint256 elasticity = eternalStorage.getUint(
      StorageLib.formatLocation('dao.priceToTokenInflationRate')
    );
    uint256 m = eternalStorage.getUint(StorageLib.formatLocation('dao.shareModifier'));
    uint256 capitalDelta = eternalStorage.getUint(StorageLib.formatLocation('dao.tokenPrice'));
    uint256 deltaE = ElasticMathLib.deltaE(
      shareAmountToPurchase,
      capitalDelta,
      k,
      elasticity,
      lambda,
      m
    );

    require(deltaE == msg.value, 'ElasticDAO: Incorrect ETH amount');

    eternalStorage.setUint(
      StorageLib.formatLocation('dao.totalShares'),
      SafeMath.add(lambda, shareAmountToPurchase)
    );
    eternalStorage.setUint(
      StorageLib.formatAddress('dao.shares', msg.sender),
      SafeMath.add(walletLambda, shareAmountToPurchase)
    );
  }

  function seedSummoning() public payable onlyBeforeSummoning onlySummoners {
    uint256 initialTokenPrice = eternalStorage.getUint(
      StorageLib.formatLocation('dao.initialTokenPrice')
    );
    uint256 k = eternalStorage.getUint(StorageLib.formatLocation('dao.baseTokenRatio'));
    uint256 walletLambda = eternalStorage.getUint(
      StorageLib.formatAddress('dao.shares', msg.sender)
    );
    uint256 deltaE = msg.value;
    uint256 deltaLambda = SafeMath.div(SafeMath.div(deltaE, initialTokenPrice), k);
    uint256 lambdaDash = SafeMath.add(walletLambda, deltaLambda);

    eternalStorage.setUint(StorageLib.formatAddress('dao.shares', msg.sender), lambdaDash);
  }

  function summon() public onlyBeforeSummoning onlySummoners {
    uint256 vaultBalance = address(this).balance;

    require(vaultBalance > 0, 'ElasticDAO: Please seed DAO with ETH to set ETH:EGT ratio');

    uint256 totalShares = eternalStorage.getUint(StorageLib.formatLocation('dao.totalShares'));
    uint256 baseTokenRatio = eternalStorage.getUint(
      StorageLib.formatLocation('dao.baseTokenRatio')
    );
    uint256 totalSupply = SafeMath.mul(totalShares, baseTokenRatio);
    uint256 tokenPrice = SafeMath.div(vaultBalance, totalSupply);

    eternalStorage.setUint(StorageLib.formatLocation('dao.shareModifier'), 1);
    eternalStorage.setUint(StorageLib.formatLocation('dao.tokenPrice'), tokenPrice);

    ElasticGovernanceToken token = new ElasticGovernanceToken(address(eternalStorage));

    eternalStorage.setBool(StorageLib.formatLocation('dao.summoned'), true);
    eternalStorage.setAddress(StorageLib.formatLocation('dao.governance.token'), address(token));
  }

  function storeStringData(string[3] memory _stringData) internal returns (bool) {
    string memory name = _stringData[0];
    string memory tokenName = _stringData[1];
    string memory tokenSymbol = _stringData[2];

    eternalStorage.setString(StorageLib.formatLocation('dao.name'), name);
    eternalStorage.setString(StorageLib.formatLocation('dao.token.name'), tokenName);
    eternalStorage.setString(StorageLib.formatLocation('dao.token.symbol'), tokenSymbol);

    return true;
  }

  function storeBoolData(bool[4] memory _boolData) internal returns (bool) {
    bool votePenaltyEnabledContracts = _boolData[0];
    bool votePenaltyEnabledFinance = _boolData[1];
    bool votePenaltyEnabledInforamtion = _boolData[2];
    bool votePenaltyEnabledPermission = _boolData[3];

    eternalStorage.setBool(
      StorageLib.formatLocation('dao.vote.penalty.enabledContracts'),
      votePenaltyEnabledContracts
    );
    eternalStorage.setBool(
      StorageLib.formatLocation('dao.vote.penalty.enabledFinance'),
      votePenaltyEnabledFinance
    );
    eternalStorage.setBool(
      StorageLib.formatLocation('dao.vote.penalty.enabledInformation'),
      votePenaltyEnabledInforamtion
    );
    eternalStorage.setBool(
      StorageLib.formatLocation('dao.vote.penalty.enabledPermission'),
      votePenaltyEnabledPermission
    );

    return true;
  }

  function storeUintDAOData(uint256[15] memory _uintData, address[] memory _summoners)
    internal
    returns (bool)
  {
    uint256 baseTokenRatio = _uintData[0];
    uint256 initialTokenPrice = _uintData[1];
    uint256 priceToTokenInflationRate = _uintData[2];
    uint256 summoningShare = _uintData[3];

    eternalStorage.setUint(StorageLib.formatLocation('dao.baseTokenRatio'), baseTokenRatio);
    eternalStorage.setUint(StorageLib.formatLocation('dao.initialTokenPrice'), initialTokenPrice);

    eternalStorage.setUint(
      StorageLib.formatLocation('dao.priceToTokenInflationRate'),
      priceToTokenInflationRate
    );

    for (uint256 i = 0; i < _summoners.length; i++) {
      eternalStorage.setBool(StorageLib.formatAddress('dao.summoner', _summoners[i]), true);
      eternalStorage.setUint(StorageLib.formatAddress('dao.shares', _summoners[i]), summoningShare);
    }

    uint256 lambda = SafeMath.mul(summoningShare, _summoners.length);
    eternalStorage.setUint(StorageLib.formatLocation('dao.totalShares'), lambda);

    return true;
  }

  function storeUintVoteData(uint256[15] memory _uintData) internal returns (bool) {
    uint256 voteApproval = _uintData[4];
    uint256 voteMaxSharesPerWallet = _uintData[5];
    uint256 voteMinBlocksContract = _uintData[6];
    uint256 voteMinBlocksFinance = _uintData[7];
    uint256 voteMinBlocksInformation = _uintData[8];
    uint256 voteMinBlocksPenalty = _uintData[9];
    uint256 voteMinBlocksPermission = _uintData[10];
    uint256 voteMinSharesToCreate = _uintData[11];
    uint256 votePenalty = _uintData[12];
    uint256 voteQuorum = _uintData[13];
    uint256 voteReward = _uintData[14];

    // Initialize Vote
    eternalStorage.setUint(
      StorageLib.formatLocation('dao.voteMaxSharesPerWallet'),
      voteMaxSharesPerWallet
    );
    eternalStorage.setUint(StorageLib.formatLocation('dao.voteReward'), voteReward);
    eternalStorage.setUint(StorageLib.formatLocation('dao.vote.approval'), voteApproval);
    eternalStorage.setUint(
      StorageLib.formatLocation('dao.vote.maxSharesPerWallet'),
      voteMaxSharesPerWallet
    );
    eternalStorage.setUint(
      StorageLib.formatLocation('dao.vote.minBlocksContract'),
      voteMinBlocksContract
    );
    eternalStorage.setUint(
      StorageLib.formatLocation('dao.vote.minBlocksFinance'),
      voteMinBlocksFinance
    );
    eternalStorage.setUint(
      StorageLib.formatLocation('dao.vote.minBlocksInformation'),
      voteMinBlocksInformation
    );
    eternalStorage.setUint(
      StorageLib.formatLocation('dao.vote.minBlocksPenalty'),
      voteMinBlocksPenalty
    );
    eternalStorage.setUint(
      StorageLib.formatLocation('dao.vote.minBlocksPermission'),
      voteMinBlocksPermission
    );
    eternalStorage.setUint(
      StorageLib.formatLocation('dao.vote.minSharesToCreate'),
      voteMinSharesToCreate
    );
    eternalStorage.setUint(StorageLib.formatLocation('dao.vote.penalty'), votePenalty);
    eternalStorage.setUint(StorageLib.formatLocation('dao.vote.quorum'), voteQuorum);
    eternalStorage.setUint(StorageLib.formatLocation('dao.vote.reward'), voteReward);

    return true;
  }
}
