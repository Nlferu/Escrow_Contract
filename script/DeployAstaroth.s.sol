// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Astaroth} from "../src/tokens/Astaroth.sol";
import {console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";

contract DeployAstaroth is Script {
    function run() external returns (Astaroth, address) {
        uint256 deployerKey = vm.envUint("AST_PRIVATE_KEY");

        uint256 astSupply = 7000;

        vm.startBroadcast(deployerKey);
        Astaroth astaroth = new Astaroth(astSupply);
        address astOwner = vm.addr(deployerKey);
        console.log("Astaroth Token Deployed: ", address(astaroth));
        console.log("Astaroth Token Owner: ", astOwner);
        vm.stopBroadcast();

        return (astaroth, astOwner);
    }
}
