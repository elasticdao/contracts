// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;

import './SafeMath.sol';

/**
 * @dev Provides functions for performing ElasticDAO specific math.
 *
 * These functions correspond with functions provided by the JS SDK and should
 * always be used instead of doing calculations within other contracts to avoid
 * any inconsistencies in the math.
 *
 * Notes:
 *
 * - Dash values represent the state after a transaction has completed successfully.
 * - Non-dash values represent the current state, before the transaction has completed.
 * - Lambda is the math term for shares. We typically expose the value to users as
 *   shares instead of lambda because it's easier to grok.
 */
library ElasticMath {
  /**
   * @dev calculates the value of capitalDelta; the amount of ETH backing each
   * governance token.
   * @param totalEthValue amount of ETH in the DAO contract
   * @param totalSupplyOfTokens number of tokens in existance
   *
   * capitalDelta = totalEthValue / totalSupplyOfTokens
   * @return uint256
   */
  function capitalDelta(uint256 totalEthValue, uint256 totalSupplyOfTokens)
    internal
    pure
    returns (uint256)
  {
    return wdiv(totalEthValue, totalSupplyOfTokens);
  }

  /**
   * @dev calculates the value of deltaE; the amount of ETH required to mint deltaLambda
   * @param deltaLambda = lambdaDash - lambda
   * @param capitalDeltaValue the ETH/token ratio; see capitalDelta(uint256, uint256)
   * @param k constant token multiplier - it increases the number of tokens
   *  that each member of the DAO has with respect to their lambda
   * @param elasticity the percentage by which capitalDelta (cost of entering the  DAO)
   * should increase on every join
   * @param lambda outstanding shares
   * @param m - lambda modifier - it's value increases every time someone joins the DAO
   *
   * lambdaDash = deltaLambda + lambda
   * mDash = ( lambdaDash / lambda ) * m
   * deltaE = capitalDelta * k * ( lambdaDash * mDash * ( 1 + elasticity ) - lambda * m )
   * @return uint256
   */
  function deltaE(
    uint256 deltaLambda,
    uint256 capitalDeltaValue,
    uint256 k,
    uint256 elasticity,
    uint256 lambda,
    uint256 m
  ) internal pure returns (uint256) {
    uint256 lambdaDash = SafeMath.add(deltaLambda, lambda);

    return
      wmul(
        wmul(capitalDeltaValue, k),
        SafeMath.sub(
          wmul(lambdaDash, wmul(mDash(lambdaDash, lambda, m), revamp(elasticity))),
          wmul(lambda, m)
        )
      );
  }

  /**
   * @dev calculates the lambda value given t, k, & m
   * @param tokens t value; number of tokens for which lambda should be calculated
   * @param k constant token multiplier - it increases the number of tokens
   *  that each member of the DAO has with respect to their lambda
   * @param m - lambda modifier - it's value increases every time someone joins the DAO
   *
   * lambda = t / ( m * k)
   * @return uint256
   */
  function lambdaFromT(
    uint256 tokens,
    uint256 k,
    uint256 m
  ) internal pure returns (uint256) {
    return wdiv(tokens, wmul(k, m));
  }

  /**
   * @dev calculates the future share modifier given the future value of
   * lambda (lambdaDash), the current value of lambda, and the current share modifier
   * @param m current share modifier
   * @param lambda current outstanding shares
   * @param lambdaDash future outstanding shares
   *
   * mDash = ( lambdaDash / lambda ) * m
   * @return uint256
   */
  function mDash(
    uint256 lambdaDash,
    uint256 lambda,
    uint256 m
  ) internal pure returns (uint256) {
    return wmul(wdiv(lambdaDash, lambda), m);
  }

  /**
   * @dev calculates the value of revamp
   * @param elasticity the percentage by which capitalDelta should increase
   *
   * revamp = 1 + elasticity
   * @return uint256
   */
  function revamp(uint256 elasticity) internal pure returns (uint256) {
    return SafeMath.add(elasticity, 1000000000000000000);
  }

  /**
   * @dev calculates the number of tokens represented by lambda given k & m
   * @param lambda shares
   * @param k a constant, initially set by the DAO
   * @param m share modifier
   *
   * t = lambda * m * k
   * @return uint256
   */
  function t(
    uint256 lambda,
    uint256 k,
    uint256 m
  ) internal view returns (uint256) {
    if (lambda == 0) {
      return 0;
    }

    return wmul(wmul(lambda, k), m);
  }

  /**
   * @dev multiplies two float values, required since solidity does not handle
   * floating point values
   *
   * inspiration: https://github.com/dapphub/ds-math/blob/master/src/math.sol
   *
   * @return uint256
   */
  function wmul(uint256 a, uint256 b) internal pure returns (uint256) {
    return
      SafeMath.div(
        SafeMath.add(SafeMath.mul(a, b), SafeMath.div(1000000000000000000, 2)),
        1000000000000000000
      );
  }

  /**
   * @dev divides two float values, required since solidity does not handle
   * floating point values.
   *
   * inspiration: https://github.com/dapphub/ds-math/blob/master/src/math.sol
   *
   * @return uint256
   */
  function wdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return SafeMath.div(SafeMath.add(SafeMath.mul(a, 1000000000000000000), SafeMath.div(b, 2)), b);
  }
}
