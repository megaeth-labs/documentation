// SPDX-License-Identifier: VPL
pragma solidity ^0.8.34;

import {BLS2} from "../../lib/bls-solidity/src/libraries/BLS2.sol";
import {LibBLS} from "../../src/utils/LibBLS.sol";

contract LibBLSHarness {
    function decompressG2Signature(bytes calldata compressedSig) external view returns (bytes memory) {
        return LibBLS.decompressG2Signature(compressedSig);
    }

    function verifyDefaultSignature(
        bytes calldata signature,
        BLS2.PointG1 calldata pubkey,
        bytes calldata dst,
        bytes32 digest
    ) external view returns (bool) {
        return LibBLS.verifyDefaultSignature(signature, pubkey, dst, digest);
    }

    function g2UnmarshalCompressed(bytes calldata sig) external view returns (BLS2.PointG2 memory) {
        return LibBLS._g2UnmarshalCompressed(sig);
    }

    function fp2Sqrt(uint128 c1Hi, uint256 c1Lo, uint128 c0Hi, uint256 c0Lo)
        external
        view
        returns (LibBLS.Fp2 memory y, bool ok)
    {
        return LibBLS._fp2Sqrt(LibBLS.Fp2({c1_hi: c1Hi, c1_lo: c1Lo, c0_hi: c0Hi, c0_lo: c0Lo}));
    }

    function fp2SqrtImaginaryNonZero(uint128 bHi, uint256 bLo, uint128 aHi, uint256 aLo)
        external
        view
        returns (LibBLS.Fp2 memory y, bool ok)
    {
        return LibBLS._fp2SqrtImaginaryNonZero(bHi, bLo, aHi, aLo);
    }

    function fp2SquareEquals(
        uint128 y1Hi,
        uint256 y1Lo,
        uint128 y0Hi,
        uint256 y0Lo,
        uint128 bHi,
        uint256 bLo,
        uint128 aHi,
        uint256 aLo
    ) external view returns (bool) {
        LibBLS.Fp2 memory y = LibBLS.Fp2({c1_hi: y1Hi, c1_lo: y1Lo, c0_hi: y0Hi, c0_lo: y0Lo});
        return LibBLS._fp2SquareEquals(y, bHi, bLo, aHi, aLo);
    }

    function fp2NormSqrt(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo)
        external
        view
        returns (uint128 tHi, uint256 tLo, bool ok)
    {
        return LibBLS._fp2NormSqrt(aHi, aLo, bHi, bLo);
    }

    function fp2RecoverImaginaryPart(uint128 bHi, uint256 bLo, uint128 y0Hi, uint256 y0Lo)
        external
        view
        returns (uint128 y1Hi, uint256 y1Lo)
    {
        return LibBLS._fp2RecoverImaginaryPart(bHi, bLo, y0Hi, y0Lo);
    }

    function fp2SqrtRealComponent(uint128 aHi, uint256 aLo, uint128 tHi, uint256 tLo)
        external
        view
        returns (uint128 y0Hi, uint256 y0Lo, bool hasY0)
    {
        return LibBLS._fp2SqrtRealComponent(aHi, aLo, tHi, tLo);
    }

    function isLexicographicallyLargest(uint128 c1Hi, uint256 c1Lo, uint128 c0Hi, uint256 c0Lo)
        external
        pure
        returns (bool)
    {
        return LibBLS._isLexicographicallyLargest(c1Hi, c1Lo, c0Hi, c0Lo);
    }

    function fpSqrt(uint128 aHi, uint256 aLo) external view returns (uint128 rootHi, uint256 rootLo, bool hasRoot) {
        return LibBLS._fpSqrt(aHi, aLo);
    }

    function fpInv(uint128 aHi, uint256 aLo) external view returns (uint128 outHi, uint256 outLo) {
        return LibBLS._fpInv(aHi, aLo);
    }

    function fpMul(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo)
        external
        view
        returns (uint128 outHi, uint256 outLo)
    {
        return LibBLS._fpMul(aHi, aLo, bHi, bLo);
    }

    function fpSquare(uint128 aHi, uint256 aLo) external view returns (uint128 outHi, uint256 outLo) {
        return LibBLS._fpSquare(aHi, aLo);
    }

    function fpModExp(uint128 baseHi, uint256 baseLo, uint128 expHi, uint256 expLo)
        external
        view
        returns (uint128 outHi, uint256 outLo)
    {
        return LibBLS._fpModExp(baseHi, baseLo, expHi, expLo);
    }

    function fpAddMod(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo)
        external
        pure
        returns (uint128 outHi, uint256 outLo)
    {
        return LibBLS._fpAddMod(aHi, aLo, bHi, bLo);
    }

    function fpSubMod(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo)
        external
        pure
        returns (uint128 outHi, uint256 outLo)
    {
        return LibBLS._fpSubMod(aHi, aLo, bHi, bLo);
    }

    function fpDiv2Mod(uint128 aHi, uint256 aLo) external pure returns (uint128 outHi, uint256 outLo) {
        return LibBLS._fpDiv2Mod(aHi, aLo);
    }

    function fpNeg(uint128 aHi, uint256 aLo) external pure returns (uint128 outHi, uint256 outLo) {
        return LibBLS._fpNeg(aHi, aLo);
    }

    function fpAddRaw(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo)
        external
        pure
        returns (uint128 outHi, uint256 outLo)
    {
        return LibBLS._fpAddRaw(aHi, aLo, bHi, bLo);
    }

    function fpSubRaw(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo)
        external
        pure
        returns (uint128 outHi, uint256 outLo)
    {
        return LibBLS._fpSubRaw(aHi, aLo, bHi, bLo);
    }

    function fpLtP(uint128 aHi, uint256 aLo) external pure returns (bool) {
        return LibBLS._fpLtP(aHi, aLo);
    }

    function fpLt(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo) external pure returns (bool) {
        return LibBLS._fpLt(aHi, aLo, bHi, bLo);
    }

    function fpGt(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo) external pure returns (bool) {
        return LibBLS._fpGt(aHi, aLo, bHi, bLo);
    }

    function fpGte(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo) external pure returns (bool) {
        return LibBLS._fpGte(aHi, aLo, bHi, bLo);
    }

    function fpEq(uint128 aHi, uint256 aLo, uint128 bHi, uint256 bLo) external pure returns (bool) {
        return LibBLS._fpEq(aHi, aLo, bHi, bLo);
    }

    function fpIsZero(uint128 aHi, uint256 aLo) external pure returns (bool) {
        return LibBLS._fpIsZero(aHi, aLo);
    }

    function fp2Mul(LibBLS.Fp2 calldata a, LibBLS.Fp2 calldata b) external view returns (LibBLS.Fp2 memory out) {
        return LibBLS._fp2Mul(a, b);
    }

    function fp2Add(LibBLS.Fp2 calldata a, LibBLS.Fp2 calldata b) external pure returns (LibBLS.Fp2 memory out) {
        return LibBLS._fp2Add(a, b);
    }

    function fp2Eq(LibBLS.Fp2 calldata a, LibBLS.Fp2 calldata b) external pure returns (bool) {
        return LibBLS._fp2Eq(a, b);
    }

    function fp2Const(uint128 c1Hi, uint256 c1Lo, uint128 c0Hi, uint256 c0Lo)
        external
        pure
        returns (LibBLS.Fp2 memory out)
    {
        return LibBLS._fp2Const(c1Hi, c1Lo, c0Hi, c0Lo);
    }

    function verifySingleG2(
        uint256[8] calldata signature,
        BLS2.PointG1 calldata pubkey,
        uint256[8] calldata messagePart0,
        uint256[8] calldata messagePart1
    ) external view returns (bool pairingSuccess, bool callSuccess) {
        return LibBLS._verifySingleG2(signature, pubkey, messagePart0, messagePart1);
    }

    function hashToPointG2Parts(bytes calldata dst, bytes calldata message)
        external
        view
        returns (uint256[8] memory out0, uint256[8] memory out1)
    {
        return LibBLS._hashToPointG2Parts(dst, message);
    }

    function pointG2ToPairingWords(BLS2.PointG2 calldata point) external pure returns (uint256[8] memory out) {
        return LibBLS._pointG2ToPairingWords(point);
    }

    function modPInPlace(bytes calldata input, uint256 offset) external view returns (bytes memory out) {
        out = input;
        LibBLS._modPInPlace(out, offset);
    }

    function expandMsg(bytes calldata dst, bytes calldata message, uint16 nBytes) external pure returns (bytes memory) {
        return LibBLS._expandMsg(dst, message, nBytes);
    }
}
