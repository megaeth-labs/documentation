// SPDX-License-Identifier: VPL
pragma solidity ^0.8.34;

import {Test} from "../lib/forge-std/src/Test.sol";
import {JSONParserLib} from "../lib/solady/src/utils/JSONParserLib.sol";

import {DrandOracleDefault} from "../src/oracles/DrandOracleDefault.sol";
import {BLS2} from "../lib/bls-solidity/src/libraries/BLS2.sol";

/// @notice Foundry tests for drand default network signature verification.
contract DrandVerifierDefaultTest is Test {
    using JSONParserLib for *;

    DrandOracleDefault internal verifier;

    string internal constant DEFAULT_CHAIN_HASH = "8990e7a9aaed2ffed73dbd7092123d6f289930540d7651336225dc172e51b2ce";
    string internal constant DEFAULT_DRAND_API_REQUEST =
        "https://api.drand.sh/v2/chains/8990e7a9aaed2ffed73dbd7092123d6f289930540d7651336225dc172e51b2ce/rounds/";
    bytes32 internal constant DOMAIN_SEPARATOR = keccak256("DRAND_VERIFIER");
    uint64 internal constant DEFAULT_PERIOD_SECONDS = 30;
    uint64 internal constant DEFAULT_GENESIS_TIMESTAMP = 1595431050;

    uint64 internal constant ROUND_ONE = 5997160;
    bytes internal constant PREV_SIG_ONE_COMPRESSED =
        hex"8e7aa8858ef2bea93d8ef4070dfe61b812a1f627723774f5516caf2f281039b21f315dedcb949a16ccf02476fc7c0ce909f4d37fbc46736c5ad5c9c2594fa92569ed0b86c9d131e4857f65294b1a7497d00a51eda1f0e83297c162ce642f7409";
    bytes internal constant SIG_ONE_COMPRESSED =
        hex"a10b5b313e7b86a17a7007cb20efd71859f9013dca2103e577e6592f44a2ef99e5911a55c81451713177744273f8ad170b5362d3dc75a50aaf7d93215e370cdf875da83f5aedaf9c2dc0a9492672f7865314df86999deb706ce08a0c5bd63598";
    bytes internal constant SIG_ONE_UNCOMPRESSED =
        hex"010b5b313e7b86a17a7007cb20efd71859f9013dca2103e577e6592f44a2ef99e5911a55c81451713177744273f8ad170b5362d3dc75a50aaf7d93215e370cdf875da83f5aedaf9c2dc0a9492672f7865314df86999deb706ce08a0c5bd635980f9a1d326c1c9c4febdd6c9c0b3c1fa7d76ecdc2ded95077b9c2fe3a39f100860cbd5d9ed9a58fec9653a551bc41c41d08624c6799d867638a3f7418e2119bcd9c68ad3602b85d51f45e9601e8221647d7745dba9528c2caff050ce5557224e1";

    uint64 internal constant ROUND_TWO = 5997161;
    bytes internal constant PREV_SIG_TWO_COMPRESSED =
        hex"a10b5b313e7b86a17a7007cb20efd71859f9013dca2103e577e6592f44a2ef99e5911a55c81451713177744273f8ad170b5362d3dc75a50aaf7d93215e370cdf875da83f5aedaf9c2dc0a9492672f7865314df86999deb706ce08a0c5bd63598";
    bytes internal constant SIG_TWO_COMPRESSED =
        hex"995ea514d3b495c018c66e53f90fbe7f6e5873d0c0c4be20590fe02b607f6613de7f8baaa47681c1bd16715cf1366bad0c1c3519e792767cf83aa2b7dd8d934ed449388e969572e012e7335af08a165080ebbc67449f1e5b9e6afb8f0dfa1045";
    bytes internal constant SIG_TWO_UNCOMPRESSED =
        hex"195ea514d3b495c018c66e53f90fbe7f6e5873d0c0c4be20590fe02b607f6613de7f8baaa47681c1bd16715cf1366bad0c1c3519e792767cf83aa2b7dd8d934ed449388e969572e012e7335af08a165080ebbc67449f1e5b9e6afb8f0dfa1045097e27ed7a8b89e5bf450c1632423d1753d579d5e0ef85b10c2825afafdb589e1b4062fc75dc9c41f8c01932aa5f0bd0154e72d7d619a5318f437ab53604674a478141abf87ff8f0c1aa2c7da4d42a5049cef096a07216713967040a00fd565f";

    uint128 internal constant FIELD_P_HI = 0x1a0111ea397fe69a4b1ba7b6434bacd7;
    uint256 internal constant FIELD_P_LO = 0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab;

    function setUp() public {
        verifier = new DrandOracleDefault();
    }

    function testVerifyAcceptsKnownDefaultNetworkUncompressedSignatureRoundOne() public view {
        assertTrue(verifier.verify(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, SIG_ONE_UNCOMPRESSED));
    }

    function testVerifyAcceptsKnownDefaultNetworkCompressedSignatureRoundOne() public view {
        assertTrue(verifier.verify(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, SIG_ONE_COMPRESSED));
    }

    function testSafeVerifyAcceptsKnownDefaultNetworkCompressedSignatureRoundOne() public view {
        assertTrue(verifier.safeVerify(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, SIG_ONE_COMPRESSED));
    }

    function testVerifyAcceptsKnownDefaultNetworkUncompressedSignatureRoundTwo() public view {
        assertTrue(verifier.verify(ROUND_TWO, PREV_SIG_TWO_COMPRESSED, SIG_TWO_UNCOMPRESSED));
    }

    function testVerifyAcceptsKnownDefaultNetworkCompressedSignatureRoundTwo() public view {
        assertTrue(verifier.verify(ROUND_TWO, PREV_SIG_TWO_COMPRESSED, SIG_TWO_COMPRESSED));
    }

    function testVerifyRejectsValidSignatureWhenRoundIsWrong() public view {
        assertFalse(verifier.verify(ROUND_ONE + 1, PREV_SIG_ONE_COMPRESSED, SIG_ONE_UNCOMPRESSED));
    }

    function testVerifyRejectsDifferentRoundSignature() public view {
        assertFalse(verifier.verify(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, SIG_TWO_UNCOMPRESSED));
    }

    function testVerifyRejectsKnownSignatureWhenPreviousSignatureIsWrong() public view {
        bytes memory tamperedPrev = bytes(PREV_SIG_ONE_COMPRESSED);
        tamperedPrev[0] = bytes1(uint8(tamperedPrev[0]) ^ 0x01);

        assertFalse(verifier.verify(ROUND_ONE, tamperedPrev, SIG_ONE_UNCOMPRESSED));
        assertFalse(verifier.verify(ROUND_ONE, tamperedPrev, SIG_ONE_COMPRESSED));
    }

    function testVerifyRejectsInvalidSignatureLength() public view {
        bytes memory invalidLengthSig = hex"1234";
        assertFalse(verifier.verify(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, invalidLengthSig));
    }

    function testVerifyRejectsPreviousSignatureWithInvalidLength() public view {
        bytes memory tooShortPrevious = bytes(PREV_SIG_ONE_COMPRESSED);
        assembly {
            mstore(tooShortPrevious, 95)
        }

        bytes memory tooLongPrevious = bytes.concat(PREV_SIG_ONE_COMPRESSED, bytes1(0x00));

        assertFalse(verifier.verify(ROUND_ONE, tooShortPrevious, SIG_ONE_COMPRESSED));
        assertFalse(verifier.verify(ROUND_ONE, tooLongPrevious, SIG_ONE_COMPRESSED));
        assertFalse(verifier.safeVerify(ROUND_ONE, tooShortPrevious, SIG_ONE_COMPRESSED));
        assertFalse(verifier.safeVerify(ROUND_ONE, tooLongPrevious, SIG_ONE_COMPRESSED));
    }

    function testPublicKeyReturnsExpectedDefaultCoordinates() public view {
        BLS2.PointG1 memory publicKey = verifier.PUBLIC_KEY();

        assertEq(publicKey.x_hi, 0x068f005eb8e6e4ca0a47c8a77ceaa530);
        assertEq(publicKey.x_lo, 0x9a47978a7c71bc5cce96366b5d7a569937c529eeda66c7293784a9402801af31);
        assertEq(publicKey.y_hi, 0x026fa5eef143aaa17c53b3c150d96a18);
        assertEq(publicKey.y_lo, 0x051b718531af576803cfb9acf29b8774a8184e63c62da81ddf4d76fb0a65895c);
    }

    function testRoundMessageHashMatchesKnownDefaultVector() public view {
        assertEq(
            verifier.roundMessageHash(ROUND_ONE, PREV_SIG_ONE_COMPRESSED),
            0xa8b50e95a8aa82f80576670c03e42c20f98401bcc92ab35feed94ce3afcf7930
        );
    }

    function testRoundMessageHashMatchesSecondKnownDefaultVector() public view {
        assertEq(
            verifier.roundMessageHash(ROUND_TWO, PREV_SIG_TWO_COMPRESSED),
            0x2f85f37a934d1b91e2940221170a0963383403953995a526cd89716740e90fda
        );
    }

    function testNetworkMetadataExposesDefaultPeriodAndGenesis() public view {
        assertEq(verifier.DRAND_API_REQUEST(), DEFAULT_DRAND_API_REQUEST);
        assertEq(verifier.PERIOD_SECONDS(), DEFAULT_PERIOD_SECONDS);
        assertEq(verifier.GENESIS_TIMESTAMP(), DEFAULT_GENESIS_TIMESTAMP);
    }

    function testDeriveDrandRequestBuildsDefaultRoundUrl() public view {
        string memory expected =
            "https://api.drand.sh/v2/chains/8990e7a9aaed2ffed73dbd7092123d6f289930540d7651336225dc172e51b2ce/rounds/5997160";
        assertEq(verifier.deriveDrandRequest(ROUND_ONE), expected);
    }

    function testVerifyAPIAcceptsValidDefaultJsonPayload() public view {
        string memory apiResponse =
            '{"round":5997160,"previous_signature":"8e7aa8858ef2bea93d8ef4070dfe61b812a1f627723774f5516caf2f281039b21f315dedcb949a16ccf02476fc7c0ce909f4d37fbc46736c5ad5c9c2594fa92569ed0b86c9d131e4857f65294b1a7497d00a51eda1f0e83297c162ce642f7409","signature":"a10b5b313e7b86a17a7007cb20efd71859f9013dca2103e577e6592f44a2ef99e5911a55c81451713177744273f8ad170b5362d3dc75a50aaf7d93215e370cdf875da83f5aedaf9c2dc0a9492672f7865314df86999deb706ce08a0c5bd63598"}';
        assertTrue(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIRejectsValidSignatureWhenRoundInJsonIsWrong() public view {
        string memory apiResponse =
            '{"round":5997161,"previous_signature":"8e7aa8858ef2bea93d8ef4070dfe61b812a1f627723774f5516caf2f281039b21f315dedcb949a16ccf02476fc7c0ce909f4d37fbc46736c5ad5c9c2594fa92569ed0b86c9d131e4857f65294b1a7497d00a51eda1f0e83297c162ce642f7409","signature":"a10b5b313e7b86a17a7007cb20efd71859f9013dca2103e577e6592f44a2ef99e5911a55c81451713177744273f8ad170b5362d3dc75a50aaf7d93215e370cdf875da83f5aedaf9c2dc0a9492672f7865314df86999deb706ce08a0c5bd63598"}';
        assertFalse(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIReturnsFalseWhenPreviousSignatureFieldMissing() public view {
        string memory apiResponse =
            '{"round":5997160,"signature":"a10b5b313e7b86a17a7007cb20efd71859f9013dca2103e577e6592f44a2ef99e5911a55c81451713177744273f8ad170b5362d3dc75a50aaf7d93215e370cdf875da83f5aedaf9c2dc0a9492672f7865314df86999deb706ce08a0c5bd63598"}';
        assertFalse(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIReturnsFalseWhenRoundFieldIsNotNumber() public view {
        string memory apiResponse =
            '{"round":"5997160","previous_signature":"8e7aa8858ef2bea93d8ef4070dfe61b812a1f627723774f5516caf2f281039b21f315dedcb949a16ccf02476fc7c0ce909f4d37fbc46736c5ad5c9c2594fa92569ed0b86c9d131e4857f65294b1a7497d00a51eda1f0e83297c162ce642f7409","signature":"a10b5b313e7b86a17a7007cb20efd71859f9013dca2103e577e6592f44a2ef99e5911a55c81451713177744273f8ad170b5362d3dc75a50aaf7d93215e370cdf875da83f5aedaf9c2dc0a9492672f7865314df86999deb706ce08a0c5bd63598"}';
        assertFalse(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIReturnsFalseWhenSignatureFieldIsNotString() public view {
        string memory apiResponse =
            '{"round":5997160,"previous_signature":"8e7aa8858ef2bea93d8ef4070dfe61b812a1f627723774f5516caf2f281039b21f315dedcb949a16ccf02476fc7c0ce909f4d37fbc46736c5ad5c9c2594fa92569ed0b86c9d131e4857f65294b1a7497d00a51eda1f0e83297c162ce642f7409","signature":12345}';
        assertFalse(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIReturnsFalseWhenPreviousSignatureHexHasInvalidHighNibbleCharacter() public view {
        string memory apiResponse =
            '{"round":5997160,"previous_signature":"ge7aa8858ef2bea93d8ef4070dfe61b812a1f627723774f5516caf2f281039b21f315dedcb949a16ccf02476fc7c0ce909f4d37fbc46736c5ad5c9c2594fa92569ed0b86c9d131e4857f65294b1a7497d00a51eda1f0e83297c162ce642f7409","signature":"a10b5b313e7b86a17a7007cb20efd71859f9013dca2103e577e6592f44a2ef99e5911a55c81451713177744273f8ad170b5362d3dc75a50aaf7d93215e370cdf875da83f5aedaf9c2dc0a9492672f7865314df86999deb706ce08a0c5bd63598"}';
        assertFalse(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIReturnsFalseWhenPreviousSignatureHexUsesUppercaseNibbles() public view {
        string memory apiResponse =
            '{"round":5997160,"previous_signature":"Ae7aa8858ef2bea93d8ef4070dfe61b812a1f627723774f5516caf2f281039b21f315dedcb949a16ccf02476fc7c0ce909f4d37fbc46736c5ad5c9c2594fa92569ed0b86c9d131e4857f65294b1a7497d00a51eda1f0e83297c162ce642f7409","signature":"a10b5b313e7b86a17a7007cb20efd71859f9013dca2103e577e6592f44a2ef99e5911a55c81451713177744273f8ad170b5362d3dc75a50aaf7d93215e370cdf875da83f5aedaf9c2dc0a9492672f7865314df86999deb706ce08a0c5bd63598"}';
        assertFalse(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIReturnsFalseWhenPreviousSignatureHexHasInvalidCharacter() public view {
        string memory apiResponse =
            '{"round":5997160,"previous_signature":"8e7aa8858ef2bea93d8ef4070dfe61b812a1f627723774f5516caf2f281039b21f315dedcb949a16ccf02476fc7c0ce909f4d37fbc46736c5ad5c9c2594fa92569ed0b86c9d131e4857f65294b1a7497d00a51eda1f0e83297c162ce642f740g","signature":"a10b5b313e7b86a17a7007cb20efd71859f9013dca2103e577e6592f44a2ef99e5911a55c81451713177744273f8ad170b5362d3dc75a50aaf7d93215e370cdf875da83f5aedaf9c2dc0a9492672f7865314df86999deb706ce08a0c5bd63598"}';
        assertFalse(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIReturnsFalseWhenSignatureHexHasOddLength() public view {
        string memory apiResponse =
            '{"round":5997160,"previous_signature":"8e7aa8858ef2bea93d8ef4070dfe61b812a1f627723774f5516caf2f281039b21f315dedcb949a16ccf02476fc7c0ce909f4d37fbc46736c5ad5c9c2594fa92569ed0b86c9d131e4857f65294b1a7497d00a51eda1f0e83297c162ce642f7409","signature":"a10b5b313e7b86a17a7007cb20efd71859f9013dca2103e577e6592f44a2ef99e5911a55c81451713177744273f8ad170b5362d3dc75a50aaf7d93215e370cdf875da83f5aedaf9c2dc0a9492672f7865314df86999deb706ce08a0c5bd6359"}';
        assertFalse(verifier.verifyAPI(apiResponse));
    }

    function testVerifyAPIRevertsOnMalformedJson() public {
        string memory apiResponse =
            '{"round":5997160,"previous_signature":"8e7aa8858ef2bea93d8ef4070dfe61b812a1f627723774f5516caf2f281039b21f315dedcb949a16ccf02476fc7c0ce909f4d37fbc46736c5ad5c9c2594fa92569ed0b86c9d131e4857f65294b1a7497d00a51eda1f0e83297c162ce642f7409","signature":"a10b5b313e7b86a17a7007cb20efd718"';
        vm.expectRevert(JSONParserLib.ParsingFailed.selector);
        verifier.verifyAPI(apiResponse);
    }

    function testVerifyNormalizedReturnsConsistentHashesAcrossSignatureEncodings() public view {
        (bool compressedVerified, bytes32 compressedNormalized, bytes32 compressedChainScoped) =
            verifier.verifyNormalized(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, SIG_ONE_COMPRESSED);
        (bool uncompressedVerified, bytes32 uncompressedNormalized, bytes32 uncompressedChainScoped) =
            verifier.verifyNormalized(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, SIG_ONE_UNCOMPRESSED);

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
            verifier.verifyNormalized(ROUND_ONE + 1, PREV_SIG_ONE_COMPRESSED, SIG_ONE_COMPRESSED);

        assertFalse(verified);
        assertEq(normalizedHash, bytes32(0));
        assertEq(chainScopedHash, bytes32(0));
    }

    function testVerifyNormalizedReturnsZeroHashesForInvalidSignatureLength() public view {
        (bool verified, bytes32 normalizedHash, bytes32 chainScopedHash) =
            verifier.verifyNormalized(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, hex"1234");

        assertFalse(verified);
        assertEq(normalizedHash, bytes32(0));
        assertEq(chainScopedHash, bytes32(0));
    }

    function testDecompressSignatureReturnsExpectedUncompressedBytesRoundOne() public view {
        bytes memory decompressed = verifier.decompressSignature(SIG_ONE_COMPRESSED);
        assertEq(decompressed, SIG_ONE_UNCOMPRESSED);
    }

    function testDecompressSignatureReturnsExpectedUncompressedBytesRoundTwo() public view {
        bytes memory decompressed = verifier.decompressSignature(SIG_TWO_COMPRESSED);
        assertEq(decompressed, SIG_TWO_UNCOMPRESSED);
    }

    function testDecompressSignatureRevertsOnInvalidLength() public {
        vm.expectRevert(bytes("Invalid G2 bytes length"));
        verifier.decompressSignature(hex"1234");
    }

    function testVerifyRevertsWhenCompressedEncodingBitIsMissing() public {
        bytes memory malformedCompressed = bytes(SIG_ONE_COMPRESSED);
        malformedCompressed[0] = bytes1(uint8(malformedCompressed[0]) & 0x7f);

        vm.expectRevert(bytes("Invalid G2 point: not compressed"));
        verifier.verify(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, malformedCompressed);
    }

    function testSafeVerifyRejectsWhenCompressedEncodingBitIsMissing() public view {
        bytes memory malformedCompressed = bytes(SIG_ONE_COMPRESSED);
        malformedCompressed[0] = bytes1(uint8(malformedCompressed[0]) & 0x7f);

        assertFalse(verifier.safeVerify(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, malformedCompressed));
    }

    function testVerifyRevertsWhenCompressedInfinityFlagIsSet() public {
        bytes memory malformedCompressed = bytes(SIG_ONE_COMPRESSED);
        malformedCompressed[0] = bytes1(uint8(malformedCompressed[0]) | 0x40);

        vm.expectRevert(bytes("unsupported: point at infinity"));
        verifier.verify(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, malformedCompressed);
    }

    function testSafeVerifyRejectsWhenCompressedInfinityFlagIsSet() public view {
        bytes memory malformedCompressed = bytes(SIG_ONE_COMPRESSED);
        malformedCompressed[0] = bytes1(uint8(malformedCompressed[0]) | 0x40);

        assertFalse(verifier.safeVerify(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, malformedCompressed));
    }

    function testVerifyAndSafeVerifyRejectInfinityUncompressedSignature() public view {
        bytes memory infinityUncompressed = new bytes(192);

        assertFalse(verifier.verify(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, infinityUncompressed));
        assertFalse(verifier.safeVerify(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, infinityUncompressed));
    }

    function testSafeVerifyReturnsFalseWhenG2MsmPrecompileCallFails() public {
        vm.mockCallRevert(address(0x0e), bytes4(0x00000000), bytes("mocked"));

        vm.expectRevert(bytes("g2msm failed"));
        verifier.verify(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, SIG_ONE_COMPRESSED);
        assertFalse(verifier.safeVerify(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, SIG_ONE_COMPRESSED));

        vm.clearMockedCalls();
    }

    function testVerifyRejectsCompressedSignatureWithSignBitFlipped() public view {
        bytes memory tampered = bytes(SIG_ONE_COMPRESSED);
        tampered[0] = bytes1(uint8(tampered[0]) ^ 0x20);

        _assertNotVerifiedOrReverted(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, tampered);
    }

    function testVerifyRejectsCompressedSignatureWithNonCanonicalFieldElement() public view {
        _assertNotVerifiedOrReverted(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, _compressedSignatureWithX1EqualFieldPrime());
    }

    function testVerifyRejectsSignatureWithBitFlipped() public view {
        bytes memory tampered = bytes(SIG_ONE_UNCOMPRESSED);
        tampered[0] = bytes1(uint8(tampered[0]) ^ 0x01);

        _assertNotVerifiedOrReverted(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, tampered);
    }

    function testVerifyRejectsUncompressedSignatureWithNonCanonicalFieldElement() public view {
        _assertNotVerifiedOrReverted(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, _uncompressedSignatureWithX1EqualFieldPrime());
    }

    /// forge-config: default.fuzz.runs = 32
    function testFuzzVerifyDoesNotAcceptBitFlippedUncompressedSignature(uint8 index, uint8 mask) public view {
        vm.assume(mask != 0);

        bytes memory tampered = bytes(SIG_ONE_UNCOMPRESSED);
        uint256 i = bound(uint256(index), 0, tampered.length - 1);
        tampered[i] = bytes1(uint8(tampered[i]) ^ mask);

        _assertNotVerifiedOrReverted(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, tampered);
    }

    /// forge-config: default.fuzz.runs = 32
    function testFuzzVerifyDoesNotAcceptBitFlippedCompressedSignature(uint8 index, uint8 mask) public view {
        vm.assume(mask != 0);

        bytes memory tampered = bytes(SIG_ONE_COMPRESSED);
        uint256 i = bound(uint256(index), 0, tampered.length - 1);
        tampered[i] = bytes1(uint8(tampered[i]) ^ mask);

        _assertNotVerifiedOrReverted(ROUND_ONE, PREV_SIG_ONE_COMPRESSED, tampered);
    }

    /// forge-config: default.fuzz.runs = 32
    function testFuzzVerifyDoesNotAcceptBitFlippedPreviousSignature(uint8 index, uint8 mask) public view {
        vm.assume(mask != 0);

        bytes memory tamperedPrev = bytes(PREV_SIG_ONE_COMPRESSED);
        uint256 i = bound(uint256(index), 0, tamperedPrev.length - 1);
        tamperedPrev[i] = bytes1(uint8(tamperedPrev[i]) ^ mask);

        _assertNotVerifiedOrReverted(ROUND_ONE, tamperedPrev, SIG_ONE_UNCOMPRESSED);
    }

    /// forge-config: default.fuzz.runs = 32
    function testFuzzVerifyRejectsRandomUncompressedPayload(
        uint64 round,
        bytes32 a,
        bytes32 b,
        bytes32 c,
        bytes32 d,
        bytes32 e,
        bytes32 f
    ) public view {
        bytes memory randomSignature = abi.encodePacked(a, b, c, d, e, f);
        bytes32 sigHash = keccak256(randomSignature);

        vm.assume(!(round == ROUND_ONE && sigHash == keccak256(SIG_ONE_UNCOMPRESSED)));
        vm.assume(!(round == ROUND_TWO && sigHash == keccak256(SIG_TWO_UNCOMPRESSED)));

        _assertNotVerifiedOrReverted(round, PREV_SIG_ONE_COMPRESSED, randomSignature);
    }

    /// forge-config: default.fuzz.runs = 32
    function testFuzzVerifyRejectsRandomPreviousSignature(uint64 round, bytes32 p0, bytes32 p1, bytes32 p2)
        public
        view
    {
        bytes memory randomPrevious = abi.encodePacked(p0, p1, p2);
        bytes32 prevHash = keccak256(randomPrevious);

        vm.assume(!(round == ROUND_ONE && prevHash == keccak256(PREV_SIG_ONE_COMPRESSED)));

        _assertNotVerifiedOrReverted(round, randomPrevious, SIG_ONE_UNCOMPRESSED);
    }

    /// forge-config: default.fuzz.runs = 32
    function testFuzzVerifyRejectsRandomCompressedPayload(uint64 round, bytes32 a, bytes32 b, bytes32 c) public view {
        bytes memory randomCompressed = abi.encodePacked(a, b, c);
        assembly {
            mstore(randomCompressed, 96)
        }

        vm.assume(!(round == ROUND_ONE && keccak256(randomCompressed) == keccak256(SIG_ONE_COMPRESSED)));
        vm.assume(!(round == ROUND_TWO && keccak256(randomCompressed) == keccak256(SIG_TWO_COMPRESSED)));

        _assertNotVerifiedOrReverted(round, PREV_SIG_ONE_COMPRESSED, randomCompressed);
    }

    function testDecompressSignatureMatchesFFIForKnownVector() public {
        bytes memory fromContract = verifier.decompressSignature(SIG_ONE_COMPRESSED);
        bytes memory fromFfi = _decompressG2SignatureViaFFI(SIG_ONE_COMPRESSED);
        assertEq(fromContract, fromFfi);
    }

    /// @notice Fetches latest drand default round over FFI and verifies the live signature.
    function testVerifyAcceptsLatestLiveDefaultRoundViaFFI() public {
        (
            uint64 round,
            bytes memory previousSignature,
            bytes memory signatureCompressed,
            bytes memory signatureUncompressed
        ) = _fetchLatestDefaultRoundFromApi();
        assertTrue(verifier.verify(round, previousSignature, signatureUncompressed));
        assertTrue(verifier.verify(round, previousSignature, signatureCompressed));
    }

    /// @notice Verifies the latest live default JSON payload directly via verifyAPI.
    function testVerifyAPIAcceptsLatestLiveDefaultRoundViaFFI() public {
        string memory response = _fetchLatestDefaultRoundApiResponse();
        assertTrue(verifier.verifyAPI(response));
    }

    /// @notice Confirms tampering a live default network signature causes verification failure.
    function testVerifyRejectsTamperedLatestLiveDefaultRoundViaFFI() public {
        (
            uint64 round,
            bytes memory previousSignature,
            bytes memory signatureCompressed,
            bytes memory signatureUncompressed
        ) = _fetchLatestDefaultRoundFromApi();
        signatureUncompressed[0] = bytes1(uint8(signatureUncompressed[0]) ^ 0x01);
        signatureCompressed[0] = bytes1(uint8(signatureCompressed[0]) ^ 0x01);

        _assertNotVerifiedOrReverted(round, previousSignature, signatureUncompressed);
        assertFalse(verifier.safeVerify(round, previousSignature, signatureUncompressed));
        _assertNotVerifiedOrReverted(round, previousSignature, signatureCompressed);
        assertFalse(verifier.safeVerify(round, previousSignature, signatureCompressed));
    }

    function testDecompressSignatureMatchesFFIForLatestLiveDefaultRound() public {
        (,, bytes memory signatureCompressed,) = _fetchLatestDefaultRoundFromApi();
        bytes memory fromContract = verifier.decompressSignature(signatureCompressed);
        bytes memory fromFfi = _decompressG2SignatureViaFFI(signatureCompressed);
        assertEq(fromContract, fromFfi);
    }

    function _fetchLatestDefaultRoundFromApi()
        internal
        returns (
            uint64 round,
            bytes memory previousSignature,
            bytes memory signatureCompressed,
            bytes memory signatureUncompressed
        )
    {
        string memory apiResponse = _fetchLatestDefaultRoundApiResponse();
        JSONParserLib.Item memory root = apiResponse.parse();

        round = uint64(JSONParserLib.parseUint(root.at('"round"').value()));

        string memory previousHex = JSONParserLib.decodeString(root.at('"previous_signature"').value());
        previousSignature = vm.parseBytes(string.concat("0x", previousHex));

        string memory signatureCompressedHex = JSONParserLib.decodeString(root.at('"signature"').value());
        signatureCompressed = vm.parseBytes(string.concat("0x", signatureCompressedHex));
        signatureUncompressed = _decompressG2SignatureViaFFI(signatureCompressed);
    }

    function _fetchLatestDefaultRoundApiResponse() internal returns (string memory) {
        string[] memory command = new string[](3);
        command[0] = "curl";
        command[1] = "-fsSL";
        command[2] = string.concat("https://api.drand.sh/", DEFAULT_CHAIN_HASH, "/public/latest");

        bytes memory response = vm.ffi(command);
        return string(response);
    }

    function _decompressG2SignatureViaFFI(bytes memory compressedSig) internal returns (bytes memory) {
        string[] memory command = new string[](4);
        command[0] = "python3";
        command[1] = "-c";
        command[2] =
            "import sys;from py_ecc.bls.g2_primitives import signature_to_G2;from py_ecc.optimized_bls12_381 import normalize;h=sys.argv[1].replace('0x','',1);s=bytes.fromhex(h);p=signature_to_G2(s);x,y=normalize(p);to_i=lambda v:int(v.n) if hasattr(v,'n') else int(v);b=lambda z:int(z).to_bytes(48,'big');x0=to_i(x.coeffs[0]);x1=to_i(x.coeffs[1]);y0=to_i(y.coeffs[0]);y1=to_i(y.coeffs[1]);print((b(x1)+b(x0)+b(y1)+b(y0)).hex(),end='')";
        command[3] = vm.toString(compressedSig);

        return vm.ffi(command);
    }

    function _assertNotVerifiedOrReverted(uint64 round, bytes memory previousSignature, bytes memory signature)
        internal
        view
    {
        (bool success, bytes memory returnData) = address(verifier)
            .staticcall(abi.encodeCall(DrandOracleDefault.verify, (round, previousSignature, signature)));

        if (success) {
            assertFalse(abi.decode(returnData, (bool)));
        }
    }

    function _uncompressedSignatureWithX1EqualFieldPrime() internal pure returns (bytes memory signature) {
        signature = new bytes(192);
        uint128 x1Hi = FIELD_P_HI;
        uint256 x1Lo = FIELD_P_LO;
        uint128 y0Hi = 0;
        uint256 y0Lo = 2;

        assembly {
            mstore(add(signature, 0x20), shl(128, x1Hi))
            mstore(add(signature, 0x30), x1Lo)
            mstore(add(signature, 0xb0), shl(128, y0Hi))
            mstore(add(signature, 0xc0), y0Lo)
        }
    }

    function _compressedSignatureWithX1EqualFieldPrime() internal pure returns (bytes memory signature) {
        signature = new bytes(96);
        uint128 x1HiWithCompressedFlag = FIELD_P_HI | 0x80000000000000000000000000000000;

        assembly {
            mstore(add(signature, 0x20), shl(128, x1HiWithCompressedFlag))
            mstore(add(signature, 0x30), FIELD_P_LO)
        }
    }
}
