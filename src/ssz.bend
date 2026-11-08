import Base
import ../deps/bend-merkle-tree/src/bytes.bend as B
import ../deps/bend-merkle-tree/src/merkle/chunk.bend as C
import ../deps/bend-merkle-tree/src/merkle/sha256.bend as MP
import ../deps/bend-merkle-tree/src/merkle/tree.bend as M

# SSZ serialization over the pinned bend-merkle-tree library.
#
# SSZ fixes the pair hash to SHA-256, so this layer binds the library's
# SHA-256 adapter directly instead of staying hash-generic. Capacity limits
# are arguments: callers keep their protocol-specific constants.

def zero32() -> List<&2, U32>:
  C.Chunk.zero()

def hash2(a: List<&2, U32>, b: List<&2, U32>) -> List<&2, U32>:
  MP.sha256_pair(a, b)

def zero_tree(depth: Nat) -> List<&2, U32>:
  M.tree.zero_tree(~MP.sha256_pair, depth)

def u64_chunk(n: Nat) -> List<&2, U32>:
  B.Bytes.append(B.Bytes.u64_le(n), B.Bytes.zeros(24n))

def bool_chunk(bit: Bool) -> List<&2, U32>:
  match bit:
    case False{}:
      zero32()
    case True{}:
      B.Bytes.append({[1] : List<&2, U32>}, B.Bytes.zeros(31n))

def mix_len(root: List<&2, U32>, n: Nat) -> List<&2, U32>:
  hash2(root, u64_chunk(n))

def merkle(+xs: List<&2, List<&2, U32>>) -> List<&2, U32>:
  M.tree.merkleize(~MP.sha256_pair, xs)

def merkle_limit(+xs: List<&2, List<&2, U32>>, limit: Nat) -> List<&2, U32>:
  M.tree.merkleize_limit(~MP.sha256_pair, xs, limit)

def list_root(+xs: List<&2, List<&2, U32>>, limit: Nat) -> List<&2, U32>:
  +n = List.length(&2, List<&2, U32>, xs)
  mix_len(merkle_limit(xs, limit), n)

def bytes52_root(+b: List<&2, U32>) -> List<&2, U32>:
  hash2(B.Bytes.take(b, 32n), B.Bytes.append(B.Bytes.drop(b, 32n), B.Bytes.zeros(12n)))

def chunk1(a: List<&2, U32>) -> List<&2, U32>:
  a

def chunk2(a: List<&2, U32>, b: List<&2, U32>) -> List<&2, U32>:
  hash2(a, b)

def chunk4(a: List<&2, U32>, b: List<&2, U32>, c: List<&2, U32>, d: List<&2, U32>)
  -> List<&2, U32>:
  hash2(hash2(a, b), hash2(c, d))

def repeat_byte(n: Nat, b: U32) -> List<&2, U32>:
  B.Bytes.rep(n, b)

# --- SSZ BitList packing -----------------------------------------------------

def maybe_bit(m: Maybe<&2, Bool>) -> U32:
  match m:
    case None{}:
      0
    case Some{False{}}:
      0
    case Some{True{}}:
      1

def bit_at(+bits: List<&2, Bool>, i: Nat) -> U32:
  maybe_bit(List.get(&2, Bool, bits, i))

def packed_byte(+bits: List<&2, Bool>) -> U32:
  (bit_at(bits, 0n)
    + U32.shln(bit_at(bits, 1n), 1n)
    + U32.shln(bit_at(bits, 2n), 2n)
    + U32.shln(bit_at(bits, 3n), 3n)
    + U32.shln(bit_at(bits, 4n), 4n)
    + U32.shln(bit_at(bits, 5n), 5n)
    + U32.shln(bit_at(bits, 6n), 6n)
    + U32.shln(bit_at(bits, 7n), 7n) : U32)

def pack_bits_go(fuel: Nat, +bits: List<&2, Bool>, empty: Bool) -> List<&2, U32>:
  match fuel:
    case 0n:
      Nil{}
    case 1n+p:
      match empty:
        case True{}:
          Nil{}
        case False{}:
          +rest = List.drop(&2, Bool, bits, 8n)
          packed_byte(bits) <> pack_bits_go(p, rest, List.is_empty(&2, Bool, rest))

def pack_bits(+bits: List<&2, Bool>) -> List<&2, U32>:
  pack_bits_go(32769n, bits, List.is_empty(&2, Bool, bits))

# --- byte chunking -----------------------------------------------------------

def pad_chunk(+bytes: List<&2, U32>) -> List<&2, U32>:
  B.Bytes.append(bytes, B.Bytes.zeros(Nat.sub(32n, B.Bytes.len(bytes))))

def byte_chunks_go(fuel: Nat, +bytes: List<&2, U32>, empty: Bool) -> List<&2, List<&2, U32>>:
  match fuel:
    case 0n:
      Nil{}
    case 1n+p:
      match empty:
        case True{}:
          Nil{}
        case False{}:
          +rest = B.Bytes.drop(bytes, 32n)
          pad_chunk(B.Bytes.take(bytes, 32n)) <> byte_chunks_go(p, rest, List.is_empty(&2, U32, rest))

def byte_chunks(+bytes: List<&2, U32>) -> List<&2, List<&2, U32>>:
  byte_chunks_go(32769n, bytes, List.is_empty(&2, U32, bytes))

# --- roots -------------------------------------------------------------------

def bit_chunk_limit(limit_bits: Nat) -> Nat:
  Nat.add(Nat.div(Nat.sub(limit_bits, 1n), 256n), 1n)

def bitlist_root(+bits: List<&2, Bool>, limit_bits: Nat) -> List<&2, U32>:
  +n = List.length(&2, Bool, bits)
  mix_len(merkle_limit(byte_chunks(pack_bits(bits)), bit_chunk_limit(limit_bits)), n)
