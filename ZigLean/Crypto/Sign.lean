import ZigLean.Crypto.Sign.FFI

namespace ZigLean.Crypto.Sign

def ed25519Sign (seed message : ByteArray) : IO ByteArray :=
  FFI.ed25519SignRaw seed message

def ed25519Verify (publicKey message signature : ByteArray) : IO Bool :=
  FFI.ed25519VerifyRaw publicKey message signature

def secp256k1Sign (secretKey message : ByteArray) : IO ByteArray :=
  FFI.secp256k1SignRaw secretKey message

def secp256k1Verify (publicKey message signature : ByteArray) : IO Bool :=
  FFI.secp256k1VerifyRaw publicKey message signature

end ZigLean.Crypto.Sign