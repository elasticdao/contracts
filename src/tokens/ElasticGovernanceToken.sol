// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../interfaces/IElasticToken.sol';

import '../libraries/SafeMath.sol';
import '../libraries/ElasticMath.sol';

import '../models/Balance.sol';
import '../models/DAO.sol';
import '../models/Ecosystem.sol';
import '../models/Token.sol';
import '../models/TokenHolder.sol';

/**
 * @dev Implementation of the IERC20 interface
 */
contract ElasticGovernanceToken is IElasticToken {
  address daoAddress;
  address ecosystemModelAddress;

  mapping(address => mapping(address => uint256)) private _allowances;

  modifier onlyDAO() {
    require(msg.sender == daoAddress, 'ElasticDAO: Not authorized.');
    _;
  }

  constructor(address _daoAddress, address _ecosystemModelAddress) IERC20() {
    daoAddress = _daoAddress;
    ecosystemModelAddress = _ecosystemModelAddress;
  }

  /**
   * @dev Returns the remaining number of tokens that @param _spender will be
   * allowed to spend on behalf of @param _owner through {transferFrom}. This is
   * zero by default
   * @param _spender - the address of the spender
   * @param _owner - the address of the owner
   * This value changes when {approve} or {transferFrom} are called
   * @return uint256
   */
  function allowance(address _owner, address _spender) external override view returns (uint256) {
    return _allowances[_owner][_spender];
  }

  /**
   * @dev Sets @param _amount as the allowance of @param _spender over the caller's tokens
   * @param _spender - the address of the spender
   * Returns a boolean value indicating whether the operation succeeded
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event
   * @return bool
   */
  function approve(address _spender, uint256 _amount) external override returns (bool) {
    _approve(msg.sender, _spender, _amount);
    return true;
  }

  /**
   * @dev Returns the amount of tokens owned by @param _account.
   * @param _account - address of the account
   * @return uint256
   */
  function balanceOf(address _account) external override view returns (uint256) {
    Token.Instance memory token = _getToken();
    TokenHolder.Instance memory tokenHolder = _getTokenHolder(_account);

    uint256 t = ElasticMath.t(tokenHolder.lambda, token.k, token.m);

    return t;
  }

  /**
   * @dev Returns the amount of shares owned by @param _account.
   * @param _account - address of the account
   * @return lambda uint256 - lambda is the number of shares
   */
  function balanceOfInShares(address _account) external override view returns (uint256 lambda) {
    TokenHolder.Instance memory tokenHolder = _getTokenHolder(_account);
    return tokenHolder.lambda;
  }

  /**
   * @dev Returns the amount of tokens owned by @param _account at the specific @param _blockNumber
   * @param _account - address of the account
   * @param _blockNumber - the blockNumber at which the balance is to be checked at
   * @return t uint256 - the number of tokens
   */
  function balanceOfAt(address _account, uint256 _blockNumber)
    external
    override
    view
    returns (uint256 t)
  {
    t = 0;

    Balance.Instance memory balance = _balanceAt(_account, _blockNumber);

    if (balance.blockNumber <= _blockNumber) {
      t = ElasticMath.t(balance.lambda, balance.m, balance.k);
    }

    return t;
  }

  /**
   * @dev Returns the amount of shares owned by @param _account at @param _blockNumber.
   * @param _account - address of the account
   * @param _blockNumber - the blockNumber at which the balance of shares has to be checked at
   * @return lambda uint256 - lambda is the number of shares
   */
  function balanceOfInSharesAt(address _account, uint256 _blockNumber)
    external
    override
    view
    returns (uint256 lambda)
  {
    Balance.Instance memory balance = _balanceAt(_account, _blockNumber);

    if (balance.blockNumber > _blockNumber) {
      return 0;
    }

    return balance.lambda;
  }

  /**
   * @dev Reduces the balance(tokens) of @param _account by @param _amount
   * @param _account address of the account
   * @param _amount - the amount by which the number of tokens is to be reduced
   * @return bool
   */
  function burn(address _account, uint256 _amount) external override onlyDAO returns (bool) {
    _burn(_account, _amount);
    return true;
  }

  /**
   * @dev Reduces the balance(shares) of @param _account by @param _amount
   * @param _account - address of the account
   * @param _amount - the amount by which the number of shares has to be reduced
   * @return bool
   */
  function burnShares(address _account, uint256 _amount) external override returns (bool) {
    _burnShares(_account, _amount);
    return true;
  }

  /**
   * @dev returns the number of decimals
   * @return 18
   */
  function decimals() external pure returns (uint256) {
    return 18;
  }

  /**
   * @dev decreases the allowance of @param _spender by @param _subtractedValue
   * @param _spender - address of the spender
   * @param _subtractedValue - the value the allowance has to be decreased by
   * @return bool
   */
  function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool) {
    uint256 newAllowance = SafeMath.sub(_allowances[msg.sender][_spender], _subtractedValue);

    require(newAllowance > 0, 'ElasticDAO: Allowance decrease less than 0');

    _approve(msg.sender, _spender, newAllowance);
    return true;
  }

  /**
   * @dev increases the allowance of @param _spender by @param _addedValue
   * @param _spender - address of the spender
   * @param _addedValue - the value the allowance has to be increased by
   * @return bool
   */
  function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool) {
    _approve(msg.sender, _spender, SafeMath.add(_allowances[msg.sender][_spender], _addedValue));
    return true;
  }

  /**
   * @dev mints @param _amount tokens for @param _account
   * @param _amount - the amount of tokens to be minted
   * @param _account - the address of the account for whom the token have to be minted to
   * @return bool
   */
  function mint(address _account, uint256 _amount) external onlyDAO returns (bool) {
    _mint(_account, _amount);

    return true;
  }

  /**
   * @dev mints @param _amount of shares for @param _account
   * @param _account address of the account
   * @param _amount - the amount of shares to be minted
   * @return bool
   */
  function mintShares(address _account, uint256 _amount) external override returns (bool) {
    _mintShares(_account, _amount);
    return true;
  }

  /**
   * @dev Returns the name of the token.
   * @return string - name of the token
   */
  function name() external view returns (string memory) {
    return _getToken().name;
  }

  function numberOfTokenHolders() external view returns (uint256) {
    return _getToken().numberOfTokenHolders;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   * @return string - the symbol of the token
   */
  function symbol() external view returns (string memory) {
    return _getToken().symbol;
  }

  /**
   * @dev returns the totalSupply of tokens in thee DAO
   * t - the total number of tokens in the DAO
   * lambda - the total number of shares outstanding in the DAO currently
   * m - current value of the share modifier
   * k - constant
   * t = ( lambda * m * k )
   * @return uint256 - the value of t
   */
  function totalSupply() external override view returns (uint256) {
    Token.Instance memory token = _getToken();
    return SafeMath.mul(token.lambda, SafeMath.mul(token.k, token.m));
  }

  function totalSupplyInShares() external override view returns (uint256) {
    Token.Instance memory token = _getToken();
    return token.lambda;
  }

  /**
   * @dev Moves @param _amount tokens from the caller's account to @param _to address
   *
   * Returns a boolean value indicating whether the operation succeeded
   *
   * Emits a {Transfer} event
   * @return bool
   */
  function transfer(address _to, uint256 _amount) external override returns (bool) {
    _transfer(msg.sender, _to, _amount);
    return true;
  }

  /**
   * @dev Moves @param _amount tokens from @param _from to @param _to using the
   * allowance mechanism. @param _amount is then deducted from the caller's
   * allowance
   *
   * Returns a boolean value indicating whether the operation succeeded
   *
   * Emits a {Transfer} event
   * @return bool
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  ) external override returns (bool) {
    require(msg.sender == _from || _amount <= _allowances[_from][msg.sender], 'ERC20: Bad Caller');

    _transfer(_from, _to, _amount);

    if (msg.sender != _from && _allowances[_from][msg.sender] != uint256(-1)) {
      _allowances[_from][msg.sender] = SafeMath.sub(_allowances[_from][msg.sender], _amount);

      emit Approval(msg.sender, _to, _allowances[_from][msg.sender]);
    }

    return true;
  }

  // Private

  function _approve(
    address _owner,
    address _spender,
    uint256 _amount
  ) internal {
    require(_owner != address(0), 'ERC20: approve from the zero address');
    require(_spender != address(0), 'ERC20: approve to the zero address');

    _allowances[_owner][_spender] = _amount;

    emit Approval(_owner, _spender, _amount);
  }

  function _balanceAt(address _account, uint256 _blockNumber)
    internal
    view
    returns (Balance.Instance memory)
  {
    Token.Instance memory token = _getToken();
    TokenHolder.Instance memory tokenHolder = _getTokenHolder(_account);
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    Balance balanceStorage = Balance(ecosystem.balanceModelAddress);
    return balanceStorage.deserialize(_blockNumber, ecosystem, token, tokenHolder);
  }

  function _burn(address _account, uint256 _deltaT) internal {
    Token.Instance memory token = _getToken();
    uint256 deltaLambda = SafeMath.div(_deltaT, SafeMath.mul(token.k, token.m));
    _burnShares(_account, deltaLambda);
  }

  function _burnShares(address _account, uint256 _deltaLambda) internal {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    Token tokenStorage = Token(ecosystem.tokenModelAddress);
    Token.Instance memory token = tokenStorage.deserialize(address(this), ecosystem);
    TokenHolder.Instance memory tokenHolder = _getTokenHolder(_account);
    bool alreadyTokenHolder = tokenHolder.lambda > 0;

    tokenHolder = _updateBalance(token, tokenHolder, false, _deltaLambda);

    token.lambda = SafeMath.sub(token.lambda, _deltaLambda);
    tokenStorage.serialize(token);

    TokenHolder tokenHolderStorage = TokenHolder(ecosystem.tokenHolderModelAddress);
    tokenHolderStorage.serialize(tokenHolder);
    _updateNumberOfTokenHolders(alreadyTokenHolder, token, tokenHolder, tokenStorage);
  }

  function _mint(address _account, uint256 _deltaT) internal {
    Token.Instance memory token = _getToken();
    uint256 deltaLambda = SafeMath.div(_deltaT, SafeMath.mul(token.k, token.m));
    _mintShares(_account, deltaLambda);
  }

  function _mintShares(address _account, uint256 _deltaLambda) internal {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    Token tokenStorage = Token(ecosystem.tokenModelAddress);
    Token.Instance memory token = tokenStorage.deserialize(address(this), ecosystem);
    TokenHolder.Instance memory tokenHolder = _getTokenHolder(_account);
    bool alreadyTokenHolder = tokenHolder.lambda > 0;

    uint256 deltaT = ElasticMath.t(_deltaLambda, token.k, token.m);

    tokenHolder = _updateBalance(token, tokenHolder, true, _deltaLambda);

    token.lambda = SafeMath.add(token.lambda, _deltaLambda);
    tokenStorage.serialize(token);

    TokenHolder tokenHolderStorage = TokenHolder(ecosystem.tokenHolderModelAddress);
    tokenHolderStorage.serialize(tokenHolder);
    _updateNumberOfTokenHolders(alreadyTokenHolder, token, tokenHolder, tokenStorage);

    emit Transfer(address(0), _account, deltaT);
  }

  function _transfer(
    address _from,
    address _to,
    uint256 _deltaT
  ) internal {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    Token tokenStorage = Token(ecosystem.tokenModelAddress);
    Token.Instance memory token = tokenStorage.deserialize(address(this), ecosystem);

    TokenHolder.Instance memory fromTokenHolder = _getTokenHolder(_from);
    TokenHolder.Instance memory toTokenHolder = _getTokenHolder(_to);
    bool fromAlreadyTokenHolder = fromTokenHolder.lambda > 0;
    bool toAlreadyTokenHolder = toTokenHolder.lambda > 0;

    uint256 deltaLambda = SafeMath.div(_deltaT, SafeMath.mul(token.k, token.m));
    uint256 deltaT = ElasticMath.t(deltaLambda, token.k, token.m);

    fromTokenHolder = _updateBalance(token, fromTokenHolder, false, deltaLambda);
    toTokenHolder = _updateBalance(token, toTokenHolder, true, deltaLambda);

    TokenHolder tokenHolderStorage = TokenHolder(ecosystem.tokenHolderModelAddress);
    tokenHolderStorage.serialize(fromTokenHolder);
    tokenHolderStorage.serialize(toTokenHolder);
    _updateNumberOfTokenHolders(fromAlreadyTokenHolder, token, fromTokenHolder, tokenStorage);
    _updateNumberOfTokenHolders(toAlreadyTokenHolder, token, toTokenHolder, tokenStorage);

    emit Transfer(_from, _to, deltaT);
  }

  function _updateBalance(
    Token.Instance memory _token,
    TokenHolder.Instance memory _tokenHolder,
    bool _isIncreasing,
    uint256 _deltaLambda
  ) internal returns (TokenHolder.Instance memory) {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    Balance.Instance memory balance;
    balance.blockNumber = block.number;
    balance.ecosystem = ecosystem;
    balance.index = _tokenHolder.counter;
    balance.k = _token.k;
    balance.m = _token.m;
    balance.token = _token;
    balance.tokenHolder = _tokenHolder;
    _tokenHolder.counter = SafeMath.add(_tokenHolder.counter, 1);

    if (_isIncreasing) {
      _tokenHolder.lambda = SafeMath.add(_tokenHolder.lambda, _deltaLambda);
    } else {
      _tokenHolder.lambda = SafeMath.sub(_tokenHolder.lambda, _deltaLambda);
    }

    balance.lambda = _tokenHolder.lambda;

    Balance(ecosystem.balanceModelAddress).serialize(balance);

    return _tokenHolder;
  }

  function _updateNumberOfTokenHolders(
    bool alreadyTokenHolder,
    Token.Instance memory token,
    TokenHolder.Instance memory tokenHolder,
    Token tokenStorage
  ) internal {
    if (tokenHolder.lambda > 0 && alreadyTokenHolder == false) {
      tokenStorage.updateNumberOfTokenHolders(token, SafeMath.add(token.numberOfTokenHolders, 1));
    }

    if (tokenHolder.lambda == 0 && alreadyTokenHolder) {
      tokenStorage.updateNumberOfTokenHolders(token, SafeMath.sub(token.numberOfTokenHolders, 1));
    }
  }

  // Private Getters

  function _getEcosystem() internal view returns (Ecosystem.Instance memory) {
    return Ecosystem(ecosystemModelAddress).deserialize(daoAddress);
  }

  function _getTokenHolder(address _account) internal view returns (TokenHolder.Instance memory) {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    return
      TokenHolder(ecosystem.tokenHolderModelAddress).deserialize(
        _account,
        ecosystem,
        Token(ecosystem.tokenModelAddress).deserialize(address(this), ecosystem)
      );
  }

  function _getToken() internal view returns (Token.Instance memory) {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    return Token(ecosystem.tokenModelAddress).deserialize(address(this), ecosystem);
  }
}
