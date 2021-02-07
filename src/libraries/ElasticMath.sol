// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;

import './SafeMath.sol';

/**
 * This library does the Elastic math
 */

library ElasticMath {
  function capitalDelta(uint256 totalEthValue, uint256 totalSupplyOfTokens)
    internal
    pure
    returns (uint256)
  {
    return (wdiv(totalEthValue, totalSupplyOfTokens));
  }

  /**
   * @dev calculates the value of deltaE
   * @param deltaLambda = lambdaDash - lambda
   * @param capitalDeltaValue is the Eth/Egt ratio
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
    uint256 capitalDeltaValue,
    uint256 k,
    uint256 elasticity,
    uint256 lambda,
    uint256 m
  ) internal view returns (uint256 deltaEValue) {
    uint256 lambdaDash = SafeMath.add(deltaLambda, lambda);

    uint256 a = wmul(capitalDeltaValue, k);
    // console.log('contract: a:', a);

    uint256 b = revamp(elasticity);
    // console.log('contract: b: ', b);

    uint256 c = wmul(lambda, m);
    // console.log('contract: c: ', c);

    uint256 d = mDash(lambdaDash, lambda, m);
    // console.log('contract: d: ', d);

    uint256 e = wmul(d, b);
    // console.log('contract: e: ', e);

    uint256 f = wmul(lambdaDash, e);
    // console.log('contract: f: ', f);

    uint256 g = SafeMath.sub(f, c);
    // console.log('contract: g: ', g);

    deltaEValue = wmul(a, g);
    // console.log('contract: deltaEValue: ', deltaEValue);

    return deltaEValue;
  }

  function lambdaFromT(
    uint256 t,
    uint256 k,
    uint256 m
  ) internal pure returns (uint256 lambda) {
    return wdiv(t, wmul(k, m));
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
    return wmul(wdiv(lambdaDash, lambda), m);
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
    return wmul(wmul(lambda, k), m);
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

  /**
   * @dev divides two float values,
   * required since soldity does not handle floating point values
   * @return uint256
   */
  // inspiration: https://github.com/dapphub/ds-math/blob/master/src/math.sol
  function wdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return SafeMath.add(SafeMath.mul(a, 1000000000000000000), b / 2) / b;
  }
}
