// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Escrow is Ownable, ReentrancyGuard {
    /// @dev Errors
    /// @dev Enums
    /// @dev Variables
    /// @dev Structs
    /// @dev Mappings
    /// @dev Events

    /// @dev Constructor
    constructor() Ownable(msg.sender) {}

    //////////////////////////////////// @notice Escrow External Functions ////////////////////////////////////
    //////////////////////////////////// @notice Escrow Internal Functions ////////////////////////////////////
    //////////////////////////////////// @notice Escrow Owners Functions //////////////////////////////////////
    //////////////////////////////////// @notice Escrow Getters ////////////////////////////////////
}
