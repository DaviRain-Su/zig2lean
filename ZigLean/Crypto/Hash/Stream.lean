import ZigLean.Crypto.Hash.Stream.FFI

namespace ZigLean.Crypto.Hash.Stream

structure HashStreamError where
  code : UInt32
  message : String
deriving Repr, BEq

inductive HashAlgorithm where
  | sha256
  | blake3
  | sha512
  | sha3_256
  | keccak256
deriving Repr, BEq, Inhabited

structure HashContext where
  handle : USize
  algorithm : HashAlgorithm
deriving Repr, Inhabited

def algorithmId : HashAlgorithm → UInt32
  | .sha256 => 1
  | .blake3 => 2
  | .sha512 => 3
  | .sha3_256 => 4
  | .keccak256 => 5

def digestLength : HashAlgorithm → Nat
  | .sha256 => 32
  | .blake3 => 32
  | .sha512 => 64
  | .sha3_256 => 32
  | .keccak256 => 32

def errorMessage (code : UInt32) : String :=
  if code == 3 then "hash context already finalized"
  else if code == 2 then "hash stream allocation failed"
  else if code == 1 then "hash stream invalid argument"
  else "hash stream operation failed"

def init (algorithm : HashAlgorithm) : IO (Except HashStreamError HashContext) := do
  try
    let handle ← FFI.initRaw (algorithmId algorithm)
    pure (Except.ok { handle, algorithm })
  catch _ =>
    pure (Except.error { code := 2, message := "hash stream init failed" })

def update (ctx : HashContext) (data : ByteArray) : IO (Except HashStreamError Unit) := do
  let code ← FFI.updateRaw ctx.handle data
  if code == 0 then
    pure (Except.ok ())
  else
    pure (Except.error { code, message := errorMessage code })

def final (ctx : HashContext) : IO (Except HashStreamError ByteArray) := do
  try
    let digest ← FFI.finalRaw ctx.handle (UInt32.ofNat (digestLength ctx.algorithm))
    pure (Except.ok digest)
  catch _ =>
    pure (Except.error { code := 3, message := errorMessage 3 })

def free (ctx : HashContext) : IO Unit :=
  FFI.freeRaw ctx.handle

def digest (algorithm : HashAlgorithm) (chunks : Array ByteArray) : IO (Except HashStreamError ByteArray) := do
  match ← init algorithm with
  | Except.error err => pure (Except.error err)
  | Except.ok ctx => do
    let mut current := ctx
    for chunk in chunks do
      match ← update current chunk with
      | Except.error err =>
        free current
        return Except.error err
      | Except.ok () => pure ()
    let result ← final current
    free current
    pure result

end ZigLean.Crypto.Hash.Stream