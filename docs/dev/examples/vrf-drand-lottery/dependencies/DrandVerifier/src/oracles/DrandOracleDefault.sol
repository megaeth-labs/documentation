// SPDX-License-Identifier: VPL
pragma solidity ^0.8.34;

import {BLS2} from "../../lib/bls-solidity/src/libraries/BLS2.sol";
import {IDrandOracleDefault} from "../interfaces/IDrandOracleDefault.sol";
import {DrandVerifierDefault} from "../verifiers/DrandVerifierDefault.sol";

/// @title DrandOracleDefault
/// @notice Deployable oracle contract for drand default network verification.
contract DrandOracleDefault is IDrandOracleDefault {
    string public constant DST = "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_";
    string public constant DRAND_API_REQUEST =
        "https://api.drand.sh/v2/chains/8990e7a9aaed2ffed73dbd7092123d6f289930540d7651336225dc172e51b2ce/rounds/";
    uint64 public constant PERIOD_SECONDS = 30 seconds;
    uint64 public constant GENESIS_TIMESTAMP = 1595431050;
    uint256 public constant COMPRESSED_G2_SIG_LENGTH = 96;
    uint256 public constant UNCOMPRESSED_G2_SIG_LENGTH = 192;

    function PUBLIC_KEY() public pure override returns (BLS2.PointG1 memory) {
        return DrandVerifierDefault.PUBLIC_KEY();
    }

    function roundMessageHash(uint64 round, bytes calldata previousSignature) public pure override returns (bytes32) {
        return DrandVerifierDefault.roundMessageHash(round, previousSignature);
    }

    function deriveDrandRequest(uint64 round) public pure override returns (string memory) {
        return DrandVerifierDefault.deriveDrandRequest(round);
    }

    function decompressSignature(bytes calldata compressedSig) external view override returns (bytes memory) {
        return DrandVerifierDefault.decompressSignature(compressedSig);
    }

    function verify(uint64 round, bytes calldata previousSignature, bytes calldata signature)
        public
        view
        override
        returns (bool)
    {
        return DrandVerifierDefault.verify(round, previousSignature, signature);
    }

    function safeVerify(uint64 round, bytes memory previousSignature, bytes memory signature)
        public
        view
        override
        returns (bool)
    {
        try this.verify(round, previousSignature, signature) returns (bool verified) {
            return verified;
        } catch {
            return false;
        }
    }

    function verifyAPI(string calldata response) public view override returns (bool) {
        (bool decoded, uint64 round, bytes memory previousSignature, bytes memory signature) =
            DrandVerifierDefault.decodeAPIResponse(response);
        if (!decoded) return false;
        return safeVerify(round, previousSignature, signature);
    }

    function verifyNormalized(uint64 round, bytes calldata previousSignature, bytes calldata signature)
        public
        view
        override
        returns (bool, bytes32, bytes32)
    {
        return DrandVerifierDefault.verifyNormalized(round, previousSignature, signature);
    }
}
