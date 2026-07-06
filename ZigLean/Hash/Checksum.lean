import ZigLean.Hash.Checksum.FFI

namespace ZigLean.Hash.Checksum

def crc32 (input : ByteArray) : IO UInt32 :=
  FFI.crc32Raw input

def xxHash64 (seed : UInt64) (input : ByteArray) : IO UInt64 :=
  FFI.xxHash64Raw seed input

end ZigLean.Hash.Checksum