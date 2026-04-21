// SPDX-License-Identifier: VPL
pragma solidity ^0.8.34;

import {BLS2} from "../../lib/bls-solidity/src/libraries/BLS2.sol";
import {IDrandOracleQuicknet} from "../interfaces/IDrandOracleQuicknet.sol";
import {DrandVerifierQuicknet} from "../verifiers/DrandVerifierQuicknet.sol";

/// @title DrandOracleQuicknet
/// @notice Deployable oracle contract for drand quicknet verification.
contract DrandOracleQuicknet is IDrandOracleQuicknet {
    string public constant DST = "BLS_SIG_BLS12381G1_XMD:SHA-256_SSWU_RO_NUL_";
    string public constant DRAND_API_REQUEST =
        "https://api.drand.sh/v2/chains/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971/rounds/";
    uint64 public constant PERIOD_SECONDS = 3 seconds;
    uint64 public constant GENESIS_TIMESTAMP = 1692803367;
    uint256 public constant COMPRESSED_G1_SIG_LENGTH = 48;
    uint256 public constant UNCOMPRESSED_G1_SIG_LENGTH = 96;

    function PUBLIC_KEY() public pure override returns (BLS2.PointG2 memory) {
        return DrandVerifierQuicknet.PUBLIC_KEY();
    }

    function roundMessageHash(uint64 round) public pure override returns (bytes32) {
        return DrandVerifierQuicknet.roundMessageHash(round);
    }

    function deriveDrandRequest(uint64 round) public pure override returns (string memory) {
        return DrandVerifierQuicknet.deriveDrandRequest(round);
    }

    function decompressSignature(bytes calldata compressedSig) external view override returns (bytes memory) {
        return DrandVerifierQuicknet.decompressSignature(compressedSig);
    }

    function verify(uint64 round, bytes calldata sig) public view override returns (bool) {
        return DrandVerifierQuicknet.verify(round, sig);
    }

    function safeVerify(uint64 round, bytes memory sig) public view override returns (bool) {
        try this.verify(round, sig) returns (bool verified) {
            return verified;
        } catch {
            return false;
        }
    }

    function verifyAPI(string calldata response) public view override returns (bool) {
        (bool decoded, uint64 round, bytes memory signature) = DrandVerifierQuicknet.decodeAPIResponse(response);
        if (!decoded) return false;
        return safeVerify(round, signature);
    }

    function verifyNormalized(uint64 round, bytes calldata sig) public view override returns (bool, bytes32, bytes32) {
        return DrandVerifierQuicknet.verifyNormalized(round, sig);
    }
}
