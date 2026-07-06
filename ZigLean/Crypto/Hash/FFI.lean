namespace ZigLean.Crypto.Hash.FFI

@[extern "lean_ziglean_crypto_sha256"]
opaque sha256Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_blake3"]
opaque blake3Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_hmac_sha256"]
opaque hmacSha256Raw : @& ByteArray -> @& ByteArray -> IO ByteArray

end ZigLean.Crypto.Hash.FFI
