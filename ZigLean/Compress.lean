import ZigLean.Compress.FFI

namespace ZigLean.Compress

structure CompressError where
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

def decodeRawResult (b : ByteArray) : Except CompressError ByteArray := Id.run do
  let some status := readU32LE? b 0
    | return Except.error { code := 9001, offset := 0, message := "short compress result" }
  let some code := readU32LE? b 4
    | return Except.error { code := 9001, offset := 0, message := "short compress result" }
  let some offset := readU64LE? b 8
    | return Except.error { code := 9001, offset := 0, message := "short compress result" }
  if status != 0 then
    return Except.error { code, offset, message := "compress decompress failed" }
  return Except.ok (b.extract 16 b.size)

def gzipCompress (input : ByteArray) : IO ByteArray :=
  FFI.gzipCompressRaw input

def gzipDecompress (input : ByteArray) : IO (Except CompressError ByteArray) := do
  pure <| decodeRawResult (← FFI.gzipDecompressRaw input)

def zlibCompress (input : ByteArray) : IO ByteArray :=
  FFI.zlibCompressRaw input

def zlibDecompress (input : ByteArray) : IO (Except CompressError ByteArray) := do
  pure <| decodeRawResult (← FFI.zlibDecompressRaw input)

def deflateCompress (input : ByteArray) : IO ByteArray :=
  FFI.deflateCompressRaw input

def deflateDecompress (input : ByteArray) : IO (Except CompressError ByteArray) := do
  pure <| decodeRawResult (← FFI.deflateDecompressRaw input)

end ZigLean.Compress