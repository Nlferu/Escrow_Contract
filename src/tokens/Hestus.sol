// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@solmate/tokens/ERC20.sol";

contract Hestus is ERC20 {
    constructor(uint256 initialSupply) ERC20("Hestus", "HST", 18) {
        _mint(msg.sender, initialSupply);
    }
}
