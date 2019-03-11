pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

library StringHelper {
  uint internal constant WORD_SIZE = 32;

  function copy(uint src, uint dest, uint len) internal pure {
    // Copy word-length chunks while possible
    for (; len >= WORD_SIZE; len -= WORD_SIZE) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += WORD_SIZE;
      src += WORD_SIZE;
    }

    // Copy remaining bytes
    uint mask = 256 ** (WORD_SIZE - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }
  }

  function fromBytes(bytes memory bts) 
  internal pure returns (uint addr, uint len) {
    len = bts.length;
    assembly {
      addr := add(bts, /*BYTES_HEADER_SIZE*/32)
    }
  }

  function concat(bytes memory sel, bytes memory other)
  internal pure returns (bytes memory) {
    bytes memory ret = new bytes(sel.length + other.length);
    var (src, srcLen) = fromBytes(sel);
    var (src2, src2Len) = fromBytes(other);
    var (dest,) = fromBytes(ret);
    var dest2 = dest + src2Len;
    copy(src, dest, srcLen);
    copy(src2, dest2, src2Len);
    return ret;
  }

  function decimalJoin(string memory self, string memory s2) 
  internal pure returns (string memory) {
    bytes memory b1 = bytes(self);
    bytes memory b1_a = new bytes(b1.length + 1);
    for (uint i = 0; i <= b1.length; i ++) {
      require(
        (b1[i] >= 0x30 && b1[i] <= 0x39) ||
        (b1[i] >= 0x41 && b1[i] <= 0x5A) ||
        (b1[i] >= 0x61 && b1[i] <= 0x7A),
        "Invalid character."
      );
      b1_a[i] = i == b1.length ? bytes1(".") : b1[i];
    }
    bytes memory b2 = bytes(s2);
    return string(concat(b1_a, b2));
  }
}