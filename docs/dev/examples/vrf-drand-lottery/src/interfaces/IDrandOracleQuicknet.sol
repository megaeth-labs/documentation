// SPDX-License-Identifier: VPL
pragma solidity ^0.8.34;

import {BLS2} from "../../lib/bls-solidity/src/libraries/BLS2.sol";

/// @title IDrandOracleQuicknet
/// @notice Interface for the deployable drand quicknet oracle contract.
interface IDrandOracleQuicknet {
    function DST() external pure returns (string memory);
    function DRAND_API_REQUEST() external pure returns (string memory);
    function COMPRESSED_G1_SIG_LENGTH() external pure returns (uint256);
    function UNCOMPRESSED_G1_SIG_LENGTH() external pure returns (uint256);
    function PERIOD_SECONDS() external pure returns (uint64);
    function GENESIS_TIMESTAMP() external pure returns (uint64);
    function PUBLIC_KEY() external pure returns (BLS2.PointG2 memory);

    function roundMessageHash(uint64 round) external pure returns (bytes32);
    function deriveDrandRequest(uint64 round) external view returns (string memory);
    function decompressSignature(bytes calldata compressedSig) external view returns (bytes memory);

    function verify(uint64 round, bytes calldata sig) external view returns (bool);
    function safeVerify(uint64 round, bytes calldata sig) external view returns (bool);
    function verifyAPI(string calldata response) external view returns (bool);
    function verifyNormalized(uint64 round, bytes calldata sig) external view returns (bool, bytes32, bytes32);
}
