// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Escrow} from "../src/Escrow.sol";
import {console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";

contract DeployEscrow is Script {
    function run() external returns (Escrow) {
        uint256 deployerKey = vm.envUint("LOCAL_PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        Escrow escrow = new Escrow();
        console.log("Escrow Deployed -> Owner: ", escrow.owner());
        vm.stopBroadcast();

        return (escrow);
    }
}
