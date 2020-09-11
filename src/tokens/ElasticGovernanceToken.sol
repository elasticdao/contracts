// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;

import "../EternalStorage.sol";

import "../libraries/StorageLib.sol";
import "../libraries/SafeMath.sol";

import "../interfaces/IERC20.sol";

contract ElasticGovernanceToken is IERC20 {
  EternalStorage internal eternalStorage;

  event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
  event Transfer(address indexed _from, address indexed _to, uint256 _amount);

  mapping(address => mapping(address => uint256)) private _allowances;

  constructor(address _eternalStorageAddress) public IERC20() {
    eternalStorage = EternalStorage(_eternalStorageAddress);

    eternalStorage.setAddress(StorageLib.formatLocation("dao.token.address"), address(this));
  }

  function name() external view returns (string memory) {
    return eternalStorage.getString(StorageLib.formatLocation("dao.token.name"));
  }

  function symbol() external view returns (string memory) {
    return eternalStorage.getString(StorageLib.formatLocation("dao.token.symbol"));
  }

  function decimals() external view returns (string memory) {
    return 18;
  }

  function totalSupply() external override view returns (uint256) {
    uint256 lambda = eternalStorage.getUint(StorageLib.formatLocation("dao.totalShares"));
    uint256 k = eternalStorage.getUint(StorageLib.formatLocation("dao.baseTokenRatio"));
    uint256 m = eternalStorage.getUint(StorageLib.formatLocation("dao.shareModifier"));

    return SafeMath.mul(lambda, SafeMath.mul(k, m));
  }

  function balanceOf(address _owner) external override view returns (uint256) {
    uint256 localLambda = eternalStorage.getUint(StorageLib.formatAddress("dao.shares", _owner));
    uint256 k = eternalStorage.getUint(StorageLib.formatLocation("dao.baseTokenRatio"));
    uint256 m = eternalStorage.getUint(StorageLib.formatLocation("dao.shareModifier"));

    return SafeMath.mul(localLambda, SafeMath.mul(k, m));
  }

  function allowance(address owner, address spender)
    public
    virtual
    override
    view
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
    );
    return true;
  }

  function transfer(address _to, uint256 _amount) external override view returns (bool) {
    _transfer(msg.sender, _to, _amount);

    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  ) external override returns (bool) {
    require(msg.sender == _from || _amount <= _allowances[_from][msg.sender], "ERC20: Bad Caller");

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
    uint256 _amount
  ) internal {
    uint256 fromLocalLambda = eternalStorage.getUint(StorageLib.formatAddress("dao.shares", _from));
    uint256 k = eternalStorage.getUint(StorageLib.formatLocation("dao.baseTokenRatio"));
    uint256 m = eternalStorage.getUint(StorageLib.formatLocation("dao.shareModifier"));
    uint256 localLambda = SafeMath.div(_amount, SafeMath.div(k, m));

    require(fromLocalLambda >= localLambda, "ElasticDAO: Insufficient Balance");

    uint256 toLocalLambda = eternalStorage.getUint(StorageLib.formatAddress("dao.shares", _to));
    eternalStorage.setUint(
      StorageLib.formatAddress("dao.shares", _to),
      SafeMath.add(toLocalLambda, localLamda)
    );
    eternalStorage.setUint(
      StorageLIb.formatAddress("dao.share", _from),
      SafeMath.sub(fromLocalLambda, localLambda)
    );

    emit Transfer(_from, _to, _amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;

    emit Approval(owner, spender, amount);
  }
}
