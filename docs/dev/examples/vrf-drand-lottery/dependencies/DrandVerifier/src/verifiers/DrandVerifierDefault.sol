// SPDX-License-Identifier: VPL
pragma solidity ^0.8.34;

import {LibBLS} from "../utils/LibBLS.sol";
import {LibHex} from "../utils/LibHex.sol";
import {LibString} from "../../lib/solady/src/utils/LibString.sol";
import {BLS2} from "../../lib/bls-solidity/src/libraries/BLS2.sol";
import {JSONParserLib} from "../../lib/solady/src/utils/JSONParserLib.sol";

/// @title DrandVerifierDefault
/// @notice Internal verifier library for drand default network (pedersen-bls-chained) BLS12-381 signatures.
/// @dev drand default network uses signatures on G2, public key on G1, and chained digest:
///      sha256(previous_signature || uint64(round) big-endian).
library DrandVerifierDefault {
    using LibString for uint256;
    using JSONParserLib for *;

    /// @notice Domain separation tag used by drand default network for hash-to-curve.
    string internal constant DST = "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_";

    /// @notice Default network beacon period in seconds.
    uint64 internal constant PERIOD_SECONDS = 30 seconds;

    /// @notice Default network genesis Unix timestamp.
    uint64 internal constant GENESIS_TIMESTAMP = 1595431050;

    /// @notice Expected compressed G2 signature length in bytes.
    uint256 internal constant COMPRESSED_G2_SIG_LENGTH = 96;

    /// @notice Expected uncompressed G2 signature length in bytes.
    uint256 internal constant UNCOMPRESSED_G2_SIG_LENGTH = 192;

    /// @notice Base drand API request URL for default-network rounds.
    string internal constant DRAND_API_REQUEST =
        "https://api.drand.sh/v2/chains/8990e7a9aaed2ffed73dbd7092123d6f289930540d7651336225dc172e51b2ce/rounds/";

    /// @notice Domain separator for chain-scoped normalized random values.
    bytes32 internal constant DOMAIN_SEPARATOR = keccak256("DRAND_VERIFIER");

    /// @notice Returns drand default network public key in G1 form.
    function PUBLIC_KEY() internal pure returns (BLS2.PointG1 memory) {
        return BLS2.PointG1(
            0x068f005eb8e6e4ca0a47c8a77ceaa530,
            0x9a47978a7c71bc5cce96366b5d7a569937c529eeda66c7293784a9402801af31,
            0x026fa5eef143aaa17c53b3c150d96a18,
            0x051b718531af576803cfb9acf29b8774a8184e63c62da81ddf4d76fb0a65895c
        );
    }

    /// @notice Computes chained drand message digest for default network.
    /// @dev Digest is sha256(previous_signature || uint64(round) big-endian).
    function roundMessageHash(uint64 round, bytes memory previousSignature) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(previousSignature, round));
    }

    /// @notice Derives the drand HTTP API request URL for a specific default network round.
    /// @dev Uses explicit default chain-hash addressing on API v2.
    function deriveDrandRequest(uint64 round) internal pure returns (string memory) {
        return string.concat(DRAND_API_REQUEST, uint256(round).toString());
    }

    /// @notice Decompresses a 96-byte compressed BLS12-381 G2 signature to 192-byte uncompressed form.
    /// @dev Intended for offchain eth_call usage so callers can submit uncompressed signatures to save onchain gas.
    /// Reverts for invalid compressed encodings.
    /// @param compressedSig The compressed signature bytes.
    /// @return The uncompressed signature bytes.
    function decompressSignature(bytes memory compressedSig) internal view returns (bytes memory) {
        return LibBLS.decompressG2Signature(compressedSig);
    }

    /// @notice Decodes a raw drand default network JSON API response.
    /// @dev Expects a JSON object containing `round`, `previous_signature`, and hex `signature` fields.
    function decodeAPIResponse(string memory response)
        internal
        pure
        returns (bool, uint64, bytes memory, bytes memory)
    {
        JSONParserLib.Item memory root = response.parse();
        JSONParserLib.Item memory roundItem = root.at('"round"');
        JSONParserLib.Item memory previousItem = root.at('"previous_signature"');
        JSONParserLib.Item memory signatureItem = root.at('"signature"');

        if (roundItem.isUndefined() || previousItem.isUndefined() || signatureItem.isUndefined()) {
            return (false, 0, bytes(""), bytes(""));
        }
        if (!roundItem.isNumber() || !previousItem.isString() || !signatureItem.isString()) {
            return (false, 0, bytes(""), bytes(""));
        }

        uint64 round = uint64(JSONParserLib.parseUint(roundItem.value()));
        string memory previousHex = JSONParserLib.decodeString(previousItem.value());
        string memory signatureHex = JSONParserLib.decodeString(signatureItem.value());

        (bool previousDecoded, bytes memory previousSignature) = LibHex._tryDecodeHex(previousHex);
        if (!previousDecoded) return (false, 0, bytes(""), bytes(""));
        (bool signatureDecoded, bytes memory signature) = LibHex._tryDecodeHex(signatureHex);
        if (!signatureDecoded) return (false, 0, bytes(""), bytes(""));

        return (true, round, previousSignature, signature);
    }

    /// @notice Verifies a drand default network signature for a round and previous signature.
    /// @param round The drand round number.
    /// @param previousSig The previous round signature bytes from drand beacon payload.
    /// @param sig The current round signature bytes in compressed (96) or uncompressed (192) G2 form.
    function verify(uint64 round, bytes memory previousSig, bytes memory sig) internal view returns (bool) {
        if (previousSig.length != COMPRESSED_G2_SIG_LENGTH) return false;

        bytes32 digest = roundMessageHash(round, previousSig);
        return LibBLS.verifyDefaultSignature(sig, PUBLIC_KEY(), bytes(DST), digest);
    }

    /// @notice Verifies signature and derives encoding-invariant random outputs.
    /// @dev Returns `(verified, normalizedRoundHash, chainScopedHash)` where:
    /// - `normalizedRoundHash = keccak256(canonicalG2SignaturePoint || round)`
    /// - `chainScopedHash = keccak256(DOMAIN_SEPARATOR || normalizedRoundHash || address(this) || block.chainid)`
    function verifyNormalized(uint64 round, bytes memory previousSig, bytes memory sig)
        internal
        view
        returns (bool, bytes32, bytes32)
    {
        uint256 signatureLength = sig.length;
        if (signatureLength != COMPRESSED_G2_SIG_LENGTH && signatureLength != UNCOMPRESSED_G2_SIG_LENGTH) {
            return (false, bytes32(0), bytes32(0));
        }

        bool verified = verify(round, previousSig, sig);
        if (!verified) return (false, bytes32(0), bytes32(0));

        BLS2.PointG2 memory signaturePoint = signatureLength == UNCOMPRESSED_G2_SIG_LENGTH
            ? BLS2.g2Unmarshal(sig)
            : BLS2.g2Unmarshal(LibBLS.decompressG2Signature(sig));

        bytes32 normalizedRoundHash = keccak256(abi.encodePacked(BLS2.g2Marshal(signaturePoint), round));
        bytes32 chainScopedHash =
            keccak256(abi.encodePacked(DOMAIN_SEPARATOR, normalizedRoundHash, address(this), block.chainid));

        return (true, normalizedRoundHash, chainScopedHash);
    }
}
