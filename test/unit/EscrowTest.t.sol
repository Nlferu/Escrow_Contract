// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Vm} from "forge-std/Vm.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployAstaroth} from "../../script/DeployAstaroth.s.sol";
import {DeployHestus} from "../../script/DeployHestus.s.sol";
import {Astaroth} from "../../src/tokens/Astaroth.sol";
import {Hestus} from "../../src/tokens/Hestus.sol";
import {DeployEscrow} from "../../script/DeployEscrow.s.sol";
import {Escrow} from "../../src/Escrow.sol";

contract EscrowTest is StdCheats, Test {
    event NewEscrowInitialized(uint256 indexed escrowId, address indexed initializer, uint256 tokensAmount);
    event TokensTransferred(address indexed token, uint256 indexed amount);
    event TokenAddedToSupportedTokensList(address indexed token);
    event TokenRemovedFromSupportedTokensList(address indexed token);
    event EscrowSettledSuccessfully(uint256 indexed escrowId);
    event EscrowCancelled(uint256 indexed escrowId);

    enum EscrowStatus {
        PENDING,
        SETTLED,
        CANCELLED
    }

    DeployAstaroth astDeployer;
    DeployHestus hstDeployer;
    DeployEscrow escrowDeployer;

    Astaroth astaroth;
    address astOwner;
    Hestus hestus;
    address hstOwner;
    Escrow escrow;

    uint256 amount = 4000;

    function setUp() external {
        astDeployer = new DeployAstaroth();
        hstDeployer = new DeployHestus();
        escrowDeployer = new DeployEscrow();

        (astaroth, astOwner) = astDeployer.run();
        (hestus, hstOwner) = hstDeployer.run();
        (escrow) = escrowDeployer.run();

        /** @notice User needs to approve our smart contract directly to allow for performing transactions using desired token */
        vm.prank(astOwner);
        astaroth.approve(address(escrow), amount);

        vm.prank(hstOwner);
        hestus.approve(address(escrow), amount);
    }

    function testCanSetupEscrowAndTokensCorrectly() public view {
        console.log("AST User Balance", astaroth.balanceOf(astOwner));
        console.log("HST User Balance", hestus.balanceOf(hstOwner));

        assert(astaroth.balanceOf(address(escrow)) == 0);
        assert(hestus.balanceOf(address(escrow)) == 0);
        assert(astaroth.balanceOf(astOwner) == 7000);
        assert(hestus.balanceOf(hstOwner) == 9000);
    }

    function testCanInitializeEscrow() public {
        vm.expectEmit(true, false, false, false, address(escrow));
        emit NewEscrowInitialized(escrow.getTotalEscrows(), astOwner, amount);
        vm.expectEmit(true, false, false, false, address(escrow));
        emit TokensTransferred(address(astaroth), amount);
        vm.prank(astOwner);
        escrow.initializeEscrow(address(astaroth), amount);
    }
}
