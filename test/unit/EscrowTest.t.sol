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
    DeployAstaroth astDeployer;
    DeployHestus hstDeployer;
    DeployEscrow escrowDeployer;

    Astaroth astaroth;
    address astOwner;
    Hestus hestus;
    address hstOwner;
    Escrow escrow;

    function setUp() external {
        astDeployer = new DeployAstaroth();
        hstDeployer = new DeployHestus();
        escrowDeployer = new DeployEscrow();

        (astaroth, astOwner) = astDeployer.run();
        (hestus, hstOwner) = hstDeployer.run();
        (escrow) = escrowDeployer.run();
    }

    function testIsSetupPerformedCorrectly() public {
        console.log("AST User Balance", astaroth.balanceOf(astOwner));
        console.log("HST User Balance", hestus.balanceOf(hstOwner));
    }
}
