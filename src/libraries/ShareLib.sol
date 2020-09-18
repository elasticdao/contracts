pragma solidity 0.7.0;

import "../EternalStorage.sol";
import "./StorageLib.sol";
import "./StringLib.sol";
import "./SafeMath.sol";

library ShareLib {
  function balanceAtBlock(
    address _memberAddress,
    uint256 _blockNumber,
    EternalStorage _eternalStorage
  ) external view returns (uint256 balance) {
    uint256 i = 0;
    balance = 0;

    uint256 shareBlockNumber = _eternalStorage.getUint(
      StorageLib.formatAddress("dao.shares.blockNumber.0", _memberAddress)
    );

    while (shareBlockNumber < _blockNumber && shareBlockNumber != 0) {
      string memory isIncreasingLocation = StringLib.concat(
        "dao.shares.isIncreasing.",
        StringLib.toStringUint(i)
      );
      string memory amountLocation = StringLib.concat(
        "dao.shares.amount.",
        StringLib.toStringUint(i)
      );

      bool isIncreasing = _eternalStorage.getBool(
        StorageLib.formatAddress(isIncreasingLocation, _memberAddress)
      );
      uint256 amount = _eternalStorage.getUint(
        StorageLib.formatAddress(amountLocation, _memberAddress)
      );

      if (isIncreasing == false) {
        balance = SafeMath.sub(balance, amount);
      } else {
        balance = SafeMath.add(balance, amount);
      }

      i = SafeMath.add(i, 1);

      string memory shareBlockNumberLocation = StringLib.concat(
        "dao.shares.blockNumber.",
        StringLib.toStringUint(i)
      );

      shareBlockNumber = _eternalStorage.getUint(
        StorageLib.formatAddress(shareBlockNumberLocation, _memberAddress)
      );
    }

    return balance;
  }

  function updateBalance(
    address _memberAddress,
    bool _isIncreasing,
    uint256 _amount,
    EternalStorage _eternalStorage
  ) external {
    uint256 lambda = _eternalStorage.getUint(StorageLib.formatLocation("dao.totalShares"));
    uint256 walletLambda = _eternalStorage.getUint(
      StorageLib.formatAddress("dao.shares", _memberAddress)
    );

    if (_isIncreasing == false) {
      _eternalStorage.setUint(
        StorageLib.formatAddress("dao.shares", _memberAddress),
        SafeMath.sub(walletLambda, _amount)
      );
      _eternalStorage.setUint(
        StorageLib.formatLocation("dao.totalShares"),
        SafeMath.sub(lambda, _amount)
      );
    } else {
      _eternalStorage.setUint(
        StorageLib.formatAddress("dao.shares", _memberAddress),
        SafeMath.add(walletLambda, _amount)
      );
      _eternalStorage.setUint(
        StorageLib.formatLocation("dao.totalShares"),
        SafeMath.add(lambda, _amount)
      );
    }

    uint256 shareTransactionCounter = _eternalStorage.getUint(
      StorageLib.formatAddress("dao.shares.counter", _memberAddress)
    );
    string memory counter = StringLib.toStringUint(shareTransactionCounter);
    string memory blockNumberLocation = StringLib.concat("dao.shares.blockNumber.", counter);
    string memory isIncreasingLocation = StringLib.concat("dao.shares.isIncreasing.", counter);
    string memory amountLocation = StringLib.concat("dao.shares.amountLocation.", counter);

    _eternalStorage.setUint(
      StorageLib.formatAddress(blockNumberLocation, _memberAddress),
      block.number
    );
    _eternalStorage.setBool(
      StorageLib.formatAddress(isIncreasingLocation, _memberAddress),
      _isIncreasing
    );
    _eternalStorage.setUint(StorageLib.formatAddress(amountLocation, _memberAddress), _amount);
    _eternalStorage.setUint(
      StorageLib.formatAddress("dao.shares.counter", _memberAddress),
      SafeMath.add(shareTransactionCounter, 1)
    );
  }
}
