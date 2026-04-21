// SPDX-License-Identifier: VPL
pragma solidity ^0.8.34;

import {LibHex} from "../utils/LibHex.sol";
import {LibString} from "../../lib/solady/src/utils/LibString.sol";
import {BLS2} from "../../lib/bls-solidity/src/libraries/BLS2.sol";
import {JSONParserLib} from "../../lib/solady/src/utils/JSONParserLib.sol";

/// @title DrandVerifierQuicknet
/// @notice Internal verifier library for drand quicknet BLS12-381 signatures.
/// @dev Supports drand signatures encoded either as compressed G1 (48 bytes) or uncompressed G1 (96 bytes).
library DrandVerifierQuicknet {
    using LibString for uint256;
    using JSONParserLib for *;

    /// @notice Domain separation tag used by drand quicknet for hash-to-curve.
    string internal constant DST = "BLS_SIG_BLS12381G1_XMD:SHA-256_SSWU_RO_NUL_";

    /// @notice Quicknet beacon period in seconds.
    uint64 internal constant PERIOD_SECONDS = 3 seconds;

    /// @notice Quicknet genesis Unix timestamp.
    uint64 internal constant GENESIS_TIMESTAMP = 1692803367;

    /// @notice Expected compressed G1 signature length in bytes.
    uint256 internal constant COMPRESSED_G1_SIG_LENGTH = 48;

    /// @notice Expected uncompressed G1 signature length in bytes.
    uint256 internal constant UNCOMPRESSED_G1_SIG_LENGTH = 96;

    /// @notice Base drand API request URL for quicknet rounds.
    string internal constant DRAND_API_REQUEST =
        "https://api.drand.sh/v2/chains/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971/rounds/";

    /// @notice Domain separator for chain-scoped normalized random values.
    bytes32 internal constant DOMAIN_SEPARATOR = keccak256("DRAND_VERIFIER");

    /// @notice Returns drand quicknet public key in G2 form.
    /// @dev Matches the quicknet key used by bls-solidity's QuicknetRegistry demo.
    function PUBLIC_KEY() internal pure returns (BLS2.PointG2 memory) {
        return BLS2.PointG2(
            0x03cf0f2896adee7eb8b5f01fcad39122,
            0x12c437e0073e911fb90022d3e760183c8c4b450b6a0a6c3ac6a5776a2d106451,
            0x0d1fec758c921cc22b0e17e63aaf4bcb,
            0x5ed66304de9cf809bd274ca73bab4af5a6e9c76a4bc09e76eae8991ef5ece45a,
            0x01a714f2edb74119a2f2b0d5a7c75ba9,
            0x02d163700a61bc224ededd8e63aef7be1aaf8e93d7a9718b047ccddb3eb5d68b,
            0x0e5db2b6bfbb01c867749cadffca88b3,
            0x6c24f3012ba09fc4d3022c5c37dce0f977d3adb5d183c7477c442b1f04515273
        );
    }

    /// @notice Computes the quicknet round message hash.
    /// @dev Quicknet uses sha256 over uint64 round encoded as 8-byte big-endian via abi.encodePacked.
    function roundMessageHash(uint64 round) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(round));
    }

    /// @notice Derives the drand HTTP API request URL for a specific quicknet round.
    /// @dev Uses explicit quicknet chain-hash addressing on API v2.
    function deriveDrandRequest(uint64 round) internal pure returns (string memory) {
        return string.concat(DRAND_API_REQUEST, uint256(round).toString());
    }

    /// @notice Decompresses a 48-byte compressed BLS12-381 G1 signature to 96-byte uncompressed form.
    /// @dev Intended for offchain eth_call usage so callers can submit uncompressed signatures to save onchain gas.
    /// Reverts for invalid compressed encodings.
    /// @param compressedSig The compressed signature bytes.
    /// @return The uncompressed signature bytes.
    function decompressSignature(bytes memory compressedSig) internal view returns (bytes memory) {
        return BLS2.g1Marshal(BLS2.g1UnmarshalCompressed(compressedSig));
    }

    /// @notice Decodes a raw drand quicknet JSON API response.
    /// @dev Expects a JSON object containing `round` and hex `signature` fields.
    function decodeAPIResponse(string memory response) internal pure returns (bool, uint64, bytes memory) {
        JSONParserLib.Item memory root = response.parse();
        JSONParserLib.Item memory roundItem = root.at('"round"');
        JSONParserLib.Item memory signatureItem = root.at('"signature"');

        if (roundItem.isUndefined() || signatureItem.isUndefined()) return (false, 0, bytes(""));
        if (!roundItem.isNumber() || !signatureItem.isString()) return (false, 0, bytes(""));

        uint64 round = uint64(JSONParserLib.parseUint(roundItem.value()));
        string memory signatureHex = JSONParserLib.decodeString(signatureItem.value());

        (bool decoded, bytes memory signature) = LibHex._tryDecodeHex(signatureHex);
        if (!decoded) return (false, 0, bytes(""));

        return (true, round, signature);
    }

    /// @notice Verifies a drand quicknet signature for a given round.
    /// @param round The drand round number.
    /// @param sig The current round signature bytes in compressed (48) or uncompressed (96) G1 form.
    /// @return True when the signature is valid for the provided round and quicknet public key.
    function verify(uint64 round, bytes memory sig) internal view returns (bool) {
        BLS2.PointG1 memory signaturePoint;
        uint256 signatureLength = sig.length;

        if (signatureLength == UNCOMPRESSED_G1_SIG_LENGTH) {
            signaturePoint = BLS2.g1Unmarshal(sig);
        } else if (signatureLength == COMPRESSED_G1_SIG_LENGTH) {
            signaturePoint = BLS2.g1UnmarshalCompressed(sig);
        } else {
            return false;
        }

        BLS2.PointG1 memory messagePoint = BLS2.hashToPoint(bytes(DST), abi.encodePacked(roundMessageHash(round)));

        (bool pairingSuccess, bool callSuccess) = BLS2.verifySingle(signaturePoint, PUBLIC_KEY(), messagePoint);
        return pairingSuccess && callSuccess;
    }

    /// @notice Verifies signature and derives encoding-invariant random outputs.
    /// @dev Returns `(verified, normalizedRoundHash, chainScopedHash)` where:
    /// - `normalizedRoundHash = keccak256(canonicalG1SignaturePoint || round)`
    /// - `chainScopedHash = keccak256(DOMAIN_SEPARATOR || normalizedRoundHash || address(this) || block.chainid)`
    function verifyNormalized(uint64 round, bytes memory sig) internal view returns (bool, bytes32, bytes32) {
        uint256 signatureLength = sig.length;
        if (signatureLength != COMPRESSED_G1_SIG_LENGTH && signatureLength != UNCOMPRESSED_G1_SIG_LENGTH) {
            return (false, bytes32(0), bytes32(0));
        }

        bool verified = verify(round, sig);
        if (!verified) return (false, bytes32(0), bytes32(0));

        BLS2.PointG1 memory signaturePoint =
            signatureLength == UNCOMPRESSED_G1_SIG_LENGTH ? BLS2.g1Unmarshal(sig) : BLS2.g1UnmarshalCompressed(sig);

        bytes32 normalizedRoundHash = keccak256(abi.encodePacked(BLS2.g1Marshal(signaturePoint), round));
        bytes32 chainScopedHash =
            keccak256(abi.encodePacked(DOMAIN_SEPARATOR, normalizedRoundHash, address(this), block.chainid));

        return (true, normalizedRoundHash, chainScopedHash);
    }
}
