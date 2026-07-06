namespace ZigLean.Crypto.Kdf.FFI

@[extern "lean_ziglean_crypto_hkdf_sha256"]
opaque hkdfSha256Raw : @& ByteArray -> @& ByteArray -> @& ByteArray -> UInt64 -> IO ByteArray

@[extern "lean_ziglean_crypto_pbkdf2_sha256"]
opaque pbkdf2Sha256Raw : @& ByteArray -> @& ByteArray -> UInt32 -> UInt64 -> IO ByteArray

@[extern "lean_ziglean_crypto_scrypt"]
opaque scryptRaw : @& ByteArray -> @& ByteArray -> UInt32 -> UInt32 -> UInt32 -> UInt64 -> IO ByteArray

@[extern "lean_ziglean_crypto_argon2id"]
opaque argon2idRaw : @& ByteArray -> @& ByteArray -> UInt32 -> UInt32 -> UInt32 -> UInt64 -> IO ByteArray

end ZigLean.Crypto.Kdf.FFI