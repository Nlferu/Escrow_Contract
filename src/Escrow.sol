// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";

interface IERC20 {
    /** @notice Allows to approve smart contract to acquire and manage chosen token amount */
    function approve(address spender, uint256 amount) external returns (bool);

    /** @notice Allows to transfer tokens from any address to any recipient */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /** @notice Allows to transfer tokens from this address to recipient */
    function transfer(address to, uint256 amount) external returns (bool);

    /** @notice Allows to check token balance for certain address */
    function balanceOf(address account) external view returns (uint256);
}

contract Escrow is Ownable, ReentrancyGuard {
    /// @dev Errors
    error Escrow__TokenAlreadySupported();
    error Escrow__TokenAlreadyNotSupported();
    error Escrow__TokenNotSupported();
    error Escrow__TransferFailed();
    error Escrow__NotActive();
    error Escrow__CancelNotAllowed();
    error Escrow__ApproveFailed();

    /// @dev Enums
    enum EscrowStatus {
        PENDING,
        SETTLED,
        CANCELLED
    }

    /// @dev Variables
    uint256 private s_totalEscrows;

    /// @dev Arrays
    address[] private s_supportedTokensList;

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
    mapping(uint256 => Escrows) private s_escrows;
    mapping(address => bool) private s_supportedTokens;

    /// @dev Events
    event NewEscrowInitialized(uint256 indexed escrowId, address indexed initializer, uint256 tokensAmount);
    event TokensTransferred(address indexed token, uint256 indexed amount);
    event EscrowApprovedToUseTokens(address indexed token);
    event TokenAddedToSupportedTokensList(address indexed token);
    event TokenRemovedFromSupportedTokensList(address indexed token);
    event EscrowSettledSuccessfully(uint256 indexed escrowId);
    event EscrowCancelled(uint256 indexed escrowId);

    /// @dev Constructor
    constructor() Ownable(msg.sender) {}

    //////////////////////////////////// @notice Escrow External Functions ////////////////////////////////////

    /** @notice Initializing escrow for chosen tokens and their amounts, where exchange is 1:1 */
    function initializeEscrow(address initialToken, address finalToken, uint256 amount) external {
        if (!s_supportedTokens[initialToken] || !s_supportedTokens[finalToken]) revert Escrow__TokenNotSupported();

        emit EscrowApprovedToUseTokens(initialToken);

        bool approve = IERC20(initialToken).approve(address(this), amount);
        if (!approve) revert Escrow__ApproveFailed();

        emit NewEscrowInitialized(s_totalEscrows, msg.sender, amount);
        emit TokensTransferred(initialToken, amount);

        bool success = IERC20(initialToken).transferFrom(msg.sender, address(this), amount);
        if (!success) revert Escrow__TransferFailed();

        Escrows storage escrows = s_escrows[s_totalEscrows];
        escrows.idToPartyOne = msg.sender;
        escrows.idToPartyOneToken = initialToken;
        escrows.idToPartyTwoToken = finalToken;
        escrows.idToPartyOneTokensAmount = amount;
        escrows.idToEscrowStatus = EscrowStatus.PENDING;
        s_totalEscrows += 1;
    }

    /** @notice This function is second part that needs to be fulfilled to settle escrow */
    function exchangeTokens(uint256 escrowId) external {
        Escrows storage escrows = s_escrows[escrowId];
        if (escrows.idToEscrowStatus != EscrowStatus.PENDING) revert Escrow__NotActive();

        emit EscrowApprovedToUseTokens(escrows.idToPartyTwoToken);

        bool approve = IERC20(escrows.idToPartyTwoToken).approve(address(this), escrows.idToPartyOneTokensAmount);
        if (!approve) revert Escrow__ApproveFailed();

        emit TokensTransferred(escrows.idToPartyTwoToken, escrows.idToPartyOneTokensAmount);

        bool success = IERC20(escrows.idToPartyTwoToken).transferFrom(msg.sender, address(this), escrows.idToPartyOneTokensAmount);
        if (!success) revert Escrow__TransferFailed();

        escrows.idToPartyTwo = msg.sender;
        escrows.idToPartyTwoTokensAmount = escrows.idToPartyOneTokensAmount;
    }

    /** @notice This function contains withdraw function */
    function cancelEscrow(uint256 escrowId) external {
        Escrows storage escrows = s_escrows[escrowId];
        // Add owner to allow him cancel escrow
        if (escrows.idToEscrowStatus != EscrowStatus.PENDING) revert Escrow__NotActive();
        if (msg.sender != escrows.idToPartyOne && msg.sender != escrows.idToPartyTwo && msg.sender != owner()) revert Escrow__CancelNotAllowed();

        emit EscrowCancelled(escrowId);

        bool success = IERC20(escrows.idToPartyOneToken).transfer(escrows.idToPartyOne, escrows.idToPartyOneTokensAmount);
        if (!success) revert Escrow__TransferFailed();

        bool transfer = IERC20(escrows.idToPartyTwoToken).transfer(escrows.idToPartyTwo, escrows.idToPartyTwoTokensAmount);
        if (!transfer) revert Escrow__TransferFailed();

        escrows.idToEscrowStatus = EscrowStatus.CANCELLED;
    }

    /** @notice If we automate this contract with chainlink automation keepers, this should be internal and callable only by keeper */
    function settleEscrow(uint256 escrowId) external onlyOwner {
        Escrows storage escrows = s_escrows[escrowId];
        if (escrows.idToEscrowStatus != EscrowStatus.PENDING) revert Escrow__NotActive();

        emit EscrowSettledSuccessfully(escrowId);

        bool success = IERC20(escrows.idToPartyOneToken).transfer(escrows.idToPartyTwo, escrows.idToPartyOneTokensAmount);
        if (!success) revert Escrow__TransferFailed();

        bool transfer = IERC20(escrows.idToPartyTwoToken).transfer(escrows.idToPartyOne, escrows.idToPartyTwoTokensAmount);
        if (!transfer) revert Escrow__TransferFailed();

        escrows.idToEscrowStatus = EscrowStatus.SETTLED;
    }

    //////////////////////////////////// @notice Escrow Internal Functions ////////////////////////////////////
    /// Internal functions can be added only if we implement automatization with chainlink keepers

    //////////////////////////////////// @notice Escrow Owners Functions //////////////////////////////////////

    function addSupportedToken(address token) external onlyOwner {
        if (s_supportedTokens[token]) revert Escrow__TokenAlreadySupported();

        emit TokenAddedToSupportedTokensList(token);

        s_supportedTokens[token] = true;
        s_supportedTokensList.push(token);
    }

    function removeSupportedToken(address token) external onlyOwner {
        if (!s_supportedTokens[token]) revert Escrow__TokenAlreadyNotSupported();

        s_supportedTokens[token] = false;

        for (uint i = 0; i < s_supportedTokensList.length; i++) {
            if (s_supportedTokensList[i] == token) {
                emit TokenRemovedFromSupportedTokensList(token);

                // Swapping wallet to be removed into last spot in array, so we can pop it and avoid getting 0 in array
                s_supportedTokensList[i] = s_supportedTokensList[s_supportedTokensList.length - 1];
                s_supportedTokensList.pop();
            }
        }
    }

    //////////////////////////////////// @notice Escrow Getters ////////////////////////////////////

    function getSupportedTokens() external view returns (address[] memory) {
        return s_supportedTokensList;
    }

    function getEscrowTokenBalance(uint256 escrowId) external view returns (uint256) {
        Escrows storage escrows = s_escrows[escrowId];

        return IERC20(escrows.idToPartyOneToken).balanceOf(address(this));
    }

    function getTokenBalance(address token) external view returns (uint256) {
        if (!s_supportedTokens[token]) revert Escrow__TokenNotSupported();

        return IERC20(token).balanceOf(address(this));
    }

    function getUserTokenBalance(address user, address token) external view returns (uint256) {
        if (!s_supportedTokens[token]) revert Escrow__TokenNotSupported();

        return IERC20(token).balanceOf(user);
    }

    function getEscrowData(uint256 escrowId) external view returns (address, address, address, address, uint256, uint256, EscrowStatus) {
        Escrows storage escrows = s_escrows[escrowId];

        return (
            escrows.idToPartyOne,
            escrows.idToPartyTwo,
            escrows.idToPartyOneToken,
            escrows.idToPartyTwoToken,
            escrows.idToPartyOneTokensAmount,
            escrows.idToPartyTwoTokensAmount,
            escrows.idToEscrowStatus
        );
    }
}
