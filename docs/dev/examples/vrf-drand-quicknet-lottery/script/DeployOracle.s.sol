// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Script, console2} from "forge-std/Script.sol";
import {DrandOracleQuicknet} from "drand-verifier/oracles/DrandOracleQuicknet.sol";

/// @notice Deploys DrandOracleQuicknet (stateless BLS12-381 verifier).
/// @dev    Required env: PRIVATE_KEY
///
///         The upstream DrandVerifier repo does not ship a deploy script, so this
///         one is duplicated here to keep the demo self-contained. Run this once
///         per chain (or reuse an existing deployment) before DeployLottery.s.sol.
///
///         Target chain MUST support EIP-2537 BLS12-381 precompiles (Pectra / Isthmus).
contract DeployOracle is Script {
    function run() external returns (DrandOracleQuicknet oracle) {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        oracle = new DrandOracleQuicknet();
        vm.stopBroadcast();

        console2.log("DrandOracleQuicknet deployed:", address(oracle));
    }
}
