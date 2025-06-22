// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/** 
 * @title SimpleSwapPair
 * @dev Liquidity pair contract for token swaps
 */

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/ISimpleSwapPair.sol";

contract SimpleSwapPair is ERC20, ISimpleSwapPair {
    /// @notice Address of the factory that created this pair
    address public factory;
    /// @notice Address of token0 in the pair
    address public token0;
    /// @notice Address of token1 in the pair
    address public token1;

    uint private reserve0;
    uint private reserve1;

    /// @dev Modifier to restrict actions to the factory only
    modifier isFactory {
        require(msg.sender == factory, "SimpleSwap:FORBIDDEN");
        _;
    } 

    /**
     * @notice Constructor sets the token name and symbol
     * @param _name Name of the liquidity token
     * @param _symbol Symbol of the liquidity token
     */
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        factory = msg.sender;
    }

    /**
     * @notice Initializes the token addresses for the pair
     * @param _token0 Address of the first token
     * @param _token1 Address of the second token
     */
    function initialize(address _token0, address _token1) external isFactory {
        token0 = _token0;
        token1 = _token1;
    }

    /**
     * @notice Returns current reserves of both tokens
     * @return reserve0 Amount of token0 in reserve
     * @return reserve1 Amount of token1 in reserve
     */
    function getReserves() public view returns (uint, uint) {
        return (reserve0, reserve1);
    }

    /**
     * @notice Mints LP tokens to a user based on deposited tokens
     * @param _to Address to receive LP tokens
     * @return _liquidity Amount of LP tokens minted
     */
    function mint(address _to) external returns (uint _liquidity) {
        (uint _balance0, uint _balance1) = _getBalances(); // Get actual balances
        (uint _reserve0, uint _reserve1) = getReserves();  // Get current reserves in contract

        // Prevent reentrancy attacks by updating reserves early
        _updateReserves(_balance0, _balance1);

        // Get the difference between actual balances and reserves
        uint _amount0 = _balance0 - _reserve0;
        uint _amount1 = _balance1 - _reserve1;

        uint _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            // First liquidity provision
            _liquidity = Math.sqrt(_amount0 * _amount1);
        } else {
            _liquidity = Math.min(
                (_amount0 * _totalSupply) / _reserve0, 
                (_amount1 * _totalSupply) / _reserve1
            );
        }
        require(_liquidity > 0, "SimpleSwap:INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(_to, _liquidity);

        emit Mint(msg.sender, _amount0, _amount1);
    }

    /**
     * @notice Burns LP tokens and returns underlying assets
     * @param _to Address to receive the tokens
     * @return _amount0 Amount of token0 withdrawn
     * @return _amount1 Amount of token1 withdrawn
     */
    function burn(address _to) external returns (uint _amount0, uint _amount1) {
        (uint _balance0, uint _balance1) = _getBalances();
        uint _liquidity = balanceOf(address(this));
        require(_liquidity > 0, "SimpleSwap:INSUFFICIENT_LIQUIDITY");

        uint _totalSupply = totalSupply();
        _amount0 = (_liquidity * _balance0) / _totalSupply;
        _amount1 = (_liquidity * _balance1) / _totalSupply;
        require(_amount0 > 0 && _amount1 > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_BURNED");

        // Burn LP tokens
        _burn(address(this), _liquidity);

        // Update reserves
        _balance0 -= _amount0;
        _balance1 -= _amount1;
        _updateReserves(_balance0, _balance1);

        // Transfer tokens to user
        IERC20(token0).transfer(_to, _amount0);
        IERC20(token1).transfer(_to, _amount1);

        emit Burn(msg.sender, _amount0, _amount1, _to);
    }

    /**
     * @notice Swaps tokens from the pair
     * @param tokenOut Address of the token to send out
     * @param amount Amount of tokenOut to transfer
     * @param to Address to receive tokenOut
     */
    function swap(address tokenOut, uint amount, address to) external {
        (address _token0, address _token1) = (token0, token1);
        require(tokenOut == _token0 || tokenOut == _token1, "SimpleSwap:INVALID_TOKEN");
        require(amount > 0, "SimpleSwap:INSUFFICIENT_OUTPUT_AMOUNT");

        (uint _reserve0, uint _reserve1) = getReserves();
        uint _reserve = tokenOut == _token0 ? _reserve0 : _reserve1;
        require(amount < _reserve, "SimpleSwap:INSUFFICIENT_LIQUIDITY");

        // Transfer requested token to user
        IERC20(tokenOut).transfer(to, amount);

        // Validate that enough of the input token was received
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));

        require(
            balance0 * balance1 >= _reserve0 * _reserve1,
            "SimpleSwap:K_INVARIANT"
        );

        _updateReserves(balance0, balance1);
        emit Swap(msg.sender, _reserve0, _reserve1, balance0, balance1, to);
    }

    /**
     * @notice Returns the actual token balances of the contract
     * @return balance0 Balance of token0
     * @return balance1 Balance of token1
     */
    function _getBalances() internal view returns (uint, uint) {
        return (
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );
    }

    /**
     * @notice Updates the internal reserves of the contract
     * @param _balance0 New balance of token0
     * @param _balance1 New balance of token1
     */
    function _updateReserves(uint _balance0, uint _balance1) internal {
        reserve0 = _balance0;
        reserve1 = _balance1;
        emit Sync(_balance0, _balance1);
    }
}
