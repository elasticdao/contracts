pragma solidity 0.7.0;

import "../EternalStorage.sol";
import "./StorageLib.sol";
import "./StringLib.sol";
import "./SafeMath.sol";

library ShareLib {
  function updateShareBalance(
    address _memberAddress,
    bool _balanceDirection,
    uint256 _amount,
    EternalStorage _eternalStorage
  ) external {
    uint256 memberShares = _eternalStorage.getUint(
      StorageLib.formatAddress("dao.shares", _memberAddress)
    );

    if (_balanceDirection == false) {
      _eternalStorage.setUint(
        StorageLib.formatAddress("dao.shares", _memberAddress),
        SafeMath.sub(memberShares, _amount)
      );
    } else {
      _eternalStorage.setUint(
        StorageLib.formatAddress("dao.shares", _memberAddress),
        SafeMath.add(memberShares, _amount)
      );
    }

    uint256 shareTransactionCounter = _eternalStorage.getUint(
      StorageLib.formatAddress("dao.shares.counter", _memberAddress)
    );
    string memory counter = StringLib.toStringUint(shareTransactionCounter);
    string memory blockNumberLocation = StringLib.concat("dao.shares.blockNumber.", counter);
    string memory directionLocation = StringLib.concat("dao.shares.direction.", counter);
    string memory shiftLocation = StringLib.concat("dao.shares.shift.", counter);

    _eternalStorage.setUint(
      StorageLib.formatAddress(blockNumberLocation, _memberAddress),
      block.number
    );
    _eternalStorage.setBool(
      StorageLib.formatAddress(directionLocation, _memberAddress),
      _balanceDirection
    );
    _eternalStorage.setUint(StorageLib.formatAddress(shiftLocation, _memberAddress), _amount);
    _eternalStorage.setUint(
      StorageLib.formatAddress("dao.shares.counter", _memberAddress),
      SafeMath.add(shareTransactionCounter, 1)
    );

    // add total share update to storage
  }

  function balanceAtBlock(
    address _memberAddress,
    uint256 _blockNumber,
    EternalStorage _eternalStorage
  ) external returns (uint256 balance) {
    uint256 i = 0;
    balance = 0;

    uint256 shareBlockNumber = _eternalStorage.getUint(
      StorageLib.formatAddress("dao.shares.blockNumber.0", _memberAddress)
    );

    while (shareBlockNumber < _blockNumber && shareBlockNumber != 0) {
      string memory directionLocation = StringLib.concat(
        "dao.shares.direction.",
        StringLib.toStringUint(i)
      );
      string memory shiftLocation = StringLib.concat(
        "dao.shares.shift.",
        StringLib.toStringUint(i)
      );

      bool balanceDirection = _eternalStorage.getBool(
        StorageLib.formatAddress(directionLocation, _memberAddress)
      );
      uint256 amount = _eternalStorage.getUint(
        StorageLib.formatAddress(shiftLocation, _memberAddress)
      );

      if (balanceDirection == false) {
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
}
