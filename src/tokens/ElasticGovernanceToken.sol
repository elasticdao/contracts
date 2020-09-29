// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import '../interfaces/IERC20.sol';

import '../libraries/SafeMath.sol';

import '../models/DAO.sol';
import '../models/Ecosystem.sol';
import '../models/Token.sol';
import '../models/TokenHolder.sol';

contract ElasticGovernanceToken is IERC20 {
  address daoAddress;
  address ecosystemModelAddress;

  mapping(address => mapping(address => uint256)) private _allowances;

  constructor(address _daoAddress, address _ecosystemModelAddress) IERC20() {
    daoAddress = _daoAddress;
    ecosystemModelAddress = _ecosystemModelAddress;
  }

  function allowance(address _owner, address _spender)
    public
    virtual
    override
    view
    returns (uint256)
  {
    return _allowances[_owner][_spender];
  }

  function approve(address _spender, uint256 _amount) public virtual override returns (bool) {
    _approve(msg.sender, _spender, _amount);
    return true;
  }

  function _approve(
    address _owner,
    address _spender,
    uint256 _amount
  ) internal virtual {
    require(_owner != address(0), 'ERC20: approve from the zero address');
    require(_spender != address(0), 'ERC20: approve to the zero address');

    _allowances[_owner][_spender] = _amount;

    emit Approval(_owner, _spender, _amount);
  }

  function balanceOf(address _account) external override view returns (uint256) {
    Token.Instance memory token = _getToken();
    TokenHolder.Instance memory tokenHolder = _getTokenHolder(_account);

    return SafeMath.mul(tokenHolder.lambda, SafeMath.mul(token.k, token.m));
  }

  function balanceOfAt(address _account, uint256 _blockNumber) external view returns (uint256 t) {
    uint256 i = 0;
    uint256 lambda = 0;
    t = 0;

    TokenHolder.Instance memory tokenHolder = _getTokenHolder(_account);

    while (
      i <= tokenHolder.counter &&
      tokenHolder.balanceChanges[i].blockNumber != 0 &&
      tokenHolder.balanceChanges[i].blockNumber < _blockNumber
    ) {
      if (tokenHolder.balanceChanges[i].isIncreasing) {
        lambda = SafeMath.add(lambda, tokenHolder.balanceChanges[i].deltaLambda);
        t = _t(lambda, tokenHolder.balanceChanges[i].m, tokenHolder.balanceChanges[i].k);
      } else {
        lambda = SafeMath.sub(lambda, tokenHolder.balanceChanges[i].deltaLambda);
        t = _t(lambda, tokenHolder.balanceChanges[i].m, tokenHolder.balanceChanges[i].k);
      }

      i = SafeMath.add(i, 1);
    }

    return t;
  }

  function decimals() external pure returns (uint256) {
    return 18;
  }

  function decreaseAllowance(address _spender, uint256 _subtractedValue)
    public
    virtual
    returns (bool)
  {
    uint256 newAllowance = SafeMath.sub(_allowances[msg.sender][_spender], _subtractedValue);

    require(newAllowance > 0, 'ElasticDAO: Allowance decrease less than 0');

    _approve(msg.sender, _spender, newAllowance);
    return true;
  }

  function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
    _approve(msg.sender, _spender, SafeMath.add(_allowances[msg.sender][_spender], _addedValue));
    return true;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory) {
    return _getToken().name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() external view returns (string memory) {
    return _getToken().symbol;
  }

  function totalSupply() external override view returns (uint256) {
    Token.Instance memory token = _getToken();
    return SafeMath.mul(token.lambda, SafeMath.mul(token.k, token.m));
  }

  function transfer(address _to, uint256 _amount) external override returns (bool) {
    _transfer(msg.sender, _to, _amount);
    return true;
  }

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

  function _transfer(
    address _from,
    address _to,
    uint256 _deltaT
  ) internal {
    Token.Instance memory token = _getToken();

    TokenHolder.Instance memory fromTokenHolder = _getTokenHolder(_from);
    TokenHolder.Instance memory toTokenHolder = _getTokenHolder(_to);

    uint256 deltaLambda = SafeMath.div(_deltaT, SafeMath.div(token.k, token.m));
    uint256 deltaT = _t(deltaLambda, token.k, token.m);

    fromTokenHolder = _updateBalance(token, fromTokenHolder, false, deltaLambda);
    toTokenHolder = _updateBalance(token, toTokenHolder, true, deltaLambda);

    TokenHolder tokenHolderStorage = TokenHolder(_getEcosystem().tokenHolderModelAddress);
    tokenHolderStorage.serialize(fromTokenHolder);
    tokenHolderStorage.serialize(toTokenHolder);

    emit Transfer(_from, _to, deltaT);
  }

  function _getEcosystem() internal view returns (Ecosystem.Instance memory ecosystem) {
    ecosystem = Ecosystem(ecosystemModelAddress).deserialize(daoAddress);
  }

  function _getTokenHolder(address _uuid)
    internal
    view
    returns (TokenHolder.Instance memory tokenHolder)
  {
    tokenHolder = TokenHolder(_getEcosystem().tokenHolderModelAddress).deserialize(
      _uuid,
      address(this)
    );
  }

  function _getToken() internal view returns (Token.Instance memory token) {
    token = Token(_getEcosystem().tokenModelAddress).deserialize(address(this));
  }

  function _t(
    uint256 lambda,
    uint256 k,
    uint256 m
  ) internal pure returns (uint256 tokens) {
    return SafeMath.mul(SafeMath.mul(lambda, k), m);
  }

  function _updateBalance(
    Token.Instance memory _token,
    TokenHolder.Instance memory _tokenHolder,
    bool _isIncreasing,
    uint256 _deltaLambda
  ) internal view returns (TokenHolder.Instance memory) {
    TokenHolder.BalanceChange memory balanceChange;
    balanceChange.blockNumber = block.number;
    balanceChange.deltaLambda = _deltaLambda;
    balanceChange.id = _tokenHolder.counter;
    balanceChange.isIncreasing = _isIncreasing;
    balanceChange.k = _token.k;
    balanceChange.m = _token.m;
    _tokenHolder.balanceChanges[_tokenHolder.counter] = balanceChange;
    _tokenHolder.counter = SafeMath.add(_tokenHolder.counter, 1);
    if (_isIncreasing) {
      _tokenHolder.lambda = SafeMath.add(_tokenHolder.lambda, _deltaLambda);
    } else {
      _tokenHolder.lambda = SafeMath.sub(_tokenHolder.lambda, _deltaLambda);
    }
    return _tokenHolder;
  }
}
