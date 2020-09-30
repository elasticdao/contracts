// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;

import './SafeMath.sol';

/**
 * This library does the Elastic math
 */

library ElasticMath {
  /**
   * @dev calculates the value of deltaE
   * @param deltaLambda = lambdaDash - lambda
   * @param capitalDelta is the Eth/Egt ratio
   * @param k is a constant, initially set by the DAO
   * @param elasticity is the value of elasticity, initially set by the DAO
   * @param lambda = Current outstanding shares
   * @param m = Current share modifier
   *
   * mDash = ( lambdaDash / lambda ) * m
   * deltaE =  ( capitalDelta * k ( ( lambdaDash * mDash * ( 1 + elasticity ) ) - lambda * m )
   * @return deltaEValue uint256
   */
  function deltaE(
    uint256 deltaLambda,
    uint256 capitalDelta,
    uint256 k,
    uint256 elasticity,
    uint256 lambda,
    uint256 m
  ) internal pure returns (uint256 deltaEValue) {
    uint256 lambdaDash = SafeMath.add(deltaLambda, lambda);
    deltaEValue = SafeMath.mul(
      SafeMath.mul(capitalDelta, k),
      SafeMath.sub(
        SafeMath.mul(lambdaDash, SafeMath.mul(mDash(lambdaDash, lambda, m), revamp(elasticity))),
        SafeMath.mul(lambda, m)
      )
    );
    return deltaEValue;
  }

  /**
   * @dev returns the value of mDash
   * mDash = New share modifier
   * @param m = Current share modifier
   * @param lambda = Current outstanding shares
   * @param lambdaDash = New outstanding shares
   *
   * mDash = ( lambdaDash / lambda ) * m
   * @return mDashValue uint256
   */
  function mDash(
    uint256 lambdaDash,
    uint256 lambda,
    uint256 m
  ) internal pure returns (uint256 mDashValue) {
    return SafeMath.mul(SafeMath.div(lambdaDash, lambda), m);
  }

  /**
   * @dev returns the value of revamp
   * @param elasticity is the value of elasticity initially set by the DAO
   * upto 18 decimal points of precision
   *
   * Essentially takes in the value of elasticity and
   * and returns the value of ( 1 + elasticity ) with 18 decimals of precision
   * @return revampValue uint256
   */
  function revamp(uint256 elasticity) internal pure returns (uint256 revampValue) {
    return SafeMath.add(elasticity, SafeMath.pow(10, 18));
  }

  /**
   * @dev returns the value of the total tokens in the DAO
   * @param lambda = Current outstanding shares
   * @param k is a constant, initially set by the DAO
   * @param m = Current share modifier
   *
   * t = ( lambda * m * k )
   * @return tokens uint256
   */
  function t(
    uint256 lambda,
    uint256 k,
    uint256 m
  ) internal pure returns (uint256 tokens) {
    return SafeMath.mul(SafeMath.mul(lambda, k), m);
  }

  /**
   * @dev multiplies two float values,
   * required since soldity does not handle floating point values
   * @return uint256
   */
  // inspiration: https://github.com/dapphub/ds-math/blob/master/src/math.sol
  function wmul(uint256 a, uint256 b) internal pure returns (uint256) {
    return SafeMath.add(SafeMath.mul(a, b), 1000000000000000000 / 2) / 1000000000000000000;
  }
}