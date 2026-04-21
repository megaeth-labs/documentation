// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Script, console2} from "forge-std/Script.sol";
import {DrandLottery} from "../src/DrandLottery.sol";
import {IDrandOracleQuicknet} from "drand-verifier/interfaces/IDrandOracleQuicknet.sol";

/// @notice Deploys DrandLottery pointing at a pre-deployed DrandOracleQuicknet.
/// @dev    Required env:
///           PRIVATE_KEY    - deployer key
///           ORACLE_ADDRESS - address of the already-deployed DrandOracleQuicknet
contract DeployLottery is Script {
    function run() external returns (DrandLottery lottery) {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address oracle = vm.envAddress("ORACLE_ADDRESS");

        vm.startBroadcast(pk);
        lottery = new DrandLottery(IDrandOracleQuicknet(oracle));
        vm.stopBroadcast();

        console2.log("DrandLottery deployed:", address(lottery));
        console2.log("Wired to oracle     :", oracle);
    }
}
