// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title ISimpleSwapPair
 * @dev Interface for the SimpleSwapPair contract which represents a liquidity pool pair
 */
interface ISimpleSwapPair {

    /**
     * @notice Emitted when liquidity is added to the pool
     * @param sender Address of the user who provided liquidity
     * @param amount0 Amount of token0 added
     * @param amount1 Amount of token1 added
     */
    event Mint(address indexed sender, uint amount0, uint amount1);

    /**
     * @notice Emitted when the reserves are updated
     * @param reserve0 New reserve amount for token0
     * @param reserve1 New reserve amount for token1
     */
    event Sync(uint256 reserve0, uint256 reserve1);

    /**
     * @notice Emitted when liquidity is removed from the pool
     * @param sender Address of the user who removed liquidity
     * @param amount0 Amount of token0 withdrawn
     * @param amount1 Amount of token1 withdrawn
     * @param to Address that received the withdrawn tokens
     */
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    /**
     * @notice Emitted when a swap is executed
     * @param sender Address initiating the swap
     * @param reserve0Initial Reserve of token0 before the swap
     * @param reserve1Initial Reserve of token1 before the swap
     * @param reserve0Final Reserve of token0 after the swap
     * @param reserve1Final Reserve of token1 after the swap
     * @param to Address receiving the output token
     */
    event Swap(
        address indexed sender,
        uint reserve0Initial,
        uint reserve1Initial,
        uint reserve0Final,
        uint reserve1Final,
        address indexed to
    );

    /**
     * @notice Initializes the pair with two token addresses
     * @param _token0 Address of token0
     * @param _token1 Address of token1
     */
    function initialize(address _token0, address _token1) external;

    /**
     * @notice Returns the current reserves of token0 and token1
     * @return Reserve amount for token0 and token1 respectively
     */
    function getReserves() external view returns (uint, uint);

    /**
     * @notice Mints LP tokens to the provided address based on liquidity added
     * @param _to Address receiving the minted LP tokens
     * @return Amount of LP tokens minted
     */
    function mint(address _to) external returns (uint);

    /**
     * @notice Burns LP tokens and returns the underlying tokens to the recipient
     * @param _to Address receiving the withdrawn tokens
     * @return Amounts of token0 and token1 withdrawn
     */
    function burn(address _to) external returns (uint, uint);

    /**
     * @notice Executes a swap by sending a specified amount of one token to a recipient
     * @param tokenOut Address of the token to send out
     * @param amount Amount of tokenOut to transfer
     * @param to Address receiving the tokenOut
     */
    function swap(address tokenOut, uint amount, address to) external;
}
