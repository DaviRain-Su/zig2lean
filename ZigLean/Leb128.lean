import ZigLean.Leb128.FFI

namespace ZigLean.Leb128

structure Leb128Error where
  code : UInt32
  value : UInt64
  message : String
deriving Repr, BEq

def readU32LE? (b : ByteArray) (off : Nat) : Option UInt32 := do
  if off + 4 > b.size then none else
  let b0 := b[off]!.toUInt32
  let b1 := b[off + 1]!.toUInt32
  let b2 := b[off + 2]!.toUInt32
  let b3 := b[off + 3]!.toUInt32
  some (b0 ||| (b1 <<< 8) ||| (b2 <<< 16) ||| (b3 <<< 24))

def readU64LE? (b : ByteArray) (off : Nat) : Option UInt64 := do
  if off + 8 > b.size then none else
  let rec loop (i factor : Nat) (acc : UInt64) : UInt64 :=
    if _h : i < 8 then
      loop (i + 1) (factor * 256) (acc + UInt64.ofNat (b[off + i]!.toNat * factor))
    else
      acc
  some (loop 0 1 0)

def decodeRawResult (b : ByteArray) : Except Leb128Error UInt64 := Id.run do
  let some status := readU32LE? b 0
    | return Except.error { code := 9001, value := 0, message := "short leb128 result" }
  let some code := readU32LE? b 4
    | return Except.error { code := 9001, value := 0, message := "short leb128 result" }
  let some value := readU64LE? b 8
    | return Except.error { code := 9001, value := 0, message := "short leb128 result" }
  if status != 0 then
    return Except.error { code, value, message := "leb128 decode failed" }
  return Except.ok value

def UInt64.toInt64 (v : UInt64) : Int64 :=
  Int64.ofBitVec (BitVec.ofNat 64 v.toNat)

def decodeSignedRawResult (b : ByteArray) : Except Leb128Error Int64 :=
  match decodeRawResult b with
  | Except.error e => Except.error e
  | Except.ok v => Except.ok (UInt64.toInt64 v)

def uleb128Encode (value : UInt64) : IO ByteArray :=
  FFI.uleb128EncodeRaw value

def uleb128Decode (input : ByteArray) : IO (Except Leb128Error UInt64) := do
  pure <| decodeRawResult (← FFI.uleb128DecodeRaw input)

def sleb128Encode (value : Int64) : IO ByteArray :=
  FFI.sleb128EncodeRaw value

def sleb128Decode (input : ByteArray) : IO (Except Leb128Error Int64) := do
  pure <| decodeSignedRawResult (← FFI.sleb128DecodeRaw input)

end ZigLean.Leb128