import ZigLean.Json.Decode
import ZigLean.Json.Stream.FFI

namespace ZigLean.Json.Stream

structure ParserContext where
  handle : USize
deriving Repr, Inhabited

inductive StreamEvent where
  | needMore
  | token (tok : JsonToken)
  | end
  | error (err : JsonError)
deriving Repr, BEq

def readU32LE? (b : ByteArray) (off : Nat) : Option UInt32 := do
  if off + 4 > b.size then none else
  let b0 := b[off]!.toUInt32
  let b1 := b[off + 1]!.toUInt32
  let b2 := b[off + 2]!.toUInt32
  let b3 := b[off + 3]!.toUInt32
  some (b0 ||| (b1 <<< 8) ||| (b2 <<< 16) ||| (b3 <<< 24))

def readU64LE? (b : ByteArray) (off : Nat) : Option UInt64 := do
  if off + 8 > b.size then none else
  let rec loop (i factor : Nat) (acc : UInt64) : UInt64 :=
    if _h : i < 8 then
      loop (i + 1) (factor * 256) (acc + UInt64.ofNat (b[off + i]!.toNat * factor))
    else
      acc
  some (loop 0 1 0)

def decodeNextResult (b : ByteArray) : Except JsonError StreamEvent := Id.run do
  let some status := readU32LE? b 0
    | return Except.error { code := 9001, offset := 0, message := "short stream result" }
  let some kindCode := readU32LE? b 4
    | return Except.error { code := 9001, offset := 0, message := "short stream result" }
  let some offset := readU64LE? b 8
    | return Except.error { code := 9001, offset := 0, message := "short stream result" }
  let some length := readU64LE? b 16
    | return Except.error { code := 9001, offset := 0, message := "short stream result" }
  let some errOffset := readU64LE? b 24
    | return Except.error { code := 9001, offset := 0, message := "short stream result" }
  match status with
  | 0 =>
    let some kind := kindOfCode? kindCode
      | return Except.error { code := 9003, offset := 0, message := "unknown stream token kind" }
    return Except.ok (.token { kind, offset, length })
  | 1 => return Except.ok .needMore
  | 2 => return Except.ok (.error { code := 1, offset := errOffset, message := "json stream parse failed" })
  | 3 => return Except.ok .end
  | _ => return Except.error { code := 9004, offset := 0, message := "unknown stream status" }

def init : IO (Except JsonError ParserContext) := do
  try
    let handle ← FFI.initRaw
    pure (Except.ok { handle })
  catch _ =>
    pure (Except.error { code := 2, offset := 0, message := "json stream init failed" })

def feed (ctx : ParserContext) (chunk : ByteArray) : IO (Except JsonError Unit) := do
  try
    FFI.feedRaw ctx.handle chunk
    pure (Except.ok ())
  catch _ =>
    pure (Except.error { code := 2, offset := 0, message := "json stream feed failed" })

def endInput (ctx : ParserContext) : IO Unit :=
  FFI.endInputRaw ctx.handle

def next (ctx : ParserContext) : IO (Except JsonError StreamEvent) := do
  pure <| decodeNextResult (← FFI.nextRaw ctx.handle)

def free (ctx : ParserContext) : IO Unit :=
  FFI.freeRaw ctx.handle

partial def drainChunk (ctx : ParserContext) (acc : Array JsonToken) : IO (Except JsonError (Array JsonToken)) := do
  match ← next ctx with
  | Except.error err => pure (Except.error err)
  | Except.ok .needMore => pure (Except.ok acc)
  | Except.ok (.error err) => pure (Except.error err)
  | Except.ok (.token tok) => drainChunk ctx (acc.push tok)
  | Except.ok .end => pure (Except.ok acc)

partial def collectTokensLoop (ctx : ParserContext) (acc : Array JsonToken) : IO (Except JsonError (Array JsonToken)) := do
  match ← next ctx with
  | Except.error err => pure (Except.error err)
  | Except.ok (.needMore) =>
    pure (Except.error { code := 9104, offset := 0, message := "json stream needs more input" })
  | Except.ok (.error err) => pure (Except.error err)
  | Except.ok (.token tok) => collectTokensLoop ctx (acc.push tok)
  | Except.ok .end => pure (Except.ok acc)

def parseTokens (chunks : Array ByteArray) : IO (Except JsonError (Array JsonToken)) := do
  match ← init with
  | Except.error err => pure (Except.error err)
  | Except.ok ctx => do
    let mut tokens := #[]
    for chunk in chunks do
      match ← feed ctx chunk with
      | Except.error err =>
        free ctx
        return Except.error err
      | Except.ok () => pure ()
      match ← drainChunk ctx tokens with
      | Except.error err =>
        free ctx
        return Except.error err
      | Except.ok acc => tokens := acc
    endInput ctx
    let result ← collectTokensLoop ctx tokens
    free ctx
    pure result

end ZigLean.Json.Stream