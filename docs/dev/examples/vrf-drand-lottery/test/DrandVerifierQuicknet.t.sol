// SPDX-License-Identifier: VPL
pragma solidity ^0.8.34;

import {Test} from "../lib/forge-std/src/Test.sol";
import {JSONParserLib} from "../lib/solady/src/utils/JSONParserLib.sol";

import {DrandOracleQuicknet} from "../src/oracles/DrandOracleQuicknet.sol";
import {BLS2} from "../lib/bls-solidity/src/libraries/BLS2.sol";

/// @notice Foundry tests for drand quicknet signature verification.
contract DrandVerifierQuicknetTest is Test {
    using JSONParserLib for *;

    DrandOracleQuicknet internal verifier;

    // drand quicknet chain hash from official docs/API v2.
    string internal constant QUICKNET_CHAIN_HASH = "52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971";
    string internal constant QUICKNET_DRAND_API_REQUEST =
        "https://api.drand.sh/v2/chains/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971/rounds/";
    bytes32 internal constant DOMAIN_SEPARATOR = keccak256("DRAND_VERIFIER");
    uint64 internal constant QUICKNET_PERIOD_SECONDS = 3;
    uint64 internal constant QUICKNET_GENESIS_TIMESTAMP = 1692803367;

    // Quicknet vector from vendored bls-solidity testcases.json (round 20791007).
    uint64 internal constant ROUND_ONE = 20791007;
    bytes internal constant SIG_ONE_UNCOMPRESSED =
        hex"0d2c8bbc37170dbacc5e280a21d4e195cff5f32a19fd6a58633fa4e4670478b5fb39bc13dd8f8c4372c5a76191198ac50823ff37364b4060af65c7ec4dde05a428e4a444713680d95c34a4b109f112af1792643c742b75d85940c4bdcfdfbfa1";
    bytes internal constant SIG_ONE_COMPRESSED =
        hex"8d2c8bbc37170dbacc5e280a21d4e195cff5f32a19fd6a58633fa4e4670478b5fb39bc13dd8f8c4372c5a76191198ac5";

    // Second quicknet vector from vendored bls-solidity testcases.json (round 20905307).
    uint64 internal constant ROUND_TWO = 20905307;
    bytes internal constant SIG_TWO_UNCOMPRESSED =
        hex"0a60486975062d9f06633c284cf1a7b46fb343f56f329f180530ca40a9e86320244f4fbfc37ae866cf25ef499665a31f08c61b5471ed86344d6b347d1b0e1a4146877a57c28507448678d8249521d91be74cd5a44fb6fce5f869b235e085ebe6";

    uint128 internal constant FIELD_P_HI = 0x1a0111ea397fe69a4b1ba7b6434bacd7;
    uint256 internal constant FIELD_P_LO = 0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab;

    function setUp() public {
        verifier = new DrandOracleQuicknet();
    }

    function testVerifyAcceptsValidCompressedQuicknetSignature() public view {
        assertTrue(verifier.verify(ROUND_ONE, SIG_ONE_COMPRESSED));
    }

    function testVerifyAcceptsValidUncompressedQuicknetSignature() public view {
        assertTrue(verifier.verify(ROUND_ONE, SIG_ONE_UNCOMPRESSED));
    }

    function testSafeVerifyAcceptsValidCompressedQuicknetSignature() public view {
        assertTrue(verifier.safeVerify(ROUND_ONE, SIG_ONE_COMPRESSED));
    }

    function testVerifyRejectsValidSignatureWhenRoundIsWrong() public view {
        assertFalse(verifier.verify(ROUND_ONE + 1, SIG_ONE_COMPRESSED));
        assertFalse(verifier.verify(ROUND_ONE + 1, SIG_ONE_UNCOMPRESSED));
    }

    function testVerifyRejectsDifferentRoundSignature() public view {
        assertFalse(verifier.verify(ROUND_ONE, SIG_TWO_UNCOMPRESSED));
    }

    function testVerifyRejectsInvalidSignatureLength() public view {
        bytes memory invalidLengthSig = hex"1234";
        assertFalse(verifier.verify(ROUND_ONE, invalidLengthSig));
    }

    function testPublicKeyReturnsExpectedQuicknetCoordinates() public view {
        BLS2.PointG2 memory publicKey = verifier.PUBLIC_KEY();

        assertEq(publicKey.x1_hi, 0x03cf0f2896adee7eb8b5f01fcad39122);
        assertEq(publicKey.x1_lo, 0x12c437e0073e911fb90022d3e760183c8c4b450b6a0a6c3ac6a5776a2d106451);
        assertEq(publicKey.x0_hi, 0x0d1fec758c921cc22b0e17e63aaf4bcb);
        assertEq(publicKey.x0_lo, 0x5ed66304de9cf809bd274ca73bab4af5a6e9c76a4bc09e76eae8991ef5ece45a);
        assertEq(publicKey.y1_hi, 0x01a714f2edb74119a2f2b0d5a7c75ba9);
        assertEq(publicKey.y1_lo, 0x02d163700a61bc224ededd8e63aef7be1aaf8e93d7a9718b047ccddb3eb5d68b);
        assertEq(publicKey.y0_hi, 0x0e5db2b6bfbb01c867749cadffca88b3);
        assertEq(publicKey.y0_lo, 0x6c24f3012ba09fc4d3022c5c37dce0f977d3adb5d183c7477c442b1f04515273);
    }

    function testRoundMessageHashMatchesKnownQuicknetVector() public view {
        assertEq(
            verifier.roundMessageHash(ROUND_ONE), 0xeb26460c7495053b531c3d007789953c47874f3380635090554e0f68619bbbeb
        );
    }

    function testNetworkMetadataExposesQuicknetPeriodAndGenesis() public view {
        assertEq(verifier.DRAND_API_REQUEST(), QUICKNET_DRAND_API_REQUEST);
        assertEq(verifier.PERIOD_SECONDS(), QUICKNET_PERIOD_SECONDS);
        assertEq(verifier.GENESIS_TIMESTAMP(), QUICKNET_GENESIS_TIMESTAMP);
    }

    function testDeriveDrandRequestBuildsQuicknetRoundUrl() public view {
        string memory expected =
            "https://api.drand.sh/v2/chains/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971/rounds/20791007";
        assertEq(verifier.deriveDrandRequest(ROUND_ONE), expected);
    }

    function testVerifyAPIAcceptsValidQuicknetJsonPayload() public view {
        string memory apiResponse =
            '{"round":20791007,"signature":"8d2c8bbc37170dbacc5e280a21d4e195cff5f32a19fd6a58633fa4e4670478b5fb39bc13dd8f8c4372c5a76191198ac5"}';
        assertTrue(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIRejectsValidSignatureWhenRoundInJsonIsWrong() public view {
        string memory apiResponse =
            '{"round":20791008,"signature":"8d2c8bbc37170dbacc5e280a21d4e195cff5f32a19fd6a58633fa4e4670478b5fb39bc13dd8f8c4372c5a76191198ac5"}';
        assertFalse(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIReturnsFalseWhenSignatureFieldMissing() public view {
        string memory apiResponse = '{"round":20791007}';
        assertFalse(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIReturnsFalseWhenRoundFieldIsNotNumber() public view {
        string memory apiResponse =
            '{"round":"20791007","signature":"8d2c8bbc37170dbacc5e280a21d4e195cff5f32a19fd6a58633fa4e4670478b5fb39bc13dd8f8c4372c5a76191198ac5"}';
        assertFalse(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIReturnsFalseWhenSignatureFieldIsNotString() public view {
        string memory apiResponse = '{"round":20791007,"signature":12345}';
        assertFalse(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIReturnsFalseWhenSignatureHexHasInvalidHighNibbleCharacter() public view {
        string memory apiResponse =
            '{"round":20791007,"signature":"gd2c8bbc37170dbacc5e280a21d4e195cff5f32a19fd6a58633fa4e4670478b5fb39bc13dd8f8c4372c5a76191198ac5"}';
        assertFalse(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIReturnsFalseWhenSignatureHexUsesUppercaseNibbles() public view {
        string memory apiResponse =
            '{"round":20791007,"signature":"Ad2c8bbc37170dbacc5e280a21d4e195cff5f32a19fd6a58633fa4e4670478b5fb39bc13dd8f8c4372c5a76191198ac5"}';
        assertFalse(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIReturnsFalseWhenSignatureHexHasInvalidCharacter() public view {
        string memory apiResponse =
            '{"round":20791007,"signature":"8d2c8bbc37170dbacc5e280a21d4e195cff5f32a19fd6a58633fa4e4670478b5fb39bc13dd8f8c4372c5a76191198acg"}';
        assertFalse(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIReturnsFalseWhenSignatureHexHasOddLength() public view {
        string memory apiResponse =
            '{"round":20791007,"signature":"8d2c8bbc37170dbacc5e280a21d4e195cff5f32a19fd6a58633fa4e4670478b5fb39bc13dd8f8c4372c5a76191198ac"}';
        assertFalse(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIRevertsOnMalformedJson() public {
        string memory apiResponse = '{"round":20791007,"signature":"8d2c8bbc37170dbacc5e280a21d4e195"';
        vm.expectRevert(JSONParserLib.ParsingFailed.selector);
        verifier.verifyAPI(apiResponse);
    }

    function testVerifyNormalizedReturnsConsistentHashesAcrossSignatureEncodings() public view {
        (bool compressedVerified, bytes32 compressedNormalized, bytes32 compressedChainScoped) =
            verifier.verifyNormalized(ROUND_ONE, SIG_ONE_COMPRESSED);
        (bool uncompressedVerified, bytes32 uncompressedNormalized, bytes32 uncompressedChainScoped) =
            verifier.verifyNormalized(ROUND_ONE, SIG_ONE_UNCOMPRESSED);

        assertTrue(compressedVerified);
        assertTrue(uncompressedVerified);
        assertEq(compressedNormalized, uncompressedNormalized);
        assertEq(compressedChainScoped, uncompressedChainScoped);

        bytes32 expectedNormalized = keccak256(abi.encodePacked(SIG_ONE_UNCOMPRESSED, ROUND_ONE));
        bytes32 expectedChainScoped =
            keccak256(abi.encodePacked(DOMAIN_SEPARATOR, expectedNormalized, address(verifier), block.chainid));

        assertEq(compressedNormalized, expectedNormalized);
        assertEq(compressedChainScoped, expectedChainScoped);
    }

    function testVerifyNormalizedReturnsZeroHashesWhenVerificationFails() public view {
        (bool verified, bytes32 normalizedHash, bytes32 chainScopedHash) =
            verifier.verifyNormalized(ROUND_ONE + 1, SIG_ONE_COMPRESSED);

        assertFalse(verified);
        assertEq(normalizedHash, bytes32(0));
        assertEq(chainScopedHash, bytes32(0));
    }

    function testVerifyNormalizedReturnsZeroHashesForInvalidSignatureLength() public view {
        (bool verified, bytes32 normalizedHash, bytes32 chainScopedHash) =
            verifier.verifyNormalized(ROUND_ONE, hex"1234");

        assertFalse(verified);
        assertEq(normalizedHash, bytes32(0));
        assertEq(chainScopedHash, bytes32(0));
    }

    function testDecompressSignatureReturnsExpectedUncompressedBytes() public view {
        bytes memory decompressed = verifier.decompressSignature(SIG_ONE_COMPRESSED);
        assertEq(decompressed, SIG_ONE_UNCOMPRESSED);
    }

    function testBLS2UnmarshalAndUnmarshalCompressedProduceSameSignaturePoint() public view {
        bytes memory decompressed = verifier.decompressSignature(SIG_ONE_COMPRESSED);

        BLS2.PointG1 memory pointFromCompressed = BLS2.g1UnmarshalCompressed(SIG_ONE_COMPRESSED);
        BLS2.PointG1 memory pointFromUncompressed = BLS2.g1Unmarshal(decompressed);

        assertEq(pointFromCompressed.x_hi, pointFromUncompressed.x_hi);
        assertEq(pointFromCompressed.x_lo, pointFromUncompressed.x_lo);
        assertEq(pointFromCompressed.y_hi, pointFromUncompressed.y_hi);
        assertEq(pointFromCompressed.y_lo, pointFromUncompressed.y_lo);
    }

    function testDecompressSignatureRevertsOnInvalidLength() public {
        vm.expectRevert(bytes("Invalid G1 bytes length"));
        verifier.decompressSignature(hex"1234");
    }

    function testVerifyRevertsWhenCompressedEncodingBitIsMissing() public {
        bytes memory malformedCompressed = bytes(SIG_ONE_COMPRESSED);
        malformedCompressed[0] = bytes1(uint8(malformedCompressed[0]) & 0x7f);

        vm.expectRevert(bytes("Invalid G1 point: not compressed"));
        verifier.verify(ROUND_ONE, malformedCompressed);
    }

    function testSafeVerifyRejectsWhenCompressedEncodingBitIsMissing() public view {
        bytes memory malformedCompressed = bytes(SIG_ONE_COMPRESSED);
        malformedCompressed[0] = bytes1(uint8(malformedCompressed[0]) & 0x7f);

        assertFalse(verifier.safeVerify(ROUND_ONE, malformedCompressed));
    }

    function testVerifyRevertsWhenCompressedInfinityFlagIsSet() public {
        bytes memory malformedCompressed = bytes(SIG_ONE_COMPRESSED);
        malformedCompressed[0] = bytes1(uint8(malformedCompressed[0]) | 0x40);

        vm.expectRevert(bytes("unsupported: point at infinity"));
        verifier.verify(ROUND_ONE, malformedCompressed);
    }

    function testSafeVerifyRejectsWhenCompressedInfinityFlagIsSet() public view {
        bytes memory malformedCompressed = bytes(SIG_ONE_COMPRESSED);
        malformedCompressed[0] = bytes1(uint8(malformedCompressed[0]) | 0x40);

        assertFalse(verifier.safeVerify(ROUND_ONE, malformedCompressed));
    }

    function testSafeVerifyReturnsFalseWhenModexpPrecompileCallFails() public {
        vm.mockCallRevert(address(0x05), bytes4(0x00000000), bytes("mocked"));

        vm.expectRevert();
        verifier.verify(ROUND_ONE, SIG_ONE_COMPRESSED);
        assertFalse(verifier.safeVerify(ROUND_ONE, SIG_ONE_COMPRESSED));

        vm.clearMockedCalls();
    }

    function testVerifyRejectsCompressedSignatureWithSignBitFlipped() public view {
        bytes memory tampered = bytes(SIG_ONE_COMPRESSED);
        tampered[0] = bytes1(uint8(tampered[0]) ^ 0x20);

        _assertNotVerifiedOrReverted(ROUND_ONE, tampered);
    }

    function testVerifyRejectsCompressedSignatureWithNonCanonicalFieldElement() public view {
        _assertNotVerifiedOrReverted(ROUND_ONE, _compressedSignatureWithXEqualFieldPrime());
    }

    function testVerifyRejectsUncompressedSignatureWithNonCanonicalFieldElement() public view {
        _assertNotVerifiedOrReverted(ROUND_ONE, _uncompressedSignatureWithXEqualFieldPrime());
    }

    /// forge-config: default.fuzz.runs = 32
    function testFuzzVerifyDoesNotAcceptBitFlippedCompressedSignature(uint8 index, uint8 mask) public view {
        vm.assume(mask != 0);

        bytes memory tampered = bytes(SIG_ONE_COMPRESSED);
        uint256 i = bound(uint256(index), 0, tampered.length - 1);
        tampered[i] = bytes1(uint8(tampered[i]) ^ mask);

        _assertNotVerifiedOrReverted(ROUND_ONE, tampered);
    }

    /// forge-config: default.fuzz.runs = 32
    function testFuzzVerifyDoesNotAcceptBitFlippedUncompressedSignature(uint8 index, uint8 mask) public view {
        vm.assume(mask != 0);

        bytes memory tampered = bytes(SIG_ONE_UNCOMPRESSED);
        uint256 i = bound(uint256(index), 0, tampered.length - 1);
        tampered[i] = bytes1(uint8(tampered[i]) ^ mask);

        _assertNotVerifiedOrReverted(ROUND_ONE, tampered);
    }

    /// forge-config: default.fuzz.runs = 32
    function testFuzzVerifyRejectsRandomUncompressedPayload(uint64 round, bytes32 a, bytes32 b, bytes32 c) public view {
        bytes memory randomUncompressed = abi.encodePacked(a, b, c);

        bytes32 signatureHash = keccak256(randomUncompressed);
        vm.assume(!(round == ROUND_ONE && signatureHash == keccak256(SIG_ONE_UNCOMPRESSED)));
        vm.assume(!(round == ROUND_TWO && signatureHash == keccak256(SIG_TWO_UNCOMPRESSED)));

        _assertNotVerifiedOrReverted(round, randomUncompressed);
    }

    /// forge-config: default.fuzz.runs = 32
    function testFuzzVerifyRejectsRandomCompressedPayload(uint64 round, bytes32 a, bytes32 b) public view {
        bytes memory randomCompressed = abi.encodePacked(a, b);
        assembly {
            mstore(randomCompressed, 48)
        }

        vm.assume(!(round == ROUND_ONE && keccak256(randomCompressed) == keccak256(SIG_ONE_COMPRESSED)));

        _assertNotVerifiedOrReverted(round, randomCompressed);
    }

    /// @notice Fetches latest drand quicknet round over FFI, parses JSON with Solady, and verifies the live signature.
    function testVerifyAcceptsLatestLiveDrandRoundViaFFI() public {
        (uint64 round, bytes memory signature) = _fetchLatestDrandRoundFromApi();
        assertTrue(verifier.verify(round, signature));
    }

    /// @notice Verifies the latest live quicknet JSON payload directly via verifyAPI.
    function testVerifyAPIAcceptsLatestLiveDrandRoundViaFFI() public {
        string memory response = _fetchLatestDrandRoundApiResponse();
        assertTrue(verifier.verifyAPI(response));
    }

    /// @notice Confirms tampering a live drand signature causes verification failure.
    function testVerifyRejectsTamperedLatestLiveDrandRoundViaFFI() public {
        (uint64 round, bytes memory signature) = _fetchLatestDrandRoundFromApi();
        signature[0] = bytes1(uint8(signature[0]) ^ 0x01);
        assertFalse(verifier.verify(round, signature));
    }

    function _fetchLatestDrandRoundFromApi() internal returns (uint64 round, bytes memory signature) {
        string memory apiResponse = _fetchLatestDrandRoundApiResponse();
        JSONParserLib.Item memory root = apiResponse.parse();

        round = uint64(JSONParserLib.parseUint(root.at('"round"').value()));

        // The API returns signature as a JSON string without 0x; decode and prefix for vm.parseBytes.
        string memory signatureHex = JSONParserLib.decodeString(root.at('"signature"').value());
        signature = vm.parseBytes(string.concat("0x", signatureHex));
    }

    function _fetchLatestDrandRoundApiResponse() internal returns (string memory) {
        string[] memory command = new string[](3);
        command[0] = "curl";
        command[1] = "-fsSL";
        command[2] = string.concat("https://api.drand.sh/v2/chains/", QUICKNET_CHAIN_HASH, "/rounds/latest");

        bytes memory response = vm.ffi(command);
        return string(response);
    }

    function _assertNotVerifiedOrReverted(uint64 round, bytes memory signature) internal view {
        (bool success, bytes memory returnData) =
            address(verifier).staticcall(abi.encodeCall(DrandOracleQuicknet.verify, (round, signature)));

        if (success) {
            assertFalse(abi.decode(returnData, (bool)));
        }
    }

    function _compressedSignatureWithXEqualFieldPrime() internal pure returns (bytes memory signature) {
        signature = new bytes(48);
        uint128 xHiWithCompressedFlag = FIELD_P_HI | 0x80000000000000000000000000000000;

        assembly {
            mstore(add(signature, 0x20), shl(128, xHiWithCompressedFlag))
            mstore(add(signature, 0x30), FIELD_P_LO)
        }
    }

    function _uncompressedSignatureWithXEqualFieldPrime() internal pure returns (bytes memory signature) {
        signature = new bytes(96);
        uint128 yHi = 0;
        uint256 yLo = 2;

        assembly {
            mstore(add(signature, 0x20), shl(128, FIELD_P_HI))
            mstore(add(signature, 0x30), FIELD_P_LO)
            mstore(add(signature, 0x50), shl(128, yHi))
            mstore(add(signature, 0x60), yLo)
        }
    }
}
