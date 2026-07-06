namespace ZigLean.Crypto.Sign.FFI

@[extern "lean_ziglean_crypto_ed25519_sign"]
opaque ed25519SignRaw : @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_ed25519_verify"]
opaque ed25519VerifyRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> IO Bool

@[extern "lean_ziglean_crypto_secp256k1_sign"]
opaque secp256k1SignRaw : @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_secp256k1_verify"]
opaque secp256k1VerifyRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> IO Bool

end ZigLean.Crypto.Sign.FFI