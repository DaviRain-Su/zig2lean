namespace ZigLean.Hash.Checksum.FFI

@[extern "lean_ziglean_hash_crc32"]
opaque crc32Raw : @& ByteArray -> IO UInt32

@[extern "lean_ziglean_hash_adler32"]
opaque adler32Raw : @& ByteArray -> IO UInt32

@[extern "lean_ziglean_hash_xxhash64"]
opaque xxHash64Raw : UInt64 -> @& ByteArray -> IO UInt64

end ZigLean.Hash.Checksum.FFI