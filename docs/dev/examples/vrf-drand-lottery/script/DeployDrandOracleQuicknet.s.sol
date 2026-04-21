// SPDX-License-Identifier: VPL
pragma solidity ^0.8.34;

import {Script, console2} from "forge-std/Script.sol";
import {DrandOracleQuicknet} from "../src/oracles/DrandOracleQuicknet.sol";

contract DeployDrandOracleQuicknet is Script {
    function run() external returns (DrandOracleQuicknet oracle) {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        oracle = new DrandOracleQuicknet();
        vm.stopBroadcast();
        console2.log("DrandOracleQuicknet deployed:", address(oracle));
    }
}
