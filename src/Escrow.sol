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
    error Escrow__TokenNotSupported();
    error Escrow__TransferFailed();
    /// @dev Enums
    enum EscroStatus {
        PENDING,
        DONE
    }

    /// @dev Variables
    /// @dev Structs
    struct Escrows {
        address idToPartyOne;
        address idToPartyTwo;
        uint256 idToPartyOneBalance;
        uint256 idToPartyTwoBalance;
    }
    /// @dev Mappings
    mapping(address => bool) private supportedTokens;
    mapping(address => uint256) private tokenToAmount;

    /// @dev Events

    /// @dev Constructor
    constructor() Ownable(msg.sender) {}

    //////////////////////////////////// @notice Escrow External Functions ////////////////////////////////////

    function initializeEscrow(address counterparty, address token) external {}

    function depositToken(address tokenAddress, uint256 amount) external {
        if (!supportedTokens[tokenAddress]) revert Escrow__TokenNotSupported();

        bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        if (!success) revert Escrow__TransferFailed();
    }

    function withdrawToken(address tokenAddress, address recipient, uint256 amount) external {
        if (!supportedTokens[tokenAddress]) revert Escrow__TokenNotSupported();

        bool success = IERC20(tokenAddress).transfer(recipient, amount);
        if (!success) revert Escrow__TransferFailed();
    }

    function getTokenBalance(address tokenAddress) external view returns (uint256) {
        if (!supportedTokens[tokenAddress]) revert Escrow__TokenNotSupported();

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
