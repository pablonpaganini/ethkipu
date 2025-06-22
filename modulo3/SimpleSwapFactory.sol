// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/** 
 * @title SimpleSwapFactory
 * @dev Factory contract to manage and deploy token pairs for swapping
 */

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./interfaces/ISimpleSwapPair.sol";
import "./interfaces/ISimpleSwapFactory.sol";
import "./libraries/SimpleSwapLibrary.sol";
import "./SimpleSwapPair.sol";

contract SimpleSwapFactory is ISimpleSwapFactory {

    /// @notice Mapping of token pairs to their corresponding pair contract address
    mapping(address => mapping(address => address)) private pairs;

    /// @notice Array of all pair contract addresses
    address[] public allPairs;

    /**
     * @notice Returns the total number of pairs created
     * @return Length of the allPairs array
     */
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    /**
     * @notice Returns the address of the pair contract for two tokens
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @return pair Address of the pair contract
     */
    function getPair(address tokenA, address tokenB) external view returns(address pair) {
        (address token0, address token1) = SimpleSwapLibrary.sortTokens(tokenA, tokenB);
        return pairs[token0][token1];
    }

    /**
     * @notice Creates a new pair contract for two tokens if it does not exist
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @return pair Address of the newly created pair contract
     */
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "SimpleSwap:IDENTICAL_ADDRESSES");

        // Token0 is always the address with the lower value
        (address token0, address token1) = SimpleSwapLibrary.sortTokens(tokenA, tokenB);
        require(token0 != address(0), "SimpleSwap:ZERO_ADDRESS");
        require(pairs[token0][token1] == address(0), "SimpleSwap:PAIR_EXISTS");

        // Construct name and symbol for the new pair
        string memory symbol0 = IERC20Metadata(tokenA).symbol();
        string memory symbol1 = IERC20Metadata(tokenB).symbol();
        string memory pairSymbol = string(abi.encodePacked(symbol0, "-", symbol1));
        string memory pairName = string(abi.encodePacked("SimpleSwap ", symbol0, "/", symbol1));

        // Deploy a new SimpleSwapPair contract using create2
        bytes memory bytecode = type(SimpleSwapPair).creationCode;
        bytes memory initCode = abi.encodePacked(bytecode, abi.encode(pairName, pairSymbol));
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(initCode, 32), mload(initCode), salt)
        }
        // Initialize contract created with tokens address (pair)
        ISimpleSwapPair(pair).initialize(token0, token1);

        pairs[token0][token1] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }
} 
