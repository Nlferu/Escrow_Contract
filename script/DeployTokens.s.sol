// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Astaroth} from "../src/tokens/Astaroth.sol";
import {Hestus} from "../src/tokens/Hestus.sol";
import {console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";

contract DeployEscrow is Script {
    function run() external returns (Astaroth, Hestus) {
        uint256 deployerKey = vm.envUint("LOCAL_PRIVATE_KEY");

        uint256 astSupply = 7000;
        uint256 hstSupply = 9000;

        vm.startBroadcast(deployerKey);
        Astaroth astaroth = new Astaroth(astSupply);
        Hestus hestus = new Hestus(hstSupply);
        console.log("Astaroth Token Deployed: ", address(astaroth));
        console.log("Hestus Token Deployed: ", address(hestus));
        vm.stopBroadcast();

        return (astaroth, hestus);
    }
}
