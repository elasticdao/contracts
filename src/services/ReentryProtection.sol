// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for reentry protection
/// based on implementation
/// https://github.com/o0ragman0o/ReentryProtected/blob/master/ReentryProtected.sol
/// @dev ElasticDAO network contracts can read/write from this contract
contract ReentryProtection {
  // The reentry protection state mutex
  bool internal mutex = false;

  // This modifier can be used on functions with external calls to
  // prevent reentry attacks.
  // Constraints:
  //   Protected functions must have only one point of exit.
  //   Protected functions cannot use the `return` keyword
  //   Protected functions return values must be through return parameters.
  modifier preventReentry() {
    require(!mutex, 'ElasticDAO: Reentry Detected');

    mutex = true;
    _;
    mutex = false;
  }
}
