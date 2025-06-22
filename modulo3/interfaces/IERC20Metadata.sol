// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IERC20Metadata
 * @dev Interface for retrieving ERC20 token metadata
 */
interface IERC20Metadata {

    /**
     * @notice Returns the name of the token
     * @return The token name as a string
     */
    function name() external view returns (string memory);

    /**
     * @notice Returns the symbol of the token
     * @return The token symbol as a string
     */
    function symbol() external view returns (string memory);
} 
