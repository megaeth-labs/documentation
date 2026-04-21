// SPDX-License-Identifier: VPL
pragma solidity ^0.8.34;

/// @title LibHex
/// @notice Internal library for decoding ASCII hex strings into raw bytes.
library LibHex {
    /// @notice Decodes an ASCII hex string into raw bytes.
    /// @dev Returns `(false, "")` when length is odd or any nibble is not `[0-9a-fA-F]`.
    /// The input is expected without a `0x` prefix.
    /// @param hexString Hex string to decode.
    /// @return success Whether decoding succeeded.
    /// @return decoded Decoded bytes when successful, otherwise empty bytes.
    function _tryDecodeHex(string memory hexString) internal pure returns (bool, bytes memory) {
        bytes memory chars = bytes(hexString);
        uint256 charsLen = chars.length;
        if (charsLen % 2 != 0) return (false, bytes(""));

        bytes memory out = new bytes(charsLen / 2);
        for (uint256 i = 0; i < charsLen; i += 2) {
            (bool okHi, uint8 hi) = _hexNibble(chars[i]);
            if (!okHi) return (false, bytes(""));
            (bool okLo, uint8 lo) = _hexNibble(chars[i + 1]);
            if (!okLo) return (false, bytes(""));
            out[i / 2] = bytes1((hi << 4) | lo);
        }

        return (true, out);
    }

    /// @notice Converts a single ASCII hex character into its 4-bit value.
    /// @param c ASCII character expected in `[0-9a-fA-F]`.
    /// @return valid Whether `c` is a valid hex character.
    /// @return nibble The parsed nibble value when valid.
    function _hexNibble(bytes1 c) internal pure returns (bool, uint8) {
        uint8 v = uint8(c);
        if (v >= 48 && v <= 57) return (true, v - 48);
        if (v >= 65 && v <= 70) return (true, v - 55);
        if (v >= 97 && v <= 102) return (true, v - 87);
        return (false, 0);
    }
}
