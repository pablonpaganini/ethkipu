// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title ISimpleSwapFactory
 * @dev Interface for the SimpleSwapFactory contract to manage pair creation and access
 */
interface ISimpleSwapFactory {

    /**
     * @notice Emitted when a new pair is created
     * @param token0 Address of the first token in the pair
     * @param token1 Address of the second token in the pair
     * @param pair Address of the newly created pair contract
     * @param totalPairs Total number of pairs after creation
     */
    event PairCreated(address indexed token0, address indexed token1, address pair, uint totalPairs);

    /**
     * @notice Returns the total number of pairs created
     * @return The number of pairs
     */
    function allPairsLength() external view returns (uint);

    /**
     * @notice Creates a new trading pair for two tokens
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @return Address of the created pair contract
     */
    function createPair(address tokenA, address tokenB) external returns (address);

    /**
     * @notice Returns the address of the pair contract for two tokens
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @return Address of the corresponding pair contract
     */
    function getPair(address tokenA, address tokenB) external view returns(address);
} 
