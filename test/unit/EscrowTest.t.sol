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
        assert(escrow.owner() == 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    }

    function testCanInitializeEscrow() public {
        vm.expectRevert(Escrow.Escrow__ZeroAmountNotAllowed.selector);
        escrow.initializeEscrow(address(astaroth), 0);

        vm.expectEmit(true, false, false, false, address(escrow));
        emit NewEscrowInitialized(escrow.getTotalEscrows(), astOwner, amount);
        vm.expectEmit(true, false, false, false, address(escrow));
        emit TokensTransferred(address(astaroth), amount);
        vm.prank(astOwner);
        escrow.initializeEscrow(address(astaroth), amount);

        uint256 escrowAstTokenBalance = escrow.getUserTokenBalance(address(escrow), address(astaroth));
        (address partyOne, , address tokenOne, , uint256 tokenOneAmount, , Escrow.EscrowStatus escrowState) = escrow.getEscrowData(1);

        assert(partyOne == astOwner);
        assert(tokenOne == address(astaroth));
        assert(tokenOneAmount == 4000);
        assert(escrowState == Escrow.EscrowStatus.PENDING);
        assert(escrowAstTokenBalance == 4000);
        assert(escrow.getTotalEscrows() == 1);
    }

    function testCantfulfillEscrowIfNotInitialized() public {
        vm.expectRevert(Escrow.Escrow__EscrowDoesNotExists.selector);
        escrow.fulfillEscrow(0, address(hestus));

        vm.expectRevert(Escrow.Escrow__EscrowDoesNotExists.selector);
        escrow.fulfillEscrow(1, address(hestus));
    }

    function testCanfulfillEscrow() public escrowInitialized {
        vm.expectEmit(true, false, false, false, address(escrow));
        emit TokensTransferred(address(hestus), amount);
        vm.prank(hstOwner);
        escrow.fulfillEscrow(1, address(hestus));

        uint256 escrowHstTokenBalance = escrow.getUserTokenBalance(address(escrow), address(hestus));
        (, address partyTwo, , address tokenTwo, , uint256 tokenTwoAmount, Escrow.EscrowStatus escrowState) = escrow.getEscrowData(1);

        assert(partyTwo == hstOwner);
        assert(tokenTwo == address(hestus));
        assert(tokenTwoAmount == 4000);
        assert(escrowState == Escrow.EscrowStatus.FULFILLED);
        assert(escrowHstTokenBalance == 4000);
        assert(escrow.getTotalEscrows() == 1);
    }

    function testCantCancelEscrow() public {
        vm.expectRevert(Escrow.Escrow__EscrowDoesNotExists.selector);
        escrow.cancelEscrow(0);

        vm.expectRevert(Escrow.Escrow__EscrowDoesNotExists.selector);
        escrow.cancelEscrow(1);
    }

    function testCanCancelEscrowWhenEscrowPending() public escrowInitialized {
        vm.expectRevert(Escrow.Escrow__CancelNotAllowedForThisCaller.selector);
        escrow.cancelEscrow(1);

        vm.expectEmit(true, false, false, false, address(escrow));
        emit EscrowCancelled(1);
        vm.prank(astOwner);
        escrow.cancelEscrow(1);

        uint256 escrowAstTokenBalance = escrow.getUserTokenBalance(address(escrow), address(astaroth));
        uint256 escrowHstTokenBalance = escrow.getUserTokenBalance(address(escrow), address(hestus));

        assert(escrowAstTokenBalance == 0);
        assert(escrowHstTokenBalance == 0);
        assert(astaroth.balanceOf(astOwner) == 7000);
        assert(hestus.balanceOf(hstOwner) == 9000);
    }

    function testCanCancelEscrowWhenEscrowFulfilled() public escrowInitialized {
        vm.expectRevert(Escrow.Escrow__CancelNotAllowedForThisCaller.selector);
        escrow.cancelEscrow(1);

        vm.prank(hstOwner);
        escrow.fulfillEscrow(1, address(hestus));

        vm.expectEmit(true, false, false, false, address(escrow));
        emit EscrowCancelled(1);
        vm.prank(hstOwner);
        escrow.cancelEscrow(1);

        uint256 escrowAstTokenBalance = escrow.getUserTokenBalance(address(escrow), address(astaroth));
        uint256 escrowHstTokenBalance = escrow.getUserTokenBalance(address(escrow), address(hestus));

        assert(escrowAstTokenBalance == 0);
        assert(escrowHstTokenBalance == 0);
        assert(astaroth.balanceOf(astOwner) == 7000);
        assert(hestus.balanceOf(hstOwner) == 9000);
    }

    function testCantSettleEscrow() public {
        vm.expectRevert();
        escrow.settleEscrow(1);

        vm.prank(escrow.owner());
        vm.expectRevert(Escrow.Escrow__EscrowDoesNotExists.selector);
        escrow.settleEscrow(1);
    }

    function testOnlyOwnerCanSettleEscrow() public escrowInitialized {
        vm.prank(escrow.owner());
        vm.expectRevert(Escrow.Escrow__NotActive.selector);
        escrow.settleEscrow(1);
    }

    modifier escrowInitialized() {
        vm.prank(astOwner);
        escrow.initializeEscrow(address(astaroth), amount);

        _;
    }
}
