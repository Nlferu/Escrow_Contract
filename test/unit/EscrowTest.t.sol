// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Vm} from "forge-std/Vm.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployEscrow} from "../../script/DeployEscrow.s.sol";
import {Escrow} from "../../src/Escrow.sol";

contract EscrowTest is StdCheats, Test {}
