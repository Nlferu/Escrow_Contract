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
    error Escrow__NotActive();
    error Escrow__CpNotAllowed();
    error Escrow__CancelNotAllowed();

    /// @dev Enums
    enum EscrowStatus {
        PENDING,
        PERFORMED,
        CANCELLED
    }

    /// @dev Variables
    uint256 private s_totalEscrows;

    /// @dev Structs
    struct Escrows {
        address idToPartyOne;
        address idToPartyTwo;
        address idToPartyOneToken;
        address idToPartyTwoToken;
        uint256 idToPartyOneTokensAmount;
        uint256 idToPartyTwoTokensAmount;
        EscrowStatus idToEscrowStatus;
    }
    /// @dev Mappings
    mapping(address => bool) private s_supportedTokens;
    mapping(address => uint256) private tokenToAmount;
    mapping(uint256 => Escrows) private s_escrows;

    /// @dev Events
    event NewEscrowInitialized(uint256 escrowId, address initializer, address counterparty, uint256 tokensAmount);
    event TokensTransferred(address token, uint256 amount);

    /// @dev Constructor
    constructor() Ownable(msg.sender) {}

    //////////////////////////////////// @notice Escrow External Functions ////////////////////////////////////

    function initializeEscrow(address counterparty, address initialToken, address finalToken, uint256 amount) external {
        if (!s_supportedTokens[initialToken] || !s_supportedTokens[finalToken]) revert Escrow__TokenNotSupported();

        emit NewEscrowInitialized(s_totalEscrows, msg.sender, counterparty, amount);
        emit TokensTransferred(initialToken, amount);

        bool success = IERC20(initialToken).transferFrom(msg.sender, address(this), amount);
        if (!success) revert Escrow__TransferFailed();

        Escrows storage escrows = s_escrows[s_totalEscrows];
        escrows.idToPartyOne = msg.sender;
        escrows.idToPartyTwo = counterparty;
        escrows.idToPartyOneToken = initialToken;
        escrows.idToPartyTwoToken = finalToken;
        escrows.idToPartyOneTokensAmount = amount;
        escrows.idToEscrowStatus = EscrowStatus.PENDING;
        s_totalEscrows += 1;
    }

    function withdrawToken(address tokenAddress, address recipient, uint256 amount) external {
        if (!s_supportedTokens[tokenAddress]) revert Escrow__TokenNotSupported();

        bool success = IERC20(tokenAddress).transfer(recipient, amount);
        if (!success) revert Escrow__TransferFailed();
    }

    function exchangeTokens(uint256 escrowId) external {
        Escrows storage escrows = s_escrows[escrowId];
        if (escrows.idToEscrowStatus != EscrowStatus.PENDING) revert Escrow__NotActive();
        if (msg.sender != escrows.idToPartyTwo) revert Escrow__CpNotAllowed();

        bool success = IERC20(escrows.idToPartyTwoToken).transferFrom(msg.sender, address(this), escrows.idToPartyOneTokensAmount);
        if (!success) revert Escrow__TransferFailed();

        escrows.idToPartyTwoTokensAmount = escrows.idToPartyOneTokensAmount;
    }

    function cancelEscrow(uint256 escrowId) external {
        Escrows storage escrows = s_escrows[escrowId];
        // Add owner to allow him cancel escrow
        if (escrows.idToEscrowStatus != EscrowStatus.PENDING) revert Escrow__NotActive();
        if (msg.sender != escrows.idToPartyOne && msg.sender != escrows.idToPartyTwo) revert Escrow__CancelNotAllowed();

        bool success = IERC20(escrows.idToPartyOneToken).transfer(escrows.idToPartyOne, escrows.idToPartyOneTokensAmount);
        if (!success) revert Escrow__TransferFailed();

        bool transfer = IERC20(escrows.idToPartyTwoToken).transfer(escrows.idToPartyTwo, escrows.idToPartyTwoTokensAmount);
        if (!transfer) revert Escrow__TransferFailed();

        escrows.idToEscrowStatus = EscrowStatus.CANCELLED;
    }

    function performEscrow(uint256 escrowId) external {
        Escrows storage escrows = s_escrows[escrowId];
        if (escrows.idToEscrowStatus != EscrowStatus.PENDING) revert Escrow__NotActive();

        bool success = IERC20(escrows.idToPartyOneToken).transfer(escrows.idToPartyTwo, escrows.idToPartyOneTokensAmount);
        if (!success) revert Escrow__TransferFailed();

        bool transfer = IERC20(escrows.idToPartyTwoToken).transfer(escrows.idToPartyOne, escrows.idToPartyTwoTokensAmount);
        if (!transfer) revert Escrow__TransferFailed();
    }

    //////////////////////////////////// @notice Escrow Internal Functions ////////////////////////////////////
    //////////////////////////////////// @notice Escrow Owners Functions //////////////////////////////////////

    function addSupportedToken(address tokenAddress) external onlyOwner {
        if (s_supportedTokens[tokenAddress]) revert Escrow__TokenAlreadySupported();

        s_supportedTokens[tokenAddress] = true;
    }

    function removeSupportedToken(address tokenAddress) external onlyOwner {
        if (!s_supportedTokens[tokenAddress]) revert Escrow__TokenAlreadyNotSupported();

        s_supportedTokens[tokenAddress] = false;
    }

    //////////////////////////////////// @notice Escrow Getters ////////////////////////////////////

    function getEscrowTokenBalance(uint256 escrowId) external view returns (uint256) {
        Escrows storage escrows = s_escrows[escrowId];

        return IERC20(escrows.idToPartyOneToken).balanceOf(address(this));
    }

    function getTokenBalance(address tokenAddress) external view returns (uint256) {
        if (!s_supportedTokens[tokenAddress]) revert Escrow__TokenNotSupported();

        return IERC20(tokenAddress).balanceOf(address(this));
    }
}
