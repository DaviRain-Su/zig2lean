import ZigLean.Codec.FFI

namespace ZigLean.Codec

structure CodecError where
  code : UInt32
  offset : UInt64
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

def decodeRawResult (b : ByteArray) : Except CodecError ByteArray := Id.run do
  let some status := readU32LE? b 0
    | return Except.error { code := 9001, offset := 0, message := "short codec result" }
  let some code := readU32LE? b 4
    | return Except.error { code := 9001, offset := 0, message := "short codec result" }
  let some offset := readU64LE? b 8
    | return Except.error { code := 9001, offset := 0, message := "short codec result" }
  if status != 0 then
    return Except.error { code, offset, message := "codec decode failed" }
  return Except.ok (b.extract 16 b.size)

def hexEncodeLower (input : ByteArray) : IO String :=
  FFI.hexEncodeLowerRaw input

def hexDecode (input : String) : IO (Except CodecError ByteArray) := do
  pure <| decodeRawResult (← FFI.hexDecodeRaw input)

def base64Encode (input : ByteArray) : IO String :=
  FFI.base64EncodeRaw input

def base64Decode (input : String) : IO (Except CodecError ByteArray) := do
  pure <| decodeRawResult (← FFI.base64DecodeRaw input)

def base64UrlEncode (input : ByteArray) : IO String :=
  FFI.base64UrlEncodeRaw input

def base64UrlDecode (input : String) : IO (Except CodecError ByteArray) := do
  pure <| decodeRawResult (← FFI.base64UrlDecodeRaw input)

def base58Encode (input : ByteArray) : IO String :=
  FFI.base58EncodeRaw input

def base58Decode (input : String) : IO (Except CodecError ByteArray) := do
  pure <| decodeRawResult (← FFI.base58DecodeRaw input)

end ZigLean.Codec
