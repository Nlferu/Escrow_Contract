# Escrow Contract

## Blockchain

-   Ethereum

## Supported Networks

-   Localhost
-   Sepolia

## Languages Used

-   Solidity
-   Type Script

## Frameworks Used

-   Foundry

## Smart Contract Details

    ● Maintains separate accounts for each user, allowing efficient handling of multiple users simultaneously.
    ● Allows for the multi-call of entrypoints: deposit and withdraw in single transaction (swap).
    ● Only the owner of an account should be able to withdraw funds from their respective escrow account.
    ● Utilizing a generic token type (SPL Token, Erc20, PSP22) based on your chosen ecosystem.
    ● Address potential security concerns, particularly vulnerabilities like reentrancy.
    ● Includes end-to-end unit tests using type script.
