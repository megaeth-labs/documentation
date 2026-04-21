// SPDX-License-Identifier: VPL
pragma solidity ^0.8.34;

import {Test} from "../lib/forge-std/src/Test.sol";

import {BLS2} from "../lib/bls-solidity/src/libraries/BLS2.sol";
import {DrandOracleDefault} from "../src/oracles/DrandOracleDefault.sol";
import {LibBLS} from "../src/utils/LibBLS.sol";
import {LibBLSHarness} from "../test/utils/LibBLSHarness.sol";

contract LibBLSTest is Test {
    LibBLSHarness internal harness;
    DrandOracleDefault internal verifierDefault;

    bytes internal constant DST = bytes("BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_");

    uint64 internal constant ROUND_ONE = 5997160;
    bytes internal constant PREV_SIG_ONE_COMPRESSED =
        hex"8e7aa8858ef2bea93d8ef4070dfe61b812a1f627723774f5516caf2f281039b21f315dedcb949a16ccf02476fc7c0ce909f4d37fbc46736c5ad5c9c2594fa92569ed0b86c9d131e4857f65294b1a7497d00a51eda1f0e83297c162ce642f7409";
    bytes internal constant SIG_ONE_COMPRESSED =
        hex"a10b5b313e7b86a17a7007cb20efd71859f9013dca2103e577e6592f44a2ef99e5911a55c81451713177744273f8ad170b5362d3dc75a50aaf7d93215e370cdf875da83f5aedaf9c2dc0a9492672f7865314df86999deb706ce08a0c5bd63598";
    bytes internal constant SIG_ONE_UNCOMPRESSED =
        hex"010b5b313e7b86a17a7007cb20efd71859f9013dca2103e577e6592f44a2ef99e5911a55c81451713177744273f8ad170b5362d3dc75a50aaf7d93215e370cdf875da83f5aedaf9c2dc0a9492672f7865314df86999deb706ce08a0c5bd635980f9a1d326c1c9c4febdd6c9c0b3c1fa7d76ecdc2ded95077b9c2fe3a39f100860cbd5d9ed9a58fec9653a551bc41c41d08624c6799d867638a3f7418e2119bcd9c68ad3602b85d51f45e9601e8221647d7745dba9528c2caff050ce5557224e1";

    uint128 internal constant P_HI = 0x1a0111ea397fe69a4b1ba7b6434bacd7;
    uint256 internal constant P_LO = 0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab;
    uint128 internal constant P_MINUS_ONE_DIV_2_HI = 0x0d0088f51cbff34d258dd3db21a5d66b;
    uint256 internal constant P_MINUS_ONE_DIV_2_LO = 0xb23ba5c279c2895fb39869507b587b120f55ffff58a9ffffdcff7fffffffd555;

    function setUp() public {
        harness = new LibBLSHarness();
        verifierDefault = new DrandOracleDefault();
    }

    function testDecompressG2SignatureMatchesKnownVector() public view {
        assertEq(harness.decompressG2Signature(SIG_ONE_COMPRESSED), SIG_ONE_UNCOMPRESSED);
    }

    function testVerifyDefaultSignatureKnownVectorsCompressedAndUncompressed() public view {
        bytes32 digest = verifierDefault.roundMessageHash(ROUND_ONE, PREV_SIG_ONE_COMPRESSED);
        BLS2.PointG1 memory pubkey = verifierDefault.PUBLIC_KEY();

        assertTrue(harness.verifyDefaultSignature(SIG_ONE_UNCOMPRESSED, pubkey, DST, digest));
        assertTrue(harness.verifyDefaultSignature(SIG_ONE_COMPRESSED, pubkey, DST, digest));
    }

    function testVerifyDefaultSignatureRejectsInvalidLength() public view {
        bytes32 digest = verifierDefault.roundMessageHash(ROUND_ONE, PREV_SIG_ONE_COMPRESSED);
        assertFalse(harness.verifyDefaultSignature(hex"1234", verifierDefault.PUBLIC_KEY(), DST, digest));
        assertFalse(harness.verifyDefaultSignature(hex"", verifierDefault.PUBLIC_KEY(), DST, digest));
    }

    function testVerifyDefaultSignatureRejectsWhenSubgroupCheckReturnsNonInfinity() public {
        bytes32 digest = verifierDefault.roundMessageHash(ROUND_ONE, PREV_SIG_ONE_COMPRESSED);
        BLS2.PointG1 memory pubkey = verifierDefault.PUBLIC_KEY();

        bytes memory nonInfinity = new bytes(256);
        nonInfinity[31] = 0x01;

        vm.mockCall(address(0x0e), bytes4(0x00000000), nonInfinity);
        assertFalse(harness.verifyDefaultSignature(SIG_ONE_COMPRESSED, pubkey, DST, digest));
        vm.clearMockedCalls();
    }

    function testG2UnmarshalCompressedRevertsOnInvalidLength() public {
        vm.expectRevert(bytes("Invalid G2 bytes length"));
        harness.g2UnmarshalCompressed(hex"1234");
    }

    function testG2UnmarshalCompressedRevertsWhenCompressedFlagMissing() public {
        bytes memory malformed = bytes(SIG_ONE_COMPRESSED);
        malformed[0] = bytes1(uint8(malformed[0]) & 0x7f);

        vm.expectRevert(bytes("Invalid G2 point: not compressed"));
        harness.g2UnmarshalCompressed(malformed);
    }

    function testG2UnmarshalCompressedRevertsOnInfinityFlag() public {
        bytes memory malformed = bytes(SIG_ONE_COMPRESSED);
        malformed[0] = bytes1(uint8(malformed[0]) | 0x40);

        vm.expectRevert(bytes("unsupported: point at infinity"));
        harness.g2UnmarshalCompressed(malformed);
    }

    function testG2UnmarshalCompressedRevertsOnNonCanonicalX1() public {
        bytes memory malformed = _compressedWithX1EqualFieldPrime();

        vm.expectRevert(bytes("Invalid G2 point: non-canonical x1"));
        harness.g2UnmarshalCompressed(malformed);
    }

    function testG2UnmarshalCompressedRevertsOnNonCanonicalX0() public {
        bytes memory malformed = _compressedWithX0EqualFieldPrime();

        vm.expectRevert(bytes("Invalid G2 point: non-canonical x0"));
        harness.g2UnmarshalCompressed(malformed);
    }

    function testG2UnmarshalCompressedSignBitControlsYChoice() public view {
        BLS2.PointG2 memory p = harness.g2UnmarshalCompressed(SIG_ONE_COMPRESSED);

        bytes memory flipped = bytes(SIG_ONE_COMPRESSED);
        flipped[0] = bytes1(uint8(flipped[0]) ^ 0x20);
        BLS2.PointG2 memory q = harness.g2UnmarshalCompressed(flipped);

        assertEq(p.x1_hi, q.x1_hi);
        assertEq(p.x1_lo, q.x1_lo);
        assertEq(p.x0_hi, q.x0_hi);
        assertEq(p.x0_lo, q.x0_lo);

        (uint128 ny1Hi, uint256 ny1Lo) = harness.fpNeg(p.y1_hi, p.y1_lo);
        (uint128 ny0Hi, uint256 ny0Lo) = harness.fpNeg(p.y0_hi, p.y0_lo);
        assertEq(q.y1_hi, ny1Hi);
        assertEq(q.y1_lo, ny1Lo);
        assertEq(q.y0_hi, ny0Hi);
        assertEq(q.y0_lo, ny0Lo);
    }

    function testG2UnmarshalCompressedRevertsOnNoSquareRoot() public view {
        bytes4 errorSelector = bytes4(keccak256("Error(string)"));
        bytes memory expected = abi.encodeWithSelector(errorSelector, "Invalid G2 point: no square root");

        bool found;
        for (uint256 x0 = 0; x0 < 256 && !found; x0++) {
            bytes memory candidate = new bytes(96);
            uint128 x1HiWithCompressedFlag = 0x80000000000000000000000000000000;
            assembly {
                mstore(add(candidate, 0x20), shl(128, x1HiWithCompressedFlag))
                mstore(add(candidate, 0x60), x0)
            }

            (bool success, bytes memory returnData) =
                address(harness).staticcall(abi.encodeCall(LibBLSHarness.g2UnmarshalCompressed, (candidate)));

            if (!success && keccak256(returnData) == keccak256(expected)) {
                found = true;
            }
        }

        assertTrue(found, "expected at least one x yielding no square root revert");
    }

    function testFp2SqrtRealBranch() public view {
        (LibBLS.Fp2 memory y, bool ok) = harness.fp2Sqrt(0, 0, 0, 4);
        assertTrue(ok);
        assertEq(y.c1_hi, 0);
        assertEq(y.c1_lo, 0);

        bool squareOk = harness.fp2SquareEquals(y.c1_hi, y.c1_lo, y.c0_hi, y.c0_lo, 0, 0, 0, 4);
        assertTrue(squareOk);
    }

    function testFp2SqrtImaginaryBranchFromZeroC1() public view {
        (uint128 neg4Hi, uint256 neg4Lo) = harness.fpNeg(0, 4);
        (LibBLS.Fp2 memory y, bool ok) = harness.fp2Sqrt(0, 0, neg4Hi, neg4Lo);
        assertTrue(ok);
        assertEq(y.c0_hi, 0);
        assertEq(y.c0_lo, 0);

        bool squareOk = harness.fp2SquareEquals(y.c1_hi, y.c1_lo, y.c0_hi, y.c0_lo, 0, 0, neg4Hi, neg4Lo);
        assertTrue(squareOk);
    }

    function testFp2SqrtImaginaryNonZeroPath() public view {
        LibBLS.Fp2 memory input = LibBLS.Fp2({c1_hi: 0, c1_lo: 6, c0_hi: 0, c0_lo: 9});
        (LibBLS.Fp2 memory y, bool ok) = harness.fp2Sqrt(input.c1_hi, input.c1_lo, input.c0_hi, input.c0_lo);

        assertTrue(ok);
        assertTrue(
            harness.fp2SquareEquals(
                y.c1_hi, y.c1_lo, y.c0_hi, y.c0_lo, input.c1_hi, input.c1_lo, input.c0_hi, input.c0_lo
            )
        );
    }

    function testFp2SqrtCanReturnFalse() public view {
        bool found;
        for (uint256 a = 1; a < 64 && !found; a++) {
            for (uint256 b = 1; b < 64 && !found; b++) {
                (, bool ok) = harness.fp2SqrtImaginaryNonZero(0, b, 0, a);
                if (!ok) found = true;
            }
        }
        assertTrue(found);
    }

    function testFp2SqrtC1ZeroCanReturnFalseForNonCanonicalInput() public view {
        (LibBLS.Fp2 memory y, bool ok) = harness.fp2Sqrt(0, 0, type(uint128).max, type(uint256).max);
        assertFalse(ok);
        assertEq(y.c1_hi, 0);
        assertEq(y.c1_lo, 0);
        assertEq(y.c0_hi, 0);
        assertEq(y.c0_lo, 0);
    }

    function testFp2SqrtImaginaryNonZeroCanHitNoY0Branch() public view {
        bool found;

        uint128[5] memory his = [uint128(0), uint128(1), uint128(2), P_HI, type(uint128).max];
        uint256[7] memory los = [uint256(0), uint256(1), uint256(2), uint256(3), uint256(4), P_LO, type(uint256).max];

        for (uint256 ai = 0; ai < his.length && !found; ai++) {
            for (uint256 al = 0; al < los.length && !found; al++) {
                for (uint256 bi = 0; bi < his.length && !found; bi++) {
                    for (uint256 bl = 0; bl < los.length && !found; bl++) {
                        if (his[bi] == 0 && los[bl] == 0) continue;

                        (uint128 tHi, uint256 tLo, bool hasTSqrt) =
                            harness.fp2NormSqrt(his[ai], los[al], his[bi], los[bl]);
                        if (!hasTSqrt) continue;

                        (,, bool hasY0) = harness.fp2SqrtRealComponent(his[ai], los[al], tHi, tLo);
                        if (!hasY0) {
                            (, bool ok) = harness.fp2SqrtImaginaryNonZero(his[bi], los[bl], his[ai], los[al]);
                            assertFalse(ok);
                            found = true;
                        }
                    }
                }
            }
        }

        assertTrue(found, "expected hasY0=false branch to be reachable");
    }

    function testFp2NormSqrtAndRecoverImaginaryPart() public view {
        // a=4, b=3 -> norm = sqrt(a^2+b^2) = sqrt(25) = ±5
        (uint128 tHi, uint256 tLo, bool ok) = harness.fp2NormSqrt(0, 4, 0, 3);
        assertTrue(ok);
        (uint128 sqHi, uint256 sqLo) = harness.fpMul(tHi, tLo, tHi, tLo);
        (uint128 expectedHi, uint256 expectedLo) = harness.fpAddMod(0, 16, 0, 9);
        assertEq(sqHi, expectedHi);
        assertEq(sqLo, expectedLo);

        (uint128 y1Hi, uint256 y1Lo) = harness.fp2RecoverImaginaryPart(0, 3, 0, 2);
        (uint128 twoY0Hi, uint256 twoY0Lo) = harness.fpAddMod(0, 2, 0, 2);
        (uint128 backHi, uint256 backLo) = harness.fpMul(y1Hi, y1Lo, twoY0Hi, twoY0Lo);
        assertEq(backHi, 0);
        assertEq(backLo, 3);
    }

    function testFp2SqrtRealComponent() public view {
        (uint128 y0Hi, uint256 y0Lo, bool hasY0) = harness.fp2SqrtRealComponent(0, 8, 0, 0);
        assertTrue(hasY0);
        (uint128 sqHi, uint256 sqLo) = harness.fpMul(y0Hi, y0Lo, y0Hi, y0Lo);
        assertEq(sqHi, 0);
        assertEq(sqLo, 4);
    }

    function testIsLexicographicallyLargestBothBranches() public view {
        assertFalse(harness.isLexicographicallyLargest(0, 1, 0, 0));
        assertTrue(harness.isLexicographicallyLargest(P_MINUS_ONE_DIV_2_HI, P_MINUS_ONE_DIV_2_LO + 1, 0, 0));

        assertFalse(harness.isLexicographicallyLargest(0, 0, 0, 1));
        assertTrue(harness.isLexicographicallyLargest(0, 0, P_MINUS_ONE_DIV_2_HI, P_MINUS_ONE_DIV_2_LO + 1));
    }

    function testFpSqrtBranches() public view {
        (uint128 zHi, uint256 zLo, bool zOk) = harness.fpSqrt(0, 0);
        assertTrue(zOk);
        assertEq(zHi, 0);
        assertEq(zLo, 0);

        (uint128 rHi, uint256 rLo, bool rOk) = harness.fpSqrt(0, 4);
        assertTrue(rOk);
        (uint128 sqHi, uint256 sqLo) = harness.fpMul(rHi, rLo, rHi, rLo);
        assertEq(sqHi, 0);
        assertEq(sqLo, 4);

        uint256 nonResidue = _findNonResidue();
        (,, bool nrOk) = harness.fpSqrt(0, nonResidue);
        assertFalse(nrOk);
    }

    function testFpInvRevertsOnZeroAndWorksForNonZero() public {
        vm.expectRevert(bytes("inverse of zero"));
        harness.fpInv(0, 0);

        (uint128 invHi, uint256 invLo) = harness.fpInv(0, 3);
        (uint128 oneHi, uint256 oneLo) = harness.fpMul(0, 3, invHi, invLo);
        assertEq(oneHi, 0);
        assertEq(oneLo, 1);
    }

    function testFpMulSquareModExp() public view {
        (uint128 sqHi, uint256 sqLo) = harness.fpSquare(0, 7);
        (uint128 mulHi, uint256 mulLo) = harness.fpMul(0, 7, 0, 7);
        assertEq(sqHi, mulHi);
        assertEq(sqLo, mulLo);

        (uint128 oneHi, uint256 oneLo) = harness.fpModExp(0, 9, 0, 0);
        assertEq(oneHi, 0);
        assertEq(oneLo, 1);

        (uint128 sameHi, uint256 sameLo) = harness.fpModExp(0, 9, 0, 1);
        assertEq(sameHi, 0);
        assertEq(sameLo, 9);
    }

    function testFpAddSubDivNegRawAndComparators() public view {
        (uint128 addHi, uint256 addLo) = harness.fpAddMod(0, 10, 0, 11);
        assertEq(addHi, 0);
        assertEq(addLo, 21);

        (uint128 wrapAddHi, uint256 wrapAddLo) = harness.fpAddMod(P_HI, P_LO - 1, 0, 2);
        assertEq(wrapAddHi, 0);
        assertEq(wrapAddLo, 1);

        (uint128 subHi, uint256 subLo) = harness.fpSubMod(0, 10, 0, 3);
        assertEq(subHi, 0);
        assertEq(subLo, 7);

        (uint128 wrapSubHi, uint256 wrapSubLo) = harness.fpSubMod(0, 1, 0, 2);
        assertEq(wrapSubHi, P_HI);
        assertEq(wrapSubLo, P_LO - 1);

        (uint128 halfEvenHi, uint256 halfEvenLo) = harness.fpDiv2Mod(0, 8);
        assertEq(halfEvenHi, 0);
        assertEq(halfEvenLo, 4);

        (uint128 halfOddHi, uint256 halfOddLo) = harness.fpDiv2Mod(0, 9);
        (uint128 dblHi, uint256 dblLo) = harness.fpAddMod(halfOddHi, halfOddLo, halfOddHi, halfOddLo);
        assertEq(dblHi, 0);
        assertEq(dblLo, 9);

        (uint128 negHi, uint256 negLo) = harness.fpNeg(0, 3);
        (uint128 zeroHi, uint256 zeroLo) = harness.fpAddMod(0, 3, negHi, negLo);
        assertEq(zeroHi, 0);
        assertEq(zeroLo, 0);

        (uint128 addRawHi, uint256 addRawLo) = harness.fpAddRaw(type(uint128).max, type(uint256).max, 0, 1);
        assertEq(addRawHi, 0);
        assertEq(addRawLo, 0);

        (uint128 subRawHi, uint256 subRawLo) = harness.fpSubRaw(0, 0, 0, 1);
        assertEq(subRawHi, type(uint128).max);
        assertEq(subRawLo, type(uint256).max);

        assertTrue(harness.fpLt(0, 1, 0, 2));
        assertTrue(harness.fpGt(0, 2, 0, 1));
        assertTrue(harness.fpGte(0, 2, 0, 2));
        assertTrue(harness.fpEq(0, 5, 0, 5));
        assertTrue(harness.fpIsZero(0, 0));
        assertTrue(harness.fpLtP(0, 5));
        assertFalse(harness.fpLtP(P_HI, P_LO));
    }

    function testFpNegZeroBranch() public view {
        (uint128 zHi, uint256 zLo) = harness.fpNeg(0, 0);
        assertEq(zHi, 0);
        assertEq(zLo, 0);
    }

    function testFp2ArithmeticHelpers() public view {
        LibBLS.Fp2 memory a = harness.fp2Const(0, 2, 0, 3);
        LibBLS.Fp2 memory b = harness.fp2Const(0, 5, 0, 7);

        LibBLS.Fp2 memory add = harness.fp2Add(a, b);
        assertEq(add.c1_hi, 0);
        assertEq(add.c1_lo, 7);
        assertEq(add.c0_hi, 0);
        assertEq(add.c0_lo, 10);

        LibBLS.Fp2 memory mul = harness.fp2Mul(a, b);
        bool eq = harness.fp2Eq(mul, harness.fp2Const(0, 29, 0, 11));
        assertTrue(eq);
    }

    function testPointG2ToPairingWordsMapping() public view {
        BLS2.PointG2 memory p = BLS2.g2Unmarshal(SIG_ONE_UNCOMPRESSED);
        uint256[8] memory words = harness.pointG2ToPairingWords(p);

        assertEq(words[0], p.x0_hi);
        assertEq(words[1], p.x0_lo);
        assertEq(words[2], p.x1_hi);
        assertEq(words[3], p.x1_lo);
        assertEq(words[4], p.y0_hi);
        assertEq(words[5], p.y0_lo);
        assertEq(words[6], p.y1_hi);
        assertEq(words[7], p.y1_lo);
    }

    function testHashToPointG2PartsDeterministicAndMessageSensitive() public view {
        bytes32 digest = verifierDefault.roundMessageHash(ROUND_ONE, PREV_SIG_ONE_COMPRESSED);
        (uint256[8] memory a0, uint256[8] memory a1) = harness.hashToPointG2Parts(DST, abi.encodePacked(digest));
        (uint256[8] memory b0, uint256[8] memory b1) = harness.hashToPointG2Parts(DST, abi.encodePacked(digest));

        assertEq(keccak256(abi.encode(a0)), keccak256(abi.encode(b0)));
        assertEq(keccak256(abi.encode(a1)), keccak256(abi.encode(b1)));

        (uint256[8] memory c0, uint256[8] memory c1) =
            harness.hashToPointG2Parts(DST, abi.encodePacked(bytes32(uint256(digest) ^ 1)));
        assertTrue(keccak256(abi.encode(a0, a1)) != keccak256(abi.encode(c0, c1)));
    }

    function testHashToPointG2PartsCanRevertAtP0WithTightGasBudget() public {
        bytes memory data =
            abi.encodeCall(LibBLSHarness.hashToPointG2Parts, (DST, abi.encodePacked(bytes32(uint256(1)))));
        bool found = _findReasonWithGasSweep(data, "map_fp2_to_g2 p0 failed", 10_000, 600_000, 2_000);
        assertTrue(found, "no gas budget hit map_fp2_to_g2 p0 failed");
    }

    function testHashToPointG2PartsCanRevertAtP1WithTightGasBudget() public {
        bytes memory data =
            abi.encodeCall(LibBLSHarness.hashToPointG2Parts, (DST, abi.encodePacked(bytes32(uint256(1)))));
        bool found = _findReasonWithGasSweep(data, "map_fp2_to_g2 p1 failed", 10_000, 1_500_000, 2_000);
        assertTrue(found, "no gas budget hit map_fp2_to_g2 p1 failed");
    }

    function testVerifySingleG2AcceptsKnownVectorAndRejectsTamperedSignature() public view {
        BLS2.PointG2 memory sigPoint = BLS2.g2Unmarshal(SIG_ONE_UNCOMPRESSED);
        uint256[8] memory sigWords = harness.pointG2ToPairingWords(sigPoint);

        bytes32 digest = verifierDefault.roundMessageHash(ROUND_ONE, PREV_SIG_ONE_COMPRESSED);
        (uint256[8] memory msg0, uint256[8] memory msg1) = harness.hashToPointG2Parts(DST, abi.encodePacked(digest));

        (bool pairingSuccess, bool callSuccess) =
            harness.verifySingleG2(sigWords, verifierDefault.PUBLIC_KEY(), msg0, msg1);
        assertTrue(callSuccess);
        assertTrue(pairingSuccess);

        sigWords[0] ^= 1;
        (pairingSuccess, callSuccess) = harness.verifySingleG2(sigWords, verifierDefault.PUBLIC_KEY(), msg0, msg1);
        if (callSuccess) {
            assertFalse(pairingSuccess);
        }
    }

    function testModPInPlaceReducesChunkToFieldRange() public view {
        bytes memory input = new bytes(256);

        // chunk at offset 64 set to value > p.
        _storeFpAt(input, 64, P_HI, P_LO + 1);
        bytes memory reduced = harness.modPInPlace(input, 64);

        (uint128 outHi, uint256 outLo) = _loadFpAt(reduced, 64);
        assertTrue(harness.fpLtP(outHi, outLo));

        // Other chunks untouched.
        (uint128 beforeHi, uint256 beforeLo) = _loadFpAt(input, 0);
        (uint128 afterHi, uint256 afterLo) = _loadFpAt(reduced, 0);
        assertEq(beforeHi, afterHi);
        assertEq(beforeLo, afterLo);
    }

    function testModPInPlaceRevertsWhenModexpCallFails() public {
        vm.mockCallRevert(address(0x05), bytes4(0x00000000), bytes("mocked"));

        bytes memory input = new bytes(64);
        vm.expectRevert(bytes("modp failed"));
        harness.modPInPlace(input, 0);

        vm.clearMockedCalls();
    }

    function testExpandMsgDeterministicAndLengthAndRevert() public {
        bytes memory outA = harness.expandMsg(DST, abi.encodePacked(bytes32(uint256(1))), 96);
        bytes memory outB = harness.expandMsg(DST, abi.encodePacked(bytes32(uint256(1))), 96);
        bytes memory outC = harness.expandMsg(DST, abi.encodePacked(bytes32(uint256(2))), 96);

        assertEq(outA.length, 96);
        assertEq(keccak256(outA), keccak256(outB));
        assertTrue(keccak256(outA) != keccak256(outC));

        bytes memory longDst = new bytes(256);
        vm.expectRevert(bytes("dst too long"));
        harness.expandMsg(longDst, hex"00", 32);
    }

    function testFpModExpRevertsWhenModexpCallFails() public {
        vm.mockCallRevert(address(0x05), bytes4(0x00000000), bytes("mocked"));

        vm.expectRevert(bytes("modexp failed"));
        harness.fpModExp(0, 9, 0, 1);

        vm.clearMockedCalls();
    }

    /// forge-config: default.fuzz.runs = 32
    function testFuzzFpAddSubRoundTrip(uint8 a, uint8 b) public view {
        (uint128 addHi, uint256 addLo) = harness.fpAddMod(0, a, 0, b);
        (uint128 backHi, uint256 backLo) = harness.fpSubMod(addHi, addLo, 0, b);
        assertEq(backHi, 0);
        assertEq(backLo, a);
    }

    /// forge-config: default.fuzz.runs = 32
    function testFuzzVerifyDefaultSignatureRejectsBitFlippedCompressed(uint8 index, uint8 mask) public view {
        vm.assume(mask != 0);

        bytes memory tampered = bytes(SIG_ONE_COMPRESSED);
        uint256 i = bound(uint256(index), 0, tampered.length - 1);
        tampered[i] = bytes1(uint8(tampered[i]) ^ mask);

        bytes32 digest = verifierDefault.roundMessageHash(ROUND_ONE, PREV_SIG_ONE_COMPRESSED);
        _assertNotVerifiedOrReverted(tampered, verifierDefault.PUBLIC_KEY(), DST, digest);
    }

    /// forge-config: default.fuzz.runs = 32
    function testFuzzVerifyDefaultSignatureRejectsBitFlippedUncompressed(uint8 index, uint8 mask) public view {
        vm.assume(mask != 0);

        bytes memory tampered = bytes(SIG_ONE_UNCOMPRESSED);
        uint256 i = bound(uint256(index), 0, tampered.length - 1);
        tampered[i] = bytes1(uint8(tampered[i]) ^ mask);

        bytes32 digest = verifierDefault.roundMessageHash(ROUND_ONE, PREV_SIG_ONE_COMPRESSED);
        _assertNotVerifiedOrReverted(tampered, verifierDefault.PUBLIC_KEY(), DST, digest);
    }

    function _assertNotVerifiedOrReverted(
        bytes memory signature,
        BLS2.PointG1 memory pubkey,
        bytes memory dst,
        bytes32 digest
    ) internal view {
        (bool success, bytes memory returnData) = address(harness)
            .staticcall(abi.encodeCall(LibBLSHarness.verifyDefaultSignature, (signature, pubkey, dst, digest)));

        if (success) {
            assertFalse(abi.decode(returnData, (bool)));
        }
    }

    function _compressedWithX1EqualFieldPrime() internal pure returns (bytes memory signature) {
        signature = new bytes(96);
        uint128 x1HiWithCompressedFlag = P_HI | 0x80000000000000000000000000000000;

        assembly {
            mstore(add(signature, 0x20), shl(128, x1HiWithCompressedFlag))
            mstore(add(signature, 0x30), P_LO)
        }
    }

    function _compressedWithX0EqualFieldPrime() internal pure returns (bytes memory signature) {
        signature = bytes(SIG_ONE_COMPRESSED);
        assembly {
            mstore(add(signature, 0x50), shl(128, P_HI))
            mstore(add(signature, 0x60), P_LO)
        }
    }

    function _storeFpAt(bytes memory data, uint256 offset, uint128 hi, uint256 lo) internal pure {
        assembly {
            mstore(add(add(data, 0x20), offset), hi)
            mstore(add(add(data, 0x40), offset), lo)
        }
    }

    function _loadFpAt(bytes memory data, uint256 offset) internal pure returns (uint128 hi, uint256 lo) {
        assembly {
            hi := mload(add(add(data, 0x20), offset))
            lo := mload(add(add(data, 0x40), offset))
        }
    }

    function _findNonResidue() internal view returns (uint256) {
        for (uint256 x = 2; x < 256; x++) {
            (,, bool hasRoot) = harness.fpSqrt(0, x);
            if (!hasRoot) {
                return x;
            }
        }
        revert("non-residue not found");
    }

    function _findReasonWithGasSweep(
        bytes memory callData,
        string memory reason,
        uint256 gasStart,
        uint256 gasEnd,
        uint256 step
    ) internal returns (bool) {
        for (uint256 g = gasStart; g <= gasEnd; g += step) {
            (bool success, bytes memory returnData) = address(harness).call{gas: g}(callData);
            if (!success && _isErrorReason(returnData, reason)) {
                return true;
            }
        }
        return false;
    }

    function _isErrorReason(bytes memory returnData, string memory reason) internal pure returns (bool) {
        return keccak256(returnData) == keccak256(abi.encodeWithSelector(bytes4(keccak256("Error(string)")), reason));
    }
}
