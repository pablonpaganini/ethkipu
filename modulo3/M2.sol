// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract M2 is ERC20 {
    
    constructor() ERC20("Moneda 2", "M2") {
        _mint(msg.sender, 1 ether);
    }
}