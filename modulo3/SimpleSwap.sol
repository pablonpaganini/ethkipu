// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/** 
 * @title SimpleSwap
 * @dev Router contract for managing token swaps and liquidity
 */

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./interfaces/ISimpleSwapFactory.sol";
import "./interfaces/ISimpleSwapPair.sol";
import "./libraries/SimpleSwapLibrary.sol";

contract SimpleSwap {

    /// @notice Address of the factory contract
    address public factory;

    /// @dev Ensures that the current block timestamp has not exceeded the deadline
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "SimpleSwap:EXPIRED");
        _;
    }

    /**
     * @notice Contract constructor
     * @param _factory Address of the factory contract
     */
    constructor(address _factory) {
        factory = _factory;
    }

    /**
     * @notice Gets the address of a token pair
     * @param tokenA Address of token A
     * @param tokenB Address of token B
     * @return pair Address of the pair contract
     */
    function getPair(address tokenA, address tokenB) external view returns(address pair) {
        pair = ISimpleSwapFactory(factory).getPair(tokenA, tokenB);
    }

    /**
     * @notice Adds liquidity to a token pair
     * @return amountA Amount of tokenA added
     * @return amountB Amount of tokenB added
     * @return liquidity Amount of LP tokens minted
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = this.getPair(tokenA, tokenB);
        IERC20(tokenA).transferFrom(msg.sender, pair, amountA);
        IERC20(tokenB).transferFrom(msg.sender, pair, amountB);
        liquidity = ISimpleSwapPair(pair).mint(to);
    }

    /**
     * @notice Removes liquidity from a pair
     * @return amountA Amount of tokenA returned
     * @return amountB Amount of tokenB returned
     */
    function removeLiquidity(
        address tokenA, 
        address tokenB, 
        uint liquidity, 
        uint amountAMin, 
        uint amountBMin, 
        address to, 
        uint deadline
    ) external ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = this.getPair(tokenA, tokenB);
        IERC20(pair).transferFrom(msg.sender, pair, liquidity); 
        (uint amount0, uint amount1) = ISimpleSwapPair(pair).burn(to);
        (address token0, ) = SimpleSwapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "SimpleSwap: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "SimpleSwap: INSUFFICIENT_B_AMOUNT");
    }

    /**
     * @notice Swaps a fixed amount of input tokens for as many output tokens as possible
     * @param amountIn Amount of input tokens to send
     * @param amountOutMin Minimum amount of output tokens that must be received
     * @param path Array containing input and output token addresses
     * @param to Address to receive output tokens
     * @param deadline Transaction must be completed before this time
     * @return amounts Array of input and output token amounts
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        require(path.length == 2, "SimpleSwap:INVALID_PATH");
        address pair = this.getPair(path[0], path[1]);
        require(pair != address(0), "SimpleSwap:PAIR_DOES_NOT_EXISTS");
        (uint reserveIn, uint reserveOut) = ISimpleSwapPair(pair).getReserves();

        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = getAmountOut(amountIn, reserveIn, reserveOut);
        require(amounts[1] >= amountOutMin, "SimpleSwap:INSUFFICIENT_OUTPUT_AMOUNT");

        IERC20(path[0]).transferFrom(msg.sender, pair, amountIn);
        ISimpleSwapPair(pair).swap(path[1], amounts[1], to);
    }

    /**
     * @notice Gets the price of tokenB in terms of tokenA
     * @param tokenA Address of token A
     * @param tokenB Address of token B
     * @return price Price of tokenB denominated in tokenA
     */
    function getPrice(address tokenA, address tokenB) external view returns (uint price) {
        address pair = this.getPair(tokenA, tokenB);
        require(pair != address(0), "SimpleSwap:PAIR_DOES_NOT_EXISTS");
        (uint reserveA, uint reserveB) = ISimpleSwapPair(pair).getReserves();
        price = (reserveB * 1e18) / reserveA;
    }

    /**
     * @notice Given an input amount of an asset and pair reserves, returns the maximum output amount
     * @param amountIn Amount of input tokens
     * @param reserveIn Reserve of input token
     * @param reserveOut Reserve of output token
     * @return amountOut Output token amount calculated
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        returns (uint amountOut)
    {
        require(amountIn > 0, "SimpleSwap:INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SimpleSwap:INSUFFICIENT_LIQUIDITY");
        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
    }

    /**
     * @dev Internal logic to calculate optimal amounts for liquidity
     */
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        address pair = this.getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = ISimpleSwapFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = ISimpleSwapPair(pair).getReserves();
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = _quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "SimpleSwap:INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = _quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "SimpleSwap:INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /**
     * @notice Returns equivalent amount of tokenB given tokenA and reserves
     * @param amountA Amount of tokenA
     * @param reserveA Reserve of tokenA
     * @param reserveB Reserve of tokenB
     * @return amountB Equivalent amount of tokenB
     */
    function _quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, "SimpleSwap:INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "SimpleSwap:INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }
} 
