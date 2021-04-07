// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../interfaces/IElasticDAO.sol';

import '../libraries/ElasticMath.sol';

import '../models/DAO.sol';
import '../models/Ecosystem.sol';
import '../models/Token.sol';

import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@pie-dao/proxy/contracts/PProxy.sol';

contract ElasticMintingPool is ReentrancyGuard {
  address public controller;
  address public ecosystemModelAddress;
  uint256 public mintReward;
  uint256 public round = 0;
  bool public initialized = false;

  struct Round {
    uint256 totalDeposited;
    mapping(address => uint256) deposits;
  }

  Round[] public rounds;
  mapping(uint256 => mapping(address => bool)) hasRoundDeposit;
  mapping(uint256 => address[]) usersInRound;

  event ControllerChanged(address indexed value);
  event Deposit(address indexed from, uint256 amount);
  event PoolMinted(address indexed token, uint256 amount);
  event MintRewardChanged(uint256 value);
  event Withdraw(address indexed from, uint256 amount);

  modifier onlyController() {
    require(msg.sender == controller, 'ElasticDAO: Only controller');
    _;
  }

  function initialize(
    address _controller,
    address _ecosystemModelAddress,
    uint256 _mintReward
  ) external nonReentrant {
    require(!initialized, 'ElasticDAO: Already initialized');
    require(_controller != address(0), 'ElasticDAO: Address can not be Zero');

    controller = _controller;
    ecosystemModelAddress = _ecosystemModelAddress;
    mintReward = _mintReward;
    initialized = true;
  }

  function deposit() external payable nonReentrant {
    // check msg.value is not zero
    require(msg.value > 100000000000000000, 'ElasticDAO: 0.1 ETH minimum');

    Token.Instance memory token = _getToken();
    DAO.Instance memory dao = _getDAO();
    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(token.uuid);

    uint256 capitalDelta =
      ElasticMath.capitalDelta(address(dao.uuid).balance, tokenContract.totalSupply());
    uint256 deltaE =
      ElasticMath.deltaE(
        token.maxLambdaPurchase,
        capitalDelta,
        token.k,
        token.elasticity,
        token.lambda,
        token.m
      );

    require(
      address(this).balance < deltaE,
      'ElasticDAO: Pool is full wait for next round or call mintVotingPower'
    );

    uint256 currentPoolBalance = address(this).balance;
    uint256 newPoolBalance = SafeMath.add(currentPoolBalance, msg.value);
    uint256 overageAmount = SafeMath.sub(newPoolBalance, deltaE);
    uint256 depositAmount = SafeMath.sub(msg.value, overageAmount);

    // add users deposit to minting round data
    rounds[round].deposits[msg.sender] += depositAmount;
    rounds[round].totalDeposited += depositAmount;
    _addUserToRound();

    // return overage
    if (overageAmount > 0) {
      // send back any ETH the last depositer sends that is more than required to call join
      (bool success, ) = msg.sender.call{ value: overageAmount }('');
      require(success, 'ElasticDAO: Return overage failed during deposit');
    }

    emit Deposit(msg.sender, SafeMath.sub(msg.value, overageAmount));
  }

  function mint() external nonReentrant {
    // require that current pool value === deltaE required to mint current max votable tokens
    Token.Instance memory token = _getToken();
    DAO.Instance memory dao = _getDAO();
    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(token.uuid);

    uint256 capitalDelta =
      ElasticMath.capitalDelta(address(dao.uuid).balance, tokenContract.totalSupply());
    uint256 deltaE =
      ElasticMath.deltaE(
        token.maxLambdaPurchase,
        capitalDelta,
        token.k,
        token.elasticity,
        token.lambda,
        token.m
      );

    require(address(this).balance == deltaE, 'ElasticDAO: Incorrect balance to mint');

    // mint new voting power
    address payable daoAddress = payable(dao.uuid);
    IElasticDAO(daoAddress).join{ value: address(this).balance }();
    uint256 elasticTokenBalance = tokenContract.balanceOf(address(this));

    // send msg.sender mintReward
    tokenContract.transfer(msg.sender, mintReward);

    // divide up remaining tokens based on each persons deposit amount and send their voting power
    for (uint256 i = 0; i < usersInRound[i].length; i += 1) {
      address user = usersInRound[round][i];

      uint256 depositAmount = rounds[round].deposits[user];

      if (depositAmount > 0) {
        uint256 percentageOfPool = SafeMath.div(depositAmount, deltaE);
        uint256 shareOfTokens = SafeMath.mul(elasticTokenBalance, percentageOfPool);
        tokenContract.transfer(user, shareOfTokens);
      }
    }

    // start new round
    round += 1;

    emit PoolMinted(token.uuid, ElasticMath.t(token.maxLambdaPurchase, token.k, token.m));
  }

  function withdraw(uint256 _amount) external payable nonReentrant {
    require(
      _amount <= rounds[round].deposits[msg.sender],
      'ElasticDAO: Withdrawal amount is greater than deposited amount'
    );

    // update round data
    rounds[round].deposits[msg.sender] -= _amount;
    rounds[round].totalDeposited -= _amount;

    if (rounds[round].deposits[msg.sender] == 0) {
      _removeUserFromRound();
    }

    (bool success, ) = msg.sender.call{ value: _amount }('');
    require(success, 'ElasticDAO: Transfer failed during withdraw');

    emit Withdraw(msg.sender, _amount);
  }

  /**
   * @notice sets the controller of the DAO,
   * The controller of the DAO handles various responsibilities of the DAO,
   * such as burning and minting tokens on behalf of the DAO
   *
   * @param _controller - the new address of the controller of the DAO
   *
   * @dev emits ControllerChanged event
   * @dev Requirements:
   * - The controller must not be the 0 address
   * - The controller of the DAO should successfully be set as the burner of the tokens of the DAO
   * - The controller of the DAO should successfully be set as the minter of the tokens of the DAO
   */
  function setController(address _controller) external onlyController nonReentrant {
    require(_controller != address(0), 'ElasticDAO: Address zero');

    controller = _controller;

    emit ControllerChanged(controller);
  }

  function setMintReward(uint256 _amount) external onlyController nonReentrant {
    mintReward = _amount;
  }

  function _addUserToRound() internal {
    // only push when its not already added
    if (!hasRoundDeposit[round][msg.sender]) {
      hasRoundDeposit[round][msg.sender] = true;
      usersInRound[round].push(msg.sender);
    }
  }

  function _getDAO() internal view returns (DAO.Instance memory) {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    return DAO(ecosystem.daoModelAddress).deserialize(address(this), ecosystem);
  }

  function _getEcosystem() internal view returns (Ecosystem.Instance memory) {
    return Ecosystem(ecosystemModelAddress).deserialize(address(this));
  }

  function _getToken() internal view returns (Token.Instance memory) {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    return
      Token(ecosystem.tokenModelAddress).deserialize(ecosystem.governanceTokenAddress, ecosystem);
  }

  function _removeUserFromRound() internal {
    if (hasRoundDeposit[round][msg.sender]) {
      hasRoundDeposit[round][msg.sender] = false;

      for (uint256 i = 0; i < usersInRound[round].length; i += 1) {
        if (usersInRound[round][i] == msg.sender) {
          usersInRound[round][i] = usersInRound[round][usersInRound[round].length - 1];
          usersInRound[round].pop();
        }
      }
    }
  }
}