import ZigLean.Crypto.Dh.FFI

namespace ZigLean.Crypto.Dh

def x25519Keypair (seed : ByteArray) : IO ByteArray :=
  FFI.x25519KeypairRaw seed

def x25519SharedSecret (secretKey publicKey : ByteArray) : IO ByteArray :=
  FFI.x25519SharedSecretRaw secretKey publicKey

end ZigLean.Crypto.Dh
