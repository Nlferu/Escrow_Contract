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
    Hestus hestus;
    Escrow escrow;

    function setUp() external {
        astDeployer = new DeployAstaroth();
        hstDeployer = new DeployHestus();
        escrowDeployer = new DeployEscrow();

        (astaroth) = astDeployer.run();
        (hestus) = hstDeployer.run();
        (escrow) = escrowDeployer.run();

        console.log("Astaroth Token: ", address(astaroth));
        console.log("Hestus Token: ", address(hestus));
        console.log("Escrow Contract: ", address(escrow));
    }

    function testIsSetupPerformedCorrectly() public {
        console.log("Astaroth Owner: ", "0x70997970C51812dc3A010C7d01b50e0d17dc79C8");
        console.log("Hestus Owner: ", "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC");
        console.log("Escrow Owner: ", address(escrowDeployer));

        console.log("AST User Balance", astaroth.balanceOf(0x70997970C51812dc3A010C7d01b50e0d17dc79C8));
        console.log("HST User Balance", hestus.balanceOf(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));
    }
}
