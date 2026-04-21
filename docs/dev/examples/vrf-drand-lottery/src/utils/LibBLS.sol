// SPDX-License-Identifier: VPL
pragma solidity ^0.8.34;

import {BLS2} from "../../lib/bls-solidity/src/libraries/BLS2.sol";

/// @title LibBLS
/// @notice Internal BLS12-381 utilities for drand default network verification.
/// @dev Provides compressed G2 decoding, Fp/Fp2 arithmetic helpers, hash-to-G2 mapping,
///      and pairing-precompile wiring used by Drand verifier/oracle implementations.
library LibBLS {
    uint256 internal constant COMPRESSED_G2_SIG_LENGTH = 96;
    uint256 internal constant UNCOMPRESSED_G2_SIG_LENGTH = 192;

    uint128 private constant CLEAR_COMPRESSED_FLAGS_MASK = 0x1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    // BLS12-381 field order.
    uint128 private constant P_HI = 0x1a0111ea397fe69a4b1ba7b6434bacd7;
    uint256 private constant P_LO = 0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab;

    // (p - 1) / 2.
    uint128 private constant P_MINUS_ONE_DIV_2_HI = 0x0d0088f51cbff34d258dd3db21a5d66b;
    uint256 private constant P_MINUS_ONE_DIV_2_LO = 0xb23ba5c279c2895fb39869507b587b120f55ffff58a9ffffdcff7fffffffd555;

    // (p + 1) / 4 for p % 4 == 3 sqrt algorithm.
    uint128 private constant P_PLUS_ONE_DIV_4_HI = 0x0680447a8e5ff9a692c6e9ed90d2eb35;
    uint256 private constant P_PLUS_ONE_DIV_4_LO = 0xd91dd2e13ce144afd9cc34a83dac3d8907aaffffac54ffffee7fbfffffffeaab;

    // p - 2 for inversion.
    uint128 private constant P_MINUS_2_HI = 0x1a0111ea397fe69a4b1ba7b6434bacd7;
    uint256 private constant P_MINUS_2_LO = 0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaa9;

    // EIP-198 / EIP-2537 precompile addresses.
    uint256 private constant MODEXP_ADDRESS = 5;
    uint256 private constant BLS12_G2MSM = 0x0e;
    uint256 private constant BLS12_PAIRING_CHECK = 0x0f;
    uint256 private constant BLS12_MAP_FP2_TO_G2 = 0x11;

    // BLS12-381 prime subgroup order r.
    uint256 private constant BLS12_SCALAR_FIELD_ORDER =
        0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001;

    // -G1 generator for BLS12-381, represented as (x_hi, x_lo, y_hi, y_lo).
    uint128 private constant NEG_G1_X_HI = 0x17f1d3a73197d7942695638c4fa9ac0f;
    uint256 private constant NEG_G1_X_LO = 0xc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb;
    uint128 private constant NEG_G1_Y_HI = 0x114d1d6855d545a8aa7d76c8cf2e21f2;
    uint256 private constant NEG_G1_Y_LO = 0x67816aef1db507c96655b9d5caac42364e6f38ba0ecb751bad54dcd6b939c2ca;

    struct Fp2 {
        uint128 c1_hi;
        uint256 c1_lo;
        uint128 c0_hi;
        uint256 c0_lo;
    }

    /// @notice Decompresses a compressed BLS12-381 G2 signature into uncompressed form.
    /// @dev Parses compressed bytes into a G2 point, then marshals back to 192-byte encoding.
    /// @param compressedSig The 96-byte compressed G2 signature.
    /// @return The 192-byte uncompressed G2 signature bytes.
    function decompressG2Signature(bytes memory compressedSig) internal view returns (bytes memory) {
        return BLS2.g2Marshal(_g2UnmarshalCompressed(compressedSig));
    }

    /// @notice Verifies a drand default network signature against a digest and public key.
    /// @dev Accepts signature bytes in compressed (96) or uncompressed (192) G2 encodings.
    /// @param signature The signature bytes to verify.
    /// @param pubkey The drand public key in G1 form.
    /// @param dst The domain separation tag for hash-to-curve.
    /// @param digest The 32-byte message digest to verify (already chained-hashed by caller).
    /// @return True if parsing succeeds and pairing check validates; otherwise false.
    function verifyDefaultSignature(
        bytes memory signature,
        BLS2.PointG1 memory pubkey,
        bytes memory dst,
        bytes32 digest
    ) internal view returns (bool) {
        BLS2.PointG2 memory signaturePoint;

        if (signature.length == UNCOMPRESSED_G2_SIG_LENGTH) {
            signaturePoint = BLS2.g2Unmarshal(signature);
        } else if (signature.length == COMPRESSED_G2_SIG_LENGTH) {
            signaturePoint = _g2UnmarshalCompressed(signature);
        } else {
            return false;
        }

        if (_isG2Infinity(signaturePoint)) return false;
        if (!_isInG2Subgroup(signaturePoint)) return false;

        uint256[8] memory signatureWords = _pointG2ToPairingWords(signaturePoint);
        (uint256[8] memory messageWords0, uint256[8] memory messageWords1) =
            _hashToPointG2Parts(dst, abi.encodePacked(digest));

        (bool pairingSuccess, bool callSuccess) = _verifySingleG2(signatureWords, pubkey, messageWords0, messageWords1);
        return pairingSuccess && callSuccess;
    }

    /// @notice Unmarshals a compressed G2 point according to drand/EIP-2537-compatible encoding rules.
    /// @dev Validates compression flags, rejects infinity encoding, enforces canonical field limbs,
    ///      reconstructs y from curve equation in Fp2, and applies sign-bit lexicographic selection.
    /// @param m The compressed G2 encoding (must be 96 bytes).
    /// @return The decoded G2 point with x/y limbs.
    function _g2UnmarshalCompressed(bytes memory m) internal view returns (BLS2.PointG2 memory) {
        require(m.length == COMPRESSED_G2_SIG_LENGTH, "Invalid G2 bytes length");

        uint128 x1_hi;
        uint256 x1_lo;
        uint128 x0_hi;
        uint256 x0_lo;
        uint8 flags;

        assembly {
            x1_hi := shr(128, mload(add(m, 0x20)))
            x1_lo := mload(add(m, 0x30))
            x0_hi := shr(128, mload(add(m, 0x50)))
            x0_lo := mload(add(m, 0x60))
            flags := byte(16, x1_hi)
        }

        if (flags & 0x80 == 0) {
            revert("Invalid G2 point: not compressed");
        }
        if (flags & 0x40 != 0) {
            revert("unsupported: point at infinity");
        }

        x1_hi &= CLEAR_COMPRESSED_FLAGS_MASK;

        require(_fpLtP(x1_hi, x1_lo), "Invalid G2 point: non-canonical x1");
        require(_fpLtP(x0_hi, x0_lo), "Invalid G2 point: non-canonical x0");

        bool largest = (flags & 0x20) != 0;

        Fp2 memory x = Fp2({c1_hi: x1_hi, c1_lo: x1_lo, c0_hi: x0_hi, c0_lo: x0_lo});
        Fp2 memory x2 = _fp2Mul(x, x);
        Fp2 memory x3 = _fp2Mul(x2, x);
        Fp2 memory rhs = _fp2Add(x3, _fp2Const(0, 4, 0, 4));

        (Fp2 memory y, bool ok) = _fp2Sqrt(rhs);
        require(ok, "Invalid G2 point: no square root");

        bool isLargest = _isLexicographicallyLargest(y.c1_hi, y.c1_lo, y.c0_hi, y.c0_lo);
        if (isLargest != largest) {
            (y.c1_hi, y.c1_lo) = _fpNeg(y.c1_hi, y.c1_lo);
            (y.c0_hi, y.c0_lo) = _fpNeg(y.c0_hi, y.c0_lo);
        }

        return BLS2.PointG2(x1_hi, x1_lo, x0_hi, x0_lo, y.c1_hi, y.c1_lo, y.c0_hi, y.c0_lo);
    }

    /// @notice Computes a square root in Fp2.
    /// @dev For zero imaginary part, tries real root first and then pure-imaginary root; otherwise
    ///      dispatches to the generic non-zero-imaginary algorithm.
    /// @param z The Fp2 element to root.
    /// @return y A candidate square root when one exists, otherwise zero.
    /// @return ok True if a valid square root was found.
    function _fp2Sqrt(Fp2 memory z) internal view returns (Fp2 memory y, bool ok) {
        if (_fpIsZero(z.c1_hi, z.c1_lo)) {
            (uint128 y0Hi, uint256 y0Lo, bool hasRoot) = _fpSqrt(z.c0_hi, z.c0_lo);
            if (hasRoot) {
                return (_fp2Const(0, 0, y0Hi, y0Lo), true);
            }

            (uint128 nyHi, uint256 nyLo) = _fpNeg(z.c0_hi, z.c0_lo);
            (uint128 y1Hi, uint256 y1Lo, bool hasImagRoot) = _fpSqrt(nyHi, nyLo);
            if (hasImagRoot) {
                return (_fp2Const(y1Hi, y1Lo, 0, 0), true);
            }
            return (_fp2Const(0, 0, 0, 0), false);
        }

        return _fp2SqrtImaginaryNonZero(z.c1_hi, z.c1_lo, z.c0_hi, z.c0_lo);
    }

    /// @notice Computes sqrt(a + i*b) in Fp2 for the branch where b != 0.
    /// @dev Uses norm-based reconstruction: compute t = sqrt(a^2 + b^2), derive y0 from (a ± t)/2,
    ///      recover y1 = b / (2*y0), then verify by squaring.
    /// @param bHi High 128 bits of imaginary limb b.
    /// @param bLo Low 256 bits of imaginary limb b.
    /// @param aHi High 128 bits of real limb a.
    /// @param aLo Low 256 bits of real limb a.
    /// @return y Candidate Fp2 root.
    /// @return ok True if reconstruction and final square check succeed.
    function _fp2SqrtImaginaryNonZero(uint128 bHi, uint256 bLo, uint128 aHi, uint256 aLo)
        internal
        view
        returns (Fp2 memory y, bool ok)
    {
        (uint128 tHi, uint256 tLo, bool hasTSqrt) = _fp2NormSqrt(aHi, aLo, bHi, bLo);
        if (!hasTSqrt) {
            return (_fp2Const(0, 0, 0, 0), false);
        }

        (uint128 y0Hi, uint256 y0Lo, bool hasY0) = _fp2SqrtRealComponent(aHi, aLo, tHi, tLo);
        if (!hasY0) {
            return (_fp2Const(0, 0, 0, 0), false);
        }

        (uint128 y1Hi, uint256 y1Lo) = _fp2RecoverImaginaryPart(bHi, bLo, y0Hi, y0Lo);

        y = _fp2Const(y1Hi, y1Lo, y0Hi, y0Lo);
        ok = _fp2SquareEquals(y, bHi, bLo, aHi, aLo);
    }

    /// @notice Checks whether y^2 equals the target Fp2 value (a + i*b).
    /// @param y The candidate Fp2 square root.
    /// @param bHi High 128 bits of target imaginary limb.
    /// @param bLo Low 256 bits of target imaginary limb.
    /// @param aHi High 128 bits of target real limb.
    /// @param aLo Low 256 bits of target real limb.
    /// @return True if squaring y reproduces the target element.
    function _fp2SquareEquals(Fp2 memory y, uint128 bHi, uint256 bLo, uint128 aHi, uint256 aLo)
        internal
        view
        returns (bool)
    {
        return _fp2Eq(_fp2Mul(y, y), _fp2Const(bHi, bLo, aHi, aLo));
    }

    /// @notice Computes sqrt(a^2 + b^2) in Fp, used as intermediate norm term for Fp2 sqrt.
    /// @param aHi High 128 bits of real limb a.
    /// @param aLo Low 256 bits of real limb a.
    /// @param bHi High 128 bits of imaginary limb b.
    /// @param bLo Low 256 bits of imaginary limb b.
    /// @return tHi High 128 bits of sqrt(a^2 + b^2) when it exists.
    /// @return tLo Low 256 bits of sqrt(a^2 + b^2) when it exists.
    /// @return ok True if the norm has a square root.
    function _fp2NormSqrt(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo)
        internal
        view
        returns (uint128 tHi, uint256 tLo, bool ok)
    {
        (uint128 a2Hi, uint256 a2Lo) = _fpMul(aHi, aLo, aHi, aLo);
        (uint128 b2Hi, uint256 b2Lo) = _fpMul(bHi, bLo, bHi, bLo);
        (uint128 sumHi, uint256 sumLo) = _fpAddMod(a2Hi, a2Lo, b2Hi, b2Lo);
        return _fpSqrt(sumHi, sumLo);
    }

    /// @notice Recovers imaginary component y1 from b and y0 using y1 = b / (2*y0).
    /// @param bHi High 128 bits of target imaginary limb b.
    /// @param bLo Low 256 bits of target imaginary limb b.
    /// @param y0Hi High 128 bits of already-derived real root component y0.
    /// @param y0Lo Low 256 bits of already-derived real root component y0.
    /// @return y1Hi High 128 bits of reconstructed imaginary component.
    /// @return y1Lo Low 256 bits of reconstructed imaginary component.
    function _fp2RecoverImaginaryPart(uint128 bHi, uint256 bLo, uint128 y0Hi, uint256 y0Lo)
        internal
        view
        returns (uint128 y1Hi, uint256 y1Lo)
    {
        (uint128 twoY0Hi, uint256 twoY0Lo) = _fpAddMod(y0Hi, y0Lo, y0Hi, y0Lo);
        (uint128 invTwoY0Hi, uint256 invTwoY0Lo) = _fpInv(twoY0Hi, twoY0Lo);
        return _fpMul(bHi, bLo, invTwoY0Hi, invTwoY0Lo);
    }

    /// @notice Finds y0 satisfying y0^2 = (a ± t)/2 for Fp2 sqrt reconstruction.
    /// @dev Tries (a+t)/2 first, then falls back to (a-t)/2.
    /// @param aHi High 128 bits of real limb a.
    /// @param aLo Low 256 bits of real limb a.
    /// @param tHi High 128 bits of sqrt(a^2+b^2) term t.
    /// @param tLo Low 256 bits of sqrt(a^2+b^2) term t.
    /// @return y0Hi High 128 bits of selected real component.
    /// @return y0Lo Low 256 bits of selected real component.
    /// @return hasY0 True if either candidate produced a square root.
    function _fp2SqrtRealComponent(uint128 aHi, uint256 aLo, uint128 tHi, uint256 tLo)
        internal
        view
        returns (uint128 y0Hi, uint256 y0Lo, bool hasY0)
    {
        (uint128 candHi, uint256 candLo) = _fpAddMod(aHi, aLo, tHi, tLo);
        (candHi, candLo) = _fpDiv2Mod(candHi, candLo);

        (y0Hi, y0Lo, hasY0) = _fpSqrt(candHi, candLo);
        if (hasY0) {
            return (y0Hi, y0Lo, true);
        }

        (candHi, candLo) = _fpSubMod(aHi, aLo, tHi, tLo);
        (candHi, candLo) = _fpDiv2Mod(candHi, candLo);
        return _fpSqrt(candHi, candLo);
    }

    /// @notice Checks if an Fp2 element is lexicographically larger than (p-1)/2 under drand sign convention.
    /// @dev Compares c1 first when non-zero, otherwise compares c0.
    /// @param c1Hi High 128 bits of imaginary limb c1.
    /// @param c1Lo Low 256 bits of imaginary limb c1.
    /// @param c0Hi High 128 bits of real limb c0.
    /// @param c0Lo Low 256 bits of real limb c0.
    /// @return True if element is considered the "largest" representative.
    function _isLexicographicallyLargest(uint128 c1Hi, uint256 c1Lo, uint128 c0Hi, uint256 c0Lo)
        internal
        pure
        returns (bool)
    {
        if (!_fpIsZero(c1Hi, c1Lo)) {
            return _fpGt(c1Hi, c1Lo, P_MINUS_ONE_DIV_2_HI, P_MINUS_ONE_DIV_2_LO);
        }
        return _fpGt(c0Hi, c0Lo, P_MINUS_ONE_DIV_2_HI, P_MINUS_ONE_DIV_2_LO);
    }

    /// @notice Computes square root in Fp using exponentiation for p % 4 == 3.
    /// @param aHi High 128 bits of field element.
    /// @param aLo Low 256 bits of field element.
    /// @return rootHi High 128 bits of candidate root.
    /// @return rootLo Low 256 bits of candidate root.
    /// @return hasRoot True if root^2 equals input.
    function _fpSqrt(uint128 aHi, uint256 aLo) internal view returns (uint128 rootHi, uint256 rootLo, bool hasRoot) {
        if (_fpIsZero(aHi, aLo)) {
            return (0, 0, true);
        }

        (rootHi, rootLo) = _fpModExp(aHi, aLo, P_PLUS_ONE_DIV_4_HI, P_PLUS_ONE_DIV_4_LO);
        (uint128 sqHi, uint256 sqLo) = _fpMul(rootHi, rootLo, rootHi, rootLo);
        hasRoot = _fpEq(sqHi, sqLo, aHi, aLo);
    }

    /// @notice Computes multiplicative inverse in Fp via exponentiation to p-2.
    /// @param aHi High 128 bits of non-zero field element.
    /// @param aLo Low 256 bits of non-zero field element.
    /// @return outHi High 128 bits of inverse.
    /// @return outLo Low 256 bits of inverse.
    function _fpInv(uint128 aHi, uint256 aLo) internal view returns (uint128 outHi, uint256 outLo) {
        require(!_fpIsZero(aHi, aLo), "inverse of zero");
        return _fpModExp(aHi, aLo, P_MINUS_2_HI, P_MINUS_2_LO);
    }

    /// @notice Multiplies two Fp elements modulo p.
    /// @dev Uses Karatsuba-style identity from squares and additions to reduce explicit multiplications.
    /// @param aHi High 128 bits of multiplicand a.
    /// @param aLo Low 256 bits of multiplicand a.
    /// @param bHi High 128 bits of multiplicand b.
    /// @param bLo Low 256 bits of multiplicand b.
    /// @return outHi High 128 bits of product modulo p.
    /// @return outLo Low 256 bits of product modulo p.
    function _fpMul(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo)
        internal
        view
        returns (uint128 outHi, uint256 outLo)
    {
        (uint128 sHi, uint256 sLo) = _fpAddMod(aHi, aLo, bHi, bLo);
        (uint128 s2Hi, uint256 s2Lo) = _fpSquare(sHi, sLo);
        (uint128 a2Hi, uint256 a2Lo) = _fpSquare(aHi, aLo);
        (uint128 b2Hi, uint256 b2Lo) = _fpSquare(bHi, bLo);

        (uint128 tHi, uint256 tLo) = _fpSubMod(s2Hi, s2Lo, a2Hi, a2Lo);
        (tHi, tLo) = _fpSubMod(tHi, tLo, b2Hi, b2Lo);
        return _fpDiv2Mod(tHi, tLo);
    }

    /// @notice Squares an Fp element modulo p.
    /// @param aHi High 128 bits of input element.
    /// @param aLo Low 256 bits of input element.
    /// @return outHi High 128 bits of squared value modulo p.
    /// @return outLo Low 256 bits of squared value modulo p.
    function _fpSquare(uint128 aHi, uint256 aLo) internal view returns (uint128 outHi, uint256 outLo) {
        return _fpModExp(aHi, aLo, 0, 2);
    }

    /// @notice Computes modular exponentiation in Fp using MODEXP precompile (0x05).
    /// @param baseHi High 128 bits of base.
    /// @param baseLo Low 256 bits of base.
    /// @param expHi High 128 bits of exponent.
    /// @param expLo Low 256 bits of exponent.
    /// @return outHi High 128 bits of (base^exp mod p).
    /// @return outLo Low 256 bits of (base^exp mod p).
    function _fpModExp(uint128 baseHi, uint256 baseLo, uint128 expHi, uint256 expLo)
        internal
        view
        returns (uint128 outHi, uint256 outLo)
    {
        bytes memory inBuf = new bytes(288);
        bytes memory outBuf = new bytes(64);
        bool ok;

        assembly {
            let p := add(inBuf, 32)
            mstore(p, 64)
            p := add(p, 32)
            mstore(p, 64)
            p := add(p, 32)
            mstore(p, 64)
            p := add(p, 32)

            mstore(p, baseHi)
            p := add(p, 32)
            mstore(p, baseLo)
            p := add(p, 32)

            mstore(p, expHi)
            p := add(p, 32)
            mstore(p, expLo)
            p := add(p, 32)

            mstore(p, P_HI)
            p := add(p, 32)
            mstore(p, P_LO)

            ok := staticcall(gas(), MODEXP_ADDRESS, add(inBuf, 32), 288, add(outBuf, 32), 64)

            outHi := mload(add(outBuf, 32))
            outLo := mload(add(outBuf, 64))
        }

        require(ok, "modexp failed");
    }

    /// @notice Adds two Fp elements modulo p.
    /// @param aHi High 128 bits of addend a.
    /// @param aLo Low 256 bits of addend a.
    /// @param bHi High 128 bits of addend b.
    /// @param bLo Low 256 bits of addend b.
    /// @return outHi High 128 bits of sum modulo p.
    /// @return outLo Low 256 bits of sum modulo p.
    function _fpAddMod(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo)
        internal
        pure
        returns (uint128 outHi, uint256 outLo)
    {
        unchecked {
            outLo = aLo + bLo;
            uint256 carry = outLo < aLo ? 1 : 0;
            outHi = uint128(uint256(aHi) + uint256(bHi) + carry);
        }

        if (!_fpLtP(outHi, outLo)) {
            (outHi, outLo) = _fpSubRaw(outHi, outLo, P_HI, P_LO);
        }
    }

    /// @notice Subtracts two Fp elements modulo p.
    /// @param aHi High 128 bits of minuend a.
    /// @param aLo Low 256 bits of minuend a.
    /// @param bHi High 128 bits of subtrahend b.
    /// @param bLo Low 256 bits of subtrahend b.
    /// @return outHi High 128 bits of difference modulo p.
    /// @return outLo Low 256 bits of difference modulo p.
    function _fpSubMod(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo)
        internal
        pure
        returns (uint128 outHi, uint256 outLo)
    {
        if (_fpGte(aHi, aLo, bHi, bLo)) {
            return _fpSubRaw(aHi, aLo, bHi, bLo);
        }

        (uint128 tHi, uint256 tLo) = _fpSubRaw(bHi, bLo, aHi, aLo);
        return _fpSubRaw(P_HI, P_LO, tHi, tLo);
    }

    /// @notice Divides an Fp element by 2 modulo p.
    /// @dev Adds p first when input is odd, then shifts right.
    /// @param aHi High 128 bits of input element.
    /// @param aLo Low 256 bits of input element.
    /// @return outHi High 128 bits of halved value modulo p.
    /// @return outLo Low 256 bits of halved value modulo p.
    function _fpDiv2Mod(uint128 aHi, uint256 aLo) internal pure returns (uint128 outHi, uint256 outLo) {
        if (aLo & 1 == 1) {
            (aHi, aLo) = _fpAddRaw(aHi, aLo, P_HI, P_LO);
        }

        outLo = (aLo >> 1) | (uint256(aHi & 1) << 255);
        outHi = aHi >> 1;
    }

    /// @notice Negates an Fp element modulo p.
    /// @param aHi High 128 bits of input element.
    /// @param aLo Low 256 bits of input element.
    /// @return outHi High 128 bits of additive inverse modulo p.
    /// @return outLo Low 256 bits of additive inverse modulo p.
    function _fpNeg(uint128 aHi, uint256 aLo) internal pure returns (uint128 outHi, uint256 outLo) {
        if (_fpIsZero(aHi, aLo)) {
            return (0, 0);
        }
        return _fpSubRaw(P_HI, P_LO, aHi, aLo);
    }

    /// @notice Adds two split-limb integers without modular reduction.
    /// @param aHi High 128 bits of addend a.
    /// @param aLo Low 256 bits of addend a.
    /// @param bHi High 128 bits of addend b.
    /// @param bLo Low 256 bits of addend b.
    /// @return outHi High 128 bits of raw sum.
    /// @return outLo Low 256 bits of raw sum.
    function _fpAddRaw(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo)
        internal
        pure
        returns (uint128 outHi, uint256 outLo)
    {
        unchecked {
            outLo = aLo + bLo;
            uint256 carry = outLo < aLo ? 1 : 0;
            outHi = uint128(uint256(aHi) + uint256(bHi) + carry);
        }
    }

    /// @notice Subtracts two split-limb integers without modular reduction.
    /// @param aHi High 128 bits of minuend a.
    /// @param aLo Low 256 bits of minuend a.
    /// @param bHi High 128 bits of subtrahend b.
    /// @param bLo Low 256 bits of subtrahend b.
    /// @return outHi High 128 bits of raw difference.
    /// @return outLo Low 256 bits of raw difference.
    function _fpSubRaw(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo)
        internal
        pure
        returns (uint128 outHi, uint256 outLo)
    {
        unchecked {
            uint256 borrow = aLo < bLo ? 1 : 0;
            outLo = aLo - bLo;
            outHi = uint128(uint256(aHi) - uint256(bHi) - borrow);
        }
    }

    /// @notice Checks whether a split-limb value is strictly less than field modulus p.
    /// @param aHi High 128 bits of input value.
    /// @param aLo Low 256 bits of input value.
    /// @return True if input < p.
    function _fpLtP(uint128 aHi, uint256 aLo) internal pure returns (bool) {
        return _fpLt(aHi, aLo, P_HI, P_LO);
    }

    /// @notice Compares two split-limb values for strict less-than.
    /// @param aHi High 128 bits of a.
    /// @param aLo Low 256 bits of a.
    /// @param bHi High 128 bits of b.
    /// @param bLo Low 256 bits of b.
    /// @return True if a < b.
    function _fpLt(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo) internal pure returns (bool) {
        if (aHi < bHi) return true;
        if (aHi > bHi) return false;
        return aLo < bLo;
    }

    /// @notice Compares two split-limb values for strict greater-than.
    /// @param aHi High 128 bits of a.
    /// @param aLo Low 256 bits of a.
    /// @param bHi High 128 bits of b.
    /// @param bLo Low 256 bits of b.
    /// @return True if a > b.
    function _fpGt(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo) internal pure returns (bool) {
        if (aHi > bHi) return true;
        if (aHi < bHi) return false;
        return aLo > bLo;
    }

    /// @notice Compares two split-limb values for greater-than-or-equal.
    /// @param aHi High 128 bits of a.
    /// @param aLo Low 256 bits of a.
    /// @param bHi High 128 bits of b.
    /// @param bLo Low 256 bits of b.
    /// @return True if a >= b.
    function _fpGte(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo) internal pure returns (bool) {
        if (aHi > bHi) return true;
        if (aHi < bHi) return false;
        return aLo >= bLo;
    }

    /// @notice Compares two split-limb values for equality.
    /// @param aHi High 128 bits of a.
    /// @param aLo Low 256 bits of a.
    /// @param bHi High 128 bits of b.
    /// @param bLo Low 256 bits of b.
    /// @return True if a equals b.
    function _fpEq(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo) internal pure returns (bool) {
        return aHi == bHi && aLo == bLo;
    }

    /// @notice Checks whether a split-limb value is zero.
    /// @param aHi High 128 bits of input.
    /// @param aLo Low 256 bits of input.
    /// @return True if both limbs are zero.
    function _fpIsZero(uint128 aHi, uint256 aLo) internal pure returns (bool) {
        return aHi == 0 && aLo == 0;
    }

    /// @notice Multiplies two Fp2 elements.
    /// @param a The first Fp2 multiplicand.
    /// @param b The second Fp2 multiplicand.
    /// @return out The product in Fp2.
    function _fp2Mul(Fp2 memory a, Fp2 memory b) internal view returns (Fp2 memory out) {
        (uint128 a0b0Hi, uint256 a0b0Lo) = _fpMul(a.c0_hi, a.c0_lo, b.c0_hi, b.c0_lo);
        (uint128 a1b1Hi, uint256 a1b1Lo) = _fpMul(a.c1_hi, a.c1_lo, b.c1_hi, b.c1_lo);

        (uint128 realHi, uint256 realLo) = _fpSubMod(a0b0Hi, a0b0Lo, a1b1Hi, a1b1Lo);

        (uint128 a0b1Hi, uint256 a0b1Lo) = _fpMul(a.c0_hi, a.c0_lo, b.c1_hi, b.c1_lo);
        (uint128 a1b0Hi, uint256 a1b0Lo) = _fpMul(a.c1_hi, a.c1_lo, b.c0_hi, b.c0_lo);
        (uint128 imagHi, uint256 imagLo) = _fpAddMod(a0b1Hi, a0b1Lo, a1b0Hi, a1b0Lo);

        out = _fp2Const(imagHi, imagLo, realHi, realLo);
    }

    /// @notice Adds two Fp2 elements.
    /// @param a The first Fp2 addend.
    /// @param b The second Fp2 addend.
    /// @return out The sum in Fp2.
    function _fp2Add(Fp2 memory a, Fp2 memory b) internal pure returns (Fp2 memory out) {
        (uint128 c1Hi, uint256 c1Lo) = _fpAddMod(a.c1_hi, a.c1_lo, b.c1_hi, b.c1_lo);
        (uint128 c0Hi, uint256 c0Lo) = _fpAddMod(a.c0_hi, a.c0_lo, b.c0_hi, b.c0_lo);
        out = _fp2Const(c1Hi, c1Lo, c0Hi, c0Lo);
    }

    /// @notice Compares two Fp2 elements for equality.
    /// @param a The first Fp2 element.
    /// @param b The second Fp2 element.
    /// @return True if both real and imaginary limbs match.
    function _fp2Eq(Fp2 memory a, Fp2 memory b) internal pure returns (bool) {
        return _fpEq(a.c1_hi, a.c1_lo, b.c1_hi, b.c1_lo) && _fpEq(a.c0_hi, a.c0_lo, b.c0_hi, b.c0_lo);
    }

    /// @notice Constructs an Fp2 element from split limbs.
    /// @param c1Hi High 128 bits of imaginary limb.
    /// @param c1Lo Low 256 bits of imaginary limb.
    /// @param c0Hi High 128 bits of real limb.
    /// @param c0Lo Low 256 bits of real limb.
    /// @return out The constructed Fp2 element.
    function _fp2Const(uint128 c1Hi, uint256 c1Lo, uint128 c0Hi, uint256 c0Lo) internal pure returns (Fp2 memory out) {
        out = Fp2({c1_hi: c1Hi, c1_lo: c1Lo, c0_hi: c0Hi, c0_lo: c0Lo});
    }

    /// @notice Verifies e(-g1, sig) * e(pk, H(m)_0) * e(pk, H(m)_1) == 1 using pairing precompile.
    /// @dev Inputs are arranged for EIP-2537 pairing precompile at address 0x0f.
    /// @param signature Signature point words in pairing input order.
    /// @param pubkey Public key in G1 form.
    /// @param messagePart0 First G2 point from hash-to-curve mapping.
    /// @param messagePart1 Second G2 point from hash-to-curve mapping.
    /// @return pairingSuccess True if precompile output equals 1.
    /// @return callSuccess True if the precompile call itself succeeded.
    function _verifySingleG2(
        uint256[8] memory signature,
        BLS2.PointG1 memory pubkey,
        uint256[8] memory messagePart0,
        uint256[8] memory messagePart1
    ) internal view returns (bool pairingSuccess, bool callSuccess) {
        uint256[36] memory input = [
            uint256(NEG_G1_X_HI),
            NEG_G1_X_LO,
            uint256(NEG_G1_Y_HI),
            NEG_G1_Y_LO,
            signature[0],
            signature[1],
            signature[2],
            signature[3],
            signature[4],
            signature[5],
            signature[6],
            signature[7],
            uint256(pubkey.x_hi),
            pubkey.x_lo,
            uint256(pubkey.y_hi),
            pubkey.y_lo,
            messagePart0[0],
            messagePart0[1],
            messagePart0[2],
            messagePart0[3],
            messagePart0[4],
            messagePart0[5],
            messagePart0[6],
            messagePart0[7],
            uint256(pubkey.x_hi),
            pubkey.x_lo,
            uint256(pubkey.y_hi),
            pubkey.y_lo,
            messagePart1[0],
            messagePart1[1],
            messagePart1[2],
            messagePart1[3],
            messagePart1[4],
            messagePart1[5],
            messagePart1[6],
            messagePart1[7]
        ];

        uint256[1] memory out;
        assembly {
            callSuccess := staticcall(gas(), BLS12_PAIRING_CHECK, input, 1152, out, 0x20)
        }
        return (out[0] != 0, callSuccess);
    }

    /// @notice Hashes message to two G2 points (message expansion + map-to-curve) for default network verification.
    /// @dev Uses RFC9380-style expand-message output, reduces each Fp limb mod p, then calls map_fp2_to_g2
    ///      precompile twice (p0 and p1).
    /// @param dst Domain separation tag bytes.
    /// @param message Message bytes to hash (digest bytes from caller).
    /// @return out0 First mapped G2 point represented as pairing words.
    /// @return out1 Second mapped G2 point represented as pairing words.
    function _hashToPointG2Parts(bytes memory dst, bytes memory message)
        internal
        view
        returns (uint256[8] memory out0, uint256[8] memory out1)
    {
        bytes memory uniformBytes = _expandMsg(dst, message, 256);

        for (uint256 i = 0; i < 4; i++) {
            _modPInPlace(uniformBytes, i * 64);
        }

        bool ok;

        assembly {
            ok := staticcall(gas(), BLS12_MAP_FP2_TO_G2, add(uniformBytes, 32), 128, out0, 256)
        }
        require(ok, "map_fp2_to_g2 p0 failed");

        assembly {
            ok := staticcall(gas(), BLS12_MAP_FP2_TO_G2, add(add(uniformBytes, 32), 128), 128, out1, 256)
        }
        require(ok, "map_fp2_to_g2 p1 failed");
    }

    /// @notice Converts a G2 point struct into the word ordering required by pairing precompile inputs.
    /// @param point The G2 point to convert.
    /// @return out Eight 32-byte words ordered as x0, x1, y0, y1 split into hi/lo limbs.
    function _pointG2ToPairingWords(BLS2.PointG2 memory point) internal pure returns (uint256[8] memory out) {
        out[0] = uint256(point.x0_hi);
        out[1] = point.x0_lo;
        out[2] = uint256(point.x1_hi);
        out[3] = point.x1_lo;
        out[4] = uint256(point.y0_hi);
        out[5] = point.y0_lo;
        out[6] = uint256(point.y1_hi);
        out[7] = point.y1_lo;
    }

    /// @notice Checks G2 subgroup membership by evaluating [r]P == infinity via BLS12_G2MSM precompile.
    function _isInG2Subgroup(BLS2.PointG2 memory point) internal view returns (bool) {
        uint256[8] memory pointWords = _pointG2ToPairingWords(point);
        uint256[9] memory input = [
            pointWords[0],
            pointWords[1],
            pointWords[2],
            pointWords[3],
            pointWords[4],
            pointWords[5],
            pointWords[6],
            pointWords[7],
            BLS12_SCALAR_FIELD_ORDER
        ];

        uint256[8] memory out;
        bool ok;
        assembly {
            ok := staticcall(gas(), BLS12_G2MSM, input, 288, out, 256)
        }
        require(ok, "g2msm failed");
        return _isG2InfinityWords(out);
    }

    /// @notice Checks whether a G2 point struct encodes the point at infinity.
    function _isG2Infinity(BLS2.PointG2 memory point) internal pure returns (bool) {
        return point.x1_hi == 0 && point.x1_lo == 0 && point.x0_hi == 0 && point.x0_lo == 0 && point.y1_hi == 0
            && point.y1_lo == 0 && point.y0_hi == 0 && point.y0_lo == 0;
    }

    /// @notice Checks whether precompile-encoded G2 words represent point at infinity.
    function _isG2InfinityWords(uint256[8] memory pointWords) internal pure returns (bool) {
        for (uint256 i = 0; i < pointWords.length; i++) {
            if (pointWords[i] != 0) return false;
        }
        return true;
    }

    /// @notice Reduces a 64-byte limb chunk inside a byte buffer modulo p in-place.
    /// @dev Builds a MODEXP input for exponent 1 so output is equivalent to value mod p.
    /// @param input Buffer containing serialized 64-byte field elements.
    /// @param offset Byte offset where the target 64-byte element starts.
    function _modPInPlace(bytes memory input, uint256 offset) internal view {
        bytes memory buf = new bytes(225);
        bool ok;

        assembly {
            let p := add(buf, 32)
            mstore(p, 64)
            p := add(p, 32)
            mstore(p, 1)
            p := add(p, 32)
            mstore(p, 64)
            p := add(p, 32)

            let src := add(add(input, 32), offset)
            mcopy(p, src, 64)
            p := add(p, 64)

            mstore8(p, 1)
            p := add(p, 1)
            mstore(p, P_HI)
            p := add(p, 32)
            mstore(p, P_LO)

            ok := staticcall(gas(), MODEXP_ADDRESS, add(buf, 32), 225, src, 64)
        }

        require(ok, "modp failed");
    }

    /// @notice Expands a message into pseudo-random bytes using SHA-256 XMD-style chaining.
    /// @dev This helper follows the hash-to-curve expand_message_xmd pattern needed for drand default mapping.
    /// @param dst Domain separation tag bytes (max length 255).
    /// @param message Input message bytes to expand.
    /// @param nBytes Number of output bytes requested.
    /// @return out Expanded output byte string of length nBytes.
    function _expandMsg(bytes memory dst, bytes memory message, uint16 nBytes) internal pure returns (bytes memory) {
        uint256 domainLen = dst.length;
        require(domainLen <= 255, "dst too long");

        bytes memory zpad = new bytes(64);
        bytes32 b0 = sha256(abi.encodePacked(zpad, message, bytes2(nBytes), uint8(0), dst, uint8(domainLen)));
        bytes32 bi = sha256(abi.encodePacked(b0, uint8(1), dst, uint8(domainLen)));

        bytes memory out = new bytes(nBytes);
        uint256 ell = (uint256(nBytes) + 31) >> 5;

        for (uint256 i = 1; i < ell; i++) {
            bytes32 tmp = bi;
            assembly {
                let p := add(add(out, 32), mul(32, sub(i, 1)))
                mstore(p, tmp)
            }
            bi = sha256(abi.encodePacked(b0 ^ bi, uint8(1 + i), dst, uint8(domainLen)));
        }

        assembly {
            let p := add(add(out, 32), mul(32, sub(ell, 1)))
            mstore(p, bi)
        }

        return out;
    }
}
