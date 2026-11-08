import Base
import ../deps/bend-merkle-tree/src/bytes.bend as B
import ../src/ssz.bend as S

# Golden vectors for the SSZ layer.
#
# The expectations come from the independent Python reference in
# tests/ssz_golden.py using hashlib.sha256, checked against the
# leanSpec-derived values the bend-client conformance suite pins.

def chunks_hex(+xs: List<&2, List<&2, U32>>) -> String:
  match xs:
    case Nil{}:
      ""
    case Con{h, Nil{}}:
      B.Bytes.hex(h)
    case Con{h, t}:
      B.Bytes.hex(h) ++ "," ++ chunks_hex(t)

def nine_bits() -> List<&2, Bool>:
  True{} <> False{} <> False{} <> True{} <> True{} <> True{} <> False{} <> False{} <> True{} <> Nil{}

def chunk_v(+i: Nat, k: Nat, acc: List<&2, U32>) -> List<&2, U32>:
  match k:
    case 0n:
      acc
    case 1n+ +p:
      +b = U32.from_nat(Nat.mod(Nat.add(Nat.mul(i, p), 1n), 256n))
      chunk_v(i, p, b <> acc)

def cs(i: Nat) -> List<&2, U32>:
  chunk_v(i, 32n, Nil{})

def chunks_go(n: Nat, acc: List<&2, List<&2, U32>>) -> List<&2, List<&2, U32>>:
  match n:
    case 0n:
      acc
    case 1n+ +p:
      chunks_go(p, cs(p) <> acc)

def chunks(+n: Nat) -> List<&2, List<&2, U32>>:
  chunks_go(n, Nil{})

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("u64-1000=" ++ B.Bytes.hex(S.u64_chunk(1000n)))
    IO.print("u64-2^32=" ++ B.Bytes.hex(S.u64_chunk(Nat.mul(2n, 2147483648n))))
    IO.print("bool-false=" ++ B.Bytes.hex(S.bool_chunk(False{})))
    IO.print("bool-true=" ++ B.Bytes.hex(S.bool_chunk(True{})))
    IO.print("pack-3=" ++ B.Bytes.hex(S.pack_bits(True{} <> False{} <> True{} <> Nil{})))
    IO.print("pack-9=" ++ B.Bytes.hex(S.pack_bits(nine_bits())))
    +data33 : List<&2, U32> = {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32] : List<&2, U32>}
    IO.print("byte-chunks-33=" ++ chunks_hex(S.byte_chunks(data33)))
    IO.print("list-root-1-1=" ++ B.Bytes.hex(S.list_root({[S.zero32()] : List<&2, List<&2, U32>>}, 1n)))
    IO.print("list-root-3-8=" ++ B.Bytes.hex(S.list_root(chunks(3n), 8n)))
    IO.print("bitlist-root-empty=" ++ B.Bytes.hex(S.bitlist_root(Nil{}, 262144n)))
    IO.print("bitlist-root-one=" ++ B.Bytes.hex(S.bitlist_root(True{} <> Nil{}, 262144n)))
    IO.print("bitlist-root-3-16=" ++ B.Bytes.hex(S.bitlist_root(True{} <> False{} <> True{} <> Nil{}, 16n)))
    IO.print("bitlist-root-9=" ++ B.Bytes.hex(S.bitlist_root(nine_bits(), 262144n)))
    IO.print("bytes52-17=" ++ B.Bytes.hex(S.bytes52_root(B.Bytes.rep(52n, 17))))
    IO.print("zero-tree-10=" ++ B.Bytes.hex(S.zero_tree(10n)))
