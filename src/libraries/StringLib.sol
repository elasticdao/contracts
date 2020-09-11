// SPDX-License-Identifier: GPLv3

pragma solidity 0.7.0;

library StringHelper {
  function concat(string memory _a, string memory _b) external pure returns (string memory) {
    return string(abi.encodePacked(_a, _b));
  }

  /// @notice convert address to string
  function toString(address _account) external pure returns (string memory) {
    return string(abi.encodePacked(_account));
  }

  function toStringUint(uint256 _i) external pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;
    while (_i != 0) {
      bstr[k--] = bytes1(uint8(48 + (_i % 10)));
      _i /= 10;
    }
    return string(bstr);
  }
}
