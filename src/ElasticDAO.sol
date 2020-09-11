pragma solidity 0.7.0;

// Contracts
import "./EternalStorage.sol";

// Libraries
import "./libraries/StorageLib.sol";
import "./libraries/StringLib.sol";
import "./libraries/SafeMath.sol";

contract ElasticDAO {
  EternalStorage internal eternalStorage;
  uint256 public SHARE_DECIMAL_PRECISION = 68;

  modifier onlyAfterSummoning() {
    require(
      eternalStorage.getBool(StorageLib.formatLocation("dao.summoned")) == true,
      "ElasticDAO: DAO must be summoned"
    );
    _;
  }

  modifier onlyBeforeSummoning() {
    require(
      eternalStorage.getBool(StorageLib.formatLocation("dao.summoned")) == false,
      "ElasticDAO: DAO must not be summoned"
    );
    _;
  }

  modifier onlySummoners() {
    bool isSummoner = eternalStorage.getBool(StorageLib.formatAddress("dao.summoner", msg.sender));

    require(isSummoner, "ElasticDAO: Only summoners");
    _;
  }

  constructor(
    string memory _name,
    string memory _tokenSymbol,
    address[] _summoners,
    uint256 _baseTokenRatio,
    uint256 _initialTokenPrice,
    uint256 _maxVotingSharesPerWallet,
    uint256 _priceToTokenInflationRate,
    uint256 _summoningShare,
    uint256 _voteReward
  ) public {
    eternalStorage = new EternalStorage();
    eternalStorage.setBool(StorageLib.formatLocation("dao.summoned"), false);
    eternalStorage.setString(StorageLib.formatLocation("dao.name"), _name);
    eternalStorage.setAddressArray(StorageLib.formatLocation("dao.summoners"), _summoners);
    eternalStorage.setUint(StorageLib.formatLocation("dao.baseTokenRatio"), _baseTokenRatio);
    eternalStorage.setUint(StorageLib.formatLocation("dao.initialTokenPrice"), _initialTokenPrice);
    eternalStorage.setUint(StorageLib.formatLocation("dao.totalShares"), 0);

    eternalStorage.setUint(
      StorageLib.formatLocation("dao.maxVotingSharesPerWallet"),
      _maxVotingSharesPerWallet
    );
    eternalStorage.setUint(
      StorageLib.formatLocation("dao.priceToTokenInflationRate"),
      _priceToTokenInflationRate
    );
    eternalStorage.setUint(StorageLib.formatLocation("dao.voteReward"), _voteReward);

    for (uint256 i = 0; i < _summoners.length; i++) {
      eternalStorage.setBool(StorageLib.formatAddress("dao.summoner", _summoners[i]), true);
      eternalStorage.setUint(
        StorageLib.formatAddress("dao.shares", _summoners[i]),
        _summoningShare
      );
    }

    uint256 totalShares = SafeMath.mul(_summoningShare, _summoners.length);
    eternalStorage.setUint(StorageLib.formatLocation("dao.totalShares"), totalShares);
  }

  function joinDAO(uint256 _shareAmountToPurchase) public payable onlyAfterSummoning {
    uint256 maxVotingSharesPerWallet = eternalStorage.getUint(
      StorageLib.formatLocation("dao.maxVotingSharesPerWallet")
    );
    uint256 existingShareAmount = eternalStorage.getUint(
      StorageLib.formatAddress("dao.shares", msg.sender)
    );
    uint256 baseTokenRatio = eternalStorage.getUint(
      StorageLib.formatLocation("dao.baseTokenRatio")
    );
    uint256 totalShares = eternalStorage.getUint(StorageLib.formatLocation("dao.totalShares"));

    require(
      SafeMath.add(_shareAmountToPurchase, existingShareAmount) <= maxVotingSharesPerWallet,
      "ElasticDAO: Cannot purchase that many shares"
    );

    uint256 priceToTokenInflationRate = eternalStorage.getUint(
      StorageLib.formatLocation("dao.priceToTokenInflationRate")
    );
    uint256 m = eternalStorage.getUint(StorageLib.formatLocation("dao.shareModifier"));
    uint256 revamp = SafeMath.add(priceToTokenInflationRate, SafeMath.pow(10, 18));
    uint256 capitalDelta = eternalStorage.getUint(StorageLib.formatLocation("dao.tokenPrice"));
    uint256 capitalDeltaDash = SafeMath.mul(tokenPrice, revamp);
    uint256 deltaLambda = _shareAmountToPurchase;
    uint256 k = baseTokenRatio;
    uint256 lambda = totalShares;
    uint256 lambdaDash = SafeMath.add(lambda, deltaLambda);
    uint256 mDash = SafeMath.div(lambdaDash, lambda);

    uint256 a = SafeMath.mul(lambdaDash, SafeMath.mul(mDash, revamp));
    uint256 b = SafeMath.mul(lambda, m);
    uint256 c = SafeMath.sub(a, b);
    uint256 deltaE = SafeMath.mul(SafeMath.mul(capitalDelta, k), c);

    require(deltaE == msg.value, "ElasticDAO: Incorrect ETH amount");

    eternalStorage.setUint(
      StorageLib.formatLocation("dao.totalShares"),
      SafeMath.add(totalShares, _shareAmountToPurchase)
    );
    eternalStorage.setUint(
      StorageLib.formatAddress("dao.shares", msg.sender),
      SafeMath.add(existingShareAmount, _shareAmountToPurchase)
    );
  }

  function seedSummoning() public payable onlyBeforeSummoning onlySummoners {
    uint256 initialTokenPrice = eternalStorage.getUint(
      StorageLib.formatLocation("dao.initialTokenPrice")
    );
    uint256 baseTokenRatio = eternalStorage.getUint(
      StorageLib.formatLocation("dao.baseTokenRatio")
    );
    uint256 existingShareAmount = eternalStorage.getUint(
      StorageLib.formatAddress("dao.shares", msg.sender)
    );
    uint256 ethValue = msg.value;
    uint256 newShareAmount = SafeMath.mul(
      SafeMath.div(SafeMath.div(ethValue, initialTokenPrice), baseTokenRatio),
      SafeMath.pow(10, 50)
    );
    uint256 totalShares = SafeMath.add(existingShareAmount, newShareAmount);

    eternalStorage.setUint(StorageLib.formatAddress("dao.shares", msg.sender), totalShares);
  }

  function summon() public onlyBeforeSummoning onlySummoners {
    address payable self = address(this);
    uint256 vaultBalance = self.balance;

    require(vaultBalance > 0, "ElasticDAO: Please seed DAO with ETH to set ETH:EGT ratio");

    uint256 totalShares = eternalStorage.getUint(StorageLib.formatLocation("dao.totalShares"));
    uint256 baseTokenRatio = eternalStorage.getUint(
      StorageLib.formatLocation("dao.baseTokenRatio")
    );
    uint256 totalSupply = SafeMath.mul(totalShares, baseTokenRatio);

    eternalStorage.setUint(StorageLib.formatLocation("dao.shareModifier"), 1);
    uint256 tokenPrice = SafeMath.div(vaultBalance, totalSupply);

    eternalStorage.setUint(StorageLib.formatLocation("dao.tokenPrice"), tokenPrice);
    eternalStorage.setBool(StorageLib.formatLocation("dao.summoned"), true);
  }
}
