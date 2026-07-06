import ZigLean

namespace JsonStreamTest

open ZigLean.Json
open ZigLean.Json.Stream

def bytes (s : String) : ByteArray :=
  s.toUTF8

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def tokensEqual (a b : Array JsonToken) : Bool :=
  a.size == b.size && (a.zip b).all fun (x, y) => x == y

def expectTokensOk (name : String) (actual expected : Array JsonToken) : IO Unit := do
  if !tokensEqual actual expected then
    throw <| IO.userError s!"{name}: token streams differ (got {actual.size}, expected {expected.size})"

def main : IO Unit := do
  let input := bytes "{\"a\":1,\"b\":[true,null]}"
  let expected ← match ← parseTokens input with
    | Except.error err => throw <| IO.userError s!"baseline parse failed: {err.code}"
    | Except.ok toks => pure toks

  match ← parseTokens #[bytes "{\"a\":", bytes "1,\"b\":[true,null]}"] with
  | Except.error err => throw <| IO.userError s!"stream two-chunk parse failed: {err.code}"
  | Except.ok streamed => expectTokensOk "stream two-chunk" streamed expected

  let small := bytes "{\"a\":1}"
  let smallExpected ← match ← parseTokens small with
    | Except.error err => throw <| IO.userError s!"small baseline failed: {err.code}"
    | Except.ok toks => pure toks
  match ← Stream.parseTokens #[bytes "{", bytes "\"a\"", bytes ":1}"] with
  | Except.error err => throw <| IO.userError s!"stream three-chunk parse failed: {err.code}"
  | Except.ok streamed => expectTokensOk "stream three-chunk object" streamed smallExpected

  match ← init with
  | Except.error err => throw <| IO.userError s!"stream init failed: {err.code}"
  | Except.ok ctx => do
    let _ ← feed ctx (bytes "{")
    let mut sawObjectStart := false
    let mut needMore := false
    for _ in [0:16] do
      if needMore then break
      match ← next ctx with
      | Except.error err =>
          free ctx
          throw <| IO.userError s!"stream incremental next failed: {err.code}"
      | Except.ok .needMore => needMore := true
      | Except.ok (.token tok) =>
        if tok.kind == .objectStart then sawObjectStart := true
      | Except.ok ev =>
          free ctx
          throw <| IO.userError s!"stream incremental unexpected: {repr ev}"
    if !needMore || !sawObjectStart then
      free ctx
      throw <| IO.userError "stream incremental expected objectStart then needMore"
    let _ ← feed ctx (bytes "\"a\":1}")
    endInput ctx
    let mut tokens := #[]
    let mut done := false
    for _ in [0:32] do
      if done then break
      match ← next ctx with
      | Except.error err =>
          free ctx
          throw <| IO.userError s!"stream incremental finalize failed: {err.code}"
      | Except.ok .end => done := true
      | Except.ok (.token tok) => tokens := tokens.push tok
      | Except.ok ev =>
          free ctx
          throw <| IO.userError s!"stream incremental finalize unexpected: {repr ev}"
    free ctx
    if tokens.isEmpty then
      throw <| IO.userError "stream incremental expected tokens after second feed"

  match ← init with
  | Except.error err => throw <| IO.userError s!"invalid init failed: {err.code}"
  | Except.ok ctx => do
    let _ ← feed ctx (bytes "{\"a\":1,}")
    endInput ctx
    let mut sawError := false
    let mut loops := 0
    while !sawError && loops < 32 do
      loops := loops + 1
      match ← next ctx with
      | Except.error _ =>
        sawError := true
      | Except.ok (.error _) => sawError := true
      | Except.ok .end => sawError := true
      | Except.ok (.token _) => pure ()
      | Except.ok .needMore => sawError := true
    free ctx
    if !sawError then
      throw <| IO.userError "stream invalid json should eventually error or end"

end JsonStreamTest

def main : IO Unit :=
  JsonStreamTest.main