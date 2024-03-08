// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";

interface IERC20 {
    /** @notice Allows to transfer tokens from any address to any recipient */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /** @notice Allows to transfer tokens from this address to recipient */
    function transfer(address to, uint256 amount) external returns (bool);

    /** @notice Allows to check token balance for certain address */
    function balanceOf(address account) external view returns (uint256);
}

contract Escrow is Ownable, ReentrancyGuard {
    /// @dev Errors
    error Escrow__TransferFailed();
    error Escrow__NotActive();
    error Escrow__CancelNotAllowed();
    error Escrow__ApproveFailed();
    error Escrow__ZeroAmountNotAllowed();

    /// @dev Enums
    enum EscrowStatus {
        PENDING,
        SETTLED,
        CANCELLED
    }

    /// @dev Variables
    uint256 private s_totalEscrows;

    /// @dev Structs
    struct EscrowData {
        address idToPartyOne;
        address idToPartyTwo;
        address idToPartyOneToken;
        address idToPartyTwoToken;
        uint256 idToPartyOneTokensAmount;
        uint256 idToPartyTwoTokensAmount;
        EscrowStatus idToEscrowStatus;
    }
    /// @dev Mappings
    mapping(uint256 => EscrowData) private s_escrows;

    /// @dev Events
    event NewEscrowInitialized(uint256 indexed escrowId, address indexed initializer, uint256 tokensAmount);
    event TokensTransferred(address indexed token, uint256 indexed amount);
    event TokenAddedToSupportedTokensList(address indexed token);
    event TokenRemovedFromSupportedTokensList(address indexed token);
    event EscrowSettledSuccessfully(uint256 indexed escrowId);
    event EscrowCancelled(uint256 indexed escrowId);

    /// @dev Constructor
    constructor() Ownable(msg.sender) {}

    //////////////////////////////////// @notice Escrow External Functions ////////////////////////////////////

    /** REQUIRE - this function require user to first approve escrow for usage of certain token amount we cannot do it in this contract as msg.sender must be user */
    /** @notice Initializing escrow for chosen tokens and their amounts, where exchange is 1:1 */
    /** @param initialToken first token, which our escrow will hold */
    /** @param amount as we will be exchanging tokens 1 : 1 this is amount for this settlement */
    function initializeEscrow(address initialToken, uint256 amount) external {
        if (amount <= 0) revert Escrow__ZeroAmountNotAllowed();

        emit NewEscrowInitialized(s_totalEscrows, msg.sender, amount);
        emit TokensTransferred(initialToken, amount);

        bool success = IERC20(initialToken).transferFrom(msg.sender, address(this), amount);
        if (!success) revert Escrow__TransferFailed();

        EscrowData storage escrows = s_escrows[s_totalEscrows];
        escrows.idToPartyOne = msg.sender;
        escrows.idToPartyOneToken = initialToken;
        escrows.idToPartyOneTokensAmount = amount;
        escrows.idToEscrowStatus = EscrowStatus.PENDING;
        s_totalEscrows += 1;
    }

    /** REQUIRE - this function require user to first approve escrow for usage of certain token amount we cannot do it in this contract as msg.sender must be user */
    /** @notice This function is second part that needs to be fulfilled to settle escrow */
    /** @param escrowId escrow account id that we want to work with */
    /** @param exToken second token, which our escrow will hold */
    function fulfillEscrow(uint256 escrowId, address exToken) external {
        EscrowData storage escrows = s_escrows[escrowId];
        if (escrows.idToEscrowStatus != EscrowStatus.PENDING) revert Escrow__NotActive();

        emit TokensTransferred(exToken, escrows.idToPartyOneTokensAmount);

        bool success = IERC20(exToken).transferFrom(msg.sender, address(this), escrows.idToPartyOneTokensAmount);
        if (!success) revert Escrow__TransferFailed();

        escrows.idToPartyTwo = msg.sender;
        escrows.idToPartyTwoToken = exToken;
        escrows.idToPartyTwoTokensAmount = escrows.idToPartyOneTokensAmount;
    }

    /** @notice This function contains withdraw function */
    /** @param escrowId escrow account id that we want to work with */
    function cancelEscrow(uint256 escrowId) external nonReentrant {
        EscrowData storage escrows = s_escrows[escrowId];
        // Add owner to allow him cancel escrow
        if (escrows.idToEscrowStatus != EscrowStatus.PENDING) revert Escrow__NotActive();
        if (msg.sender != escrows.idToPartyOne && msg.sender != escrows.idToPartyTwo) revert Escrow__CancelNotAllowed();

        emit EscrowCancelled(escrowId);

        bool success = IERC20(escrows.idToPartyOneToken).transfer(escrows.idToPartyOne, escrows.idToPartyOneTokensAmount);
        if (!success) revert Escrow__TransferFailed();

        bool transfer = IERC20(escrows.idToPartyTwoToken).transfer(escrows.idToPartyTwo, escrows.idToPartyTwoTokensAmount);
        if (!transfer) revert Escrow__TransferFailed();

        escrows.idToEscrowStatus = EscrowStatus.CANCELLED;
    }

    /** @notice If we automate this contract with chainlink automation keepers, this should be internal and callable only by keeper */
    /** @param escrowId escrow account id that we want to work with */
    function settleEscrow(uint256 escrowId) external onlyOwner {
        EscrowData storage escrows = s_escrows[escrowId];
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

    //////////////////////////////////// @notice Escrow Getters ////////////////////////////////////

    /** @notice It gives us total number of escrows ever created by this contract */
    function getTotalEscrows() external view returns (uint256) {
        return s_totalEscrows;
    }

    /** @notice It gives us desired token balance of certain user */
    /** @param user wallet address */
    /** @param token ERC20 token address */
    function getUserTokenBalance(address user, address token) external view returns (uint256) {
        return IERC20(token).balanceOf(user);
    }

    /** @notice It gives us all information for certain escrow */
    /** @param escrowId escrow account id that we want to work with */
    function getEscrowData(uint256 escrowId) external view returns (address, address, address, address, uint256, uint256, EscrowStatus) {
        EscrowData storage escrows = s_escrows[escrowId];

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
