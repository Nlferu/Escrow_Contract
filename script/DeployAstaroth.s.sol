// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Astaroth} from "../src/tokens/Astaroth.sol";
import {console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";

contract DeployAstaroth is Script {
    function run() external returns (Astaroth) {
        uint256 deployerKey = vm.envUint("AST_PRIVATE_KEY");

        uint256 astSupply = 7000;

        vm.startBroadcast(deployerKey);
        Astaroth astaroth = new Astaroth(astSupply);
        console.log("Astaroth Token Deployed: ", address(astaroth));
        console.log("Astaroth Token Owner: ", msg.sender);
        console.log(address(this));
        vm.stopBroadcast();

        return (astaroth);
    }
}
