namespace ZigLean.Crypto.Aead.FFI

@[extern "lean_ziglean_crypto_aes256gcm_encrypt"]
opaque aes256GcmEncryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_aes256gcm_decrypt"]
opaque aes256GcmDecryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_aes256gcmsiv_encrypt"]
opaque aes256GcmSivEncryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_aes256gcmsiv_decrypt"]
opaque aes256GcmSivDecryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_aegis256_encrypt"]
opaque aegis256EncryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_aegis256_decrypt"]
opaque aegis256DecryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_chacha20poly1305_encrypt"]
opaque chacha20Poly1305EncryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_chacha20poly1305_decrypt"]
opaque chacha20Poly1305DecryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_aes256ocb_encrypt"]
opaque aes256OcbEncryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_aes256ocb_decrypt"]
opaque aes256OcbDecryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_aes256siv_encrypt"]
opaque aes256SivEncryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_aes256siv_decrypt"]
opaque aes256SivDecryptRaw : @& ByteArray -> @& ByteArray -> @& ByteArray -> @& ByteArray -> IO ByteArray

end ZigLean.Crypto.Aead.FFI