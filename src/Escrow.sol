// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract Escrow is Ownable, ReentrancyGuard {
    /// @dev Errors
    error Escrow__TokenAlreadySupported();
    error Escrow__TokenAlreadyNotSupported();
    /// @dev Enums
    /// @dev Variables
    /// @dev Structs
    /// @dev Mappings
    mapping(address => bool) public supportedTokens;

    /// @dev Events

    /// @dev Constructor
    constructor() Ownable(msg.sender) {}

    //////////////////////////////////// @notice Escrow External Functions ////////////////////////////////////

    function initializeEscrow(address counterparty, address token) external {}

    function depositToken(address tokenAddress, uint256 amount) external {
        require(supportedTokens[tokenAddress], "Token not supported");
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    function withdrawToken(address tokenAddress, address recipient, uint256 amount) external {
        require(supportedTokens[tokenAddress], "Token not supported");
        require(IERC20(tokenAddress).transfer(recipient, amount), "Transfer failed");
    }

    function getTokenBalance(address tokenAddress) external view returns (uint256) {
        require(supportedTokens[tokenAddress], "Token not supported");
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    //////////////////////////////////// @notice Escrow Internal Functions ////////////////////////////////////
    //////////////////////////////////// @notice Escrow Owners Functions //////////////////////////////////////

    function addSupportedToken(address tokenAddress) external onlyOwner {
        if (supportedTokens[tokenAddress]) revert Escrow__TokenAlreadySupported();

        supportedTokens[tokenAddress] = true;
    }

    function removeSupportedToken(address tokenAddress) external onlyOwner {
        if (!supportedTokens[tokenAddress]) revert Escrow__TokenAlreadyNotSupported();

        supportedTokens[tokenAddress] = false;
    }
    //////////////////////////////////// @notice Escrow Getters ////////////////////////////////////
}
