#!/usr/bin/env python3
"""Generate SSZ golden vectors with Python stdlib only."""

from __future__ import annotations

from hashlib import sha256

ZERO_CHUNK = bytes(32)
HISTORICAL_BITS = 262144  # the historical-roots limit leanSpec runs with


def chunk(index: int) -> bytes:
    """The Bend test chunk: byte j is (index * j + 1) modulo 256."""
    return bytes(((index * j + 1) % 256) for j in range(32))


def u64_chunk(value: int) -> bytes:
    return value.to_bytes(8, "little") + b"\x00" * 24


def bool_chunk(bit: bool) -> bytes:
    return b"\x01" + b"\x00" * 31 if bit else b"\x00" * 32


def pack_bits(bits: list[bool]) -> bytes:
    out = bytearray()
    byte = 0
    for i, bit in enumerate(bits):
        if bit:
            byte |= 1 << (i % 8)
        if i % 8 == 7:
            out.append(byte)
            byte = 0
    if len(bits) % 8:
        out.append(byte)
    return bytes(out)


def byte_chunks(data: bytes) -> list[bytes]:
    return [data[i : i + 32].ljust(32, b"\0") for i in range(0, len(data) or 1, 32)]


def pair_hash(left: bytes, right: bytes) -> bytes:
    return sha256(left + right).digest()


def next_pow2(value: int) -> int:
    return 1 if value <= 1 else 1 << (value - 1).bit_length()


def zero_tree(depth: int) -> bytes:
    node = ZERO_CHUNK
    for _ in range(depth):
        node = pair_hash(node, node)
    return node


def merkleize_limit(leaves: list[bytes], limit: int) -> bytes:
    if len(leaves) > limit:
        raise ValueError("leaf count exceeds limit")
    width = next_pow2(limit)
    if not leaves:
        return zero_tree((width - 1).bit_length())

    data_width = next_pow2(len(leaves))
    level = list(leaves) + [ZERO_CHUNK] * (data_width - len(leaves))
    while len(level) > 1:
        level = [pair_hash(level[i], level[i + 1]) for i in range(0, len(level), 2)]

    node = level[0]
    data_depth = (data_width - 1).bit_length()
    for depth in range(data_depth, (width - 1).bit_length()):
        node = pair_hash(node, zero_tree(depth))
    return node


def mix_len(root: bytes, count: int) -> bytes:
    return sha256(root + u64_chunk(count)).digest()


def list_root(chunks: list[bytes], limit: int) -> bytes:
    return mix_len(merkleize_limit(chunks, limit), len(chunks))


def bitlist_root(bits: list[bool], limit_bits: int) -> bytes:
    limit_chunks = (limit_bits - 1) // 256 + 1
    return mix_len(merkleize_limit(byte_chunks(pack_bits(bits)), limit_chunks), len(bits))


def bytes52_root(key: bytes) -> bytes:
    assert len(key) == 52
    return sha256(key[:32] + key[32:].ljust(32, b"\0")).digest()


def packed(data: bytes) -> str:
    return ",".join(
        data[i : i + 32].ljust(32, b"\0").hex() for i in range(0, len(data), 32)
    )


def lines() -> list[str]:
    return [
        "u64-1000=" + u64_chunk(1000).hex(),
        "u64-2^32=" + u64_chunk(2**32).hex(),
        "bool-false=" + bool_chunk(False).hex(),
        "bool-true=" + bool_chunk(True).hex(),
        "pack-3=" + pack_bits([True, False, True]).hex(),
        "pack-9=" + pack_bits([True, False, False, True, True, True, False, False, True]).hex(),
        "byte-chunks-33=" + packed(bytes(range(33))),
        "list-root-1-1=" + list_root([ZERO_CHUNK], 1).hex(),
        "list-root-3-8=" + list_root([chunk(i) for i in range(3)], 8).hex(),
        "bitlist-root-empty=" + bitlist_root([], HISTORICAL_BITS).hex(),
        "bitlist-root-one=" + bitlist_root([True], HISTORICAL_BITS).hex(),
        "bitlist-root-3-16=" + bitlist_root([True, False, True], 16).hex(),
        "bitlist-root-9=" + bitlist_root([True, False, False, True, True, True, False, False, True], HISTORICAL_BITS).hex(),
        "bytes52-17=" + bytes52_root(bytes([17] * 52)).hex(),
        "zero-tree-10=" + zero_tree(10).hex(),
    ]


def main() -> None:
    # Cross-checks against the leanSpec-derived values the bend-client
    # conformance suite already pins, in addition to the spec formulas above.
    assert u64_chunk(1000) == bytes.fromhex("e803000000000000000000000000000000000000000000000000000000000000")
    assert bitlist_root([], HISTORICAL_BITS) == bytes.fromhex("ceb3266bf0938bc72f8256356ddc13bccc20dd767f25448b2658135780b7da51")
    assert bitlist_root([True], HISTORICAL_BITS) == bytes.fromhex("61f762b46f5120dfee3de7a38af55aa9b7463621e49589a4d784eb58daaa4b5b")
    for line in lines():
        print(line)


if __name__ == "__main__":
    main()
