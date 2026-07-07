import ZigLean.Hash.Checksum.FFI

namespace ZigLean.Hash.Checksum

def crc32 (input : ByteArray) : IO UInt32 :=
  FFI.crc32Raw input

def crc32c (input : ByteArray) : IO UInt32 :=
  FFI.crc32cRaw input

def adler32 (input : ByteArray) : IO UInt32 :=
  FFI.adler32Raw input

def xxHash64 (seed : UInt64) (input : ByteArray) : IO UInt64 :=
  FFI.xxHash64Raw seed input

def fnv1a64 (input : ByteArray) : IO UInt64 :=
  FFI.fnv1a64Raw input

end ZigLean.Hash.Checksum