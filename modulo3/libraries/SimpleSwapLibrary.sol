// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title SimpleSwapLibrary
 * @dev Utility library for sorting token addresses
 */
library SimpleSwapLibrary {

    /**
     * @notice Sorts two token addresses in ascending order
     * @dev Ensures a consistent token order for pair creation and lookups
     * @param tokenA Address of token A
     * @param tokenB Address of token B
     * @return token0 The address with the lower value
     * @return token1 The address with the higher value
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns(address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}
