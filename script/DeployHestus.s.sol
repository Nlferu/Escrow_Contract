// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Hestus} from "../src/tokens/Hestus.sol";
import {console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";

contract DeployHestus is Script {
    function run() external returns (Hestus) {
        uint256 deployerKey = vm.envUint("HST_PRIVATE_KEY");

        uint256 hstSupply = 9000;

        vm.startBroadcast(deployerKey);
        Hestus hestus = new Hestus(hstSupply);
        console.log("Hestus Token Deployed: ", address(hestus));
        console.log("Hestus Token Owner: ", msg.sender);
        vm.stopBroadcast();

        return (hestus);
    }
}
