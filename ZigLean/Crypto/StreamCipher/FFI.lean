namespace ZigLean.Crypto.StreamCipher.FFI

@[extern "lean_ziglean_crypto_chacha20_xor"]
opaque chacha20XorRaw : @& ByteArray -> @& ByteArray -> UInt32 -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_xchacha20_xor"]
opaque xChaCha20XorRaw : @& ByteArray -> @& ByteArray -> UInt32 -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_chacha20_legacy_xor"]
opaque chacha20LegacyXorRaw : @& ByteArray -> @& ByteArray -> UInt64 -> @& ByteArray -> IO ByteArray

end ZigLean.Crypto.StreamCipher.FFI
