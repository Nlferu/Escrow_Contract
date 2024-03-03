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
        uint256 idToTokensAmount;
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

        Escrows storage escrows = s_escrows[s_totalEscrows];
        escrows.idToPartyOne = msg.sender;
        escrows.idToPartyTwo = counterparty;
        escrows.idToPartyOneToken = initialToken;
        escrows.idToPartyTwoToken = finalToken;
        escrows.idToTokensAmount = amount;
        escrows.idToEscrowStatus = EscrowStatus.PENDING;
        s_totalEscrows += 1;

        emit TokensTransferred(initialToken, amount);

        bool success = IERC20(initialToken).transferFrom(msg.sender, address(this), amount);
        if (!success) revert Escrow__TransferFailed();
    }

    function withdrawToken(address tokenAddress, address recipient, uint256 amount) external {
        if (!s_supportedTokens[tokenAddress]) revert Escrow__TokenNotSupported();

        bool success = IERC20(tokenAddress).transfer(recipient, amount);
        if (!success) revert Escrow__TransferFailed();
    }

    function exchangeTokens(uint256 escrowId) internal {
        Escrows storage escrows = s_escrows[escrowId];
        if (escrows.idToEscrowStatus != EscrowStatus.PENDING) revert Escrow__NotActive();
        if (msg.sender != escrows.idToPartyTwo) revert Escrow__CpNotAllowed();
    }

    function cancelEscrow(uint256 escrowId) internal {
        Escrows storage escrows = s_escrows[escrowId];
        if (msg.sender != escrows.idToPartyOne || msg.sender != escrows.idToPartyTwo) revert Escrow__CancelNotAllowed();
    }

    function getTokenBalance(address tokenAddress) external view returns (uint256) {
        if (!s_supportedTokens[tokenAddress]) revert Escrow__TokenNotSupported();

        return IERC20(tokenAddress).balanceOf(address(this));
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
}
