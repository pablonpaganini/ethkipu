// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract M1 is ERC20 {
    
    constructor() ERC20("Moneda 1", "M1") {
        _mint(msg.sender, 1 ether);
    }
}