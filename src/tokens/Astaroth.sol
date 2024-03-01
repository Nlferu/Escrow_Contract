// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@solmate/tokens/ERC20.sol";

contract Astaroth is ERC20 {
    constructor(uint256 initialSupply) ERC20("Astaroth", "AST", 18) {
        _mint(msg.sender, initialSupply);
    }
}
