import ZigLean

namespace JsonPointerTest

open ZigLean.Json
open ZigLean.Json.Pointer

def bytes (s : String) : ByteArray :=
  s.toUTF8

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def expectGetOk (name : String) (doc : JsonValue) (pointer : String) (check : JsonValue → Bool) : IO Unit := do
  match get doc pointer with
  | Except.ok value =>
    if !check value then
      throw <| IO.userError s!"{name}: pointer check failed for {repr value}"
  | Except.error err =>
    throw <| IO.userError s!"{name}: pointer failed with code {err.code}: {err.message}"

def expectGetError (name : String) (doc : JsonValue) (pointer : String) (expectedCode : UInt32) : IO Unit := do
  match get doc pointer with
  | Except.ok value => throw <| IO.userError s!"{name}: expected error, got {repr value}"
  | Except.error err => assertEq s!"{name} code" err.code expectedCode

def parseDoc (input : String) : IO JsonValue := do
  match ← parse (bytes input) with
  | Except.ok doc => pure doc
  | Except.error err => throw <| IO.userError s!"parse failed: {err.code}"

def main : IO Unit := do
  let doc ← parseDoc "{\"foo\":[\"bar\",\"baz\"],\"a/b\":1,\"m~n\":8}"

  expectGetOk "empty pointer" doc "" fun v => v == doc
  expectGetOk "foo array" doc "/foo" fun v =>
    match v with
    | JsonValue.array elems => elems.size == 2
    | _ => false
  expectGetOk "foo index 0" doc "/foo/0" fun v =>
    match v with
    | JsonValue.string s => s == "bar"
    | _ => false
  expectGetOk "foo index 1" doc "/foo/1" fun v =>
    match v with
    | JsonValue.string s => s == "baz"
    | _ => false
  expectGetOk "escaped slash key" doc "/a~1b" fun v =>
    match v with
    | JsonValue.number n => n == "1"
    | _ => false
  expectGetOk "escaped tilde key" doc "/m~0n" fun v =>
    match v with
    | JsonValue.number n => n == "8"
    | _ => false

  expectGetError "missing key" doc "/missing" 3
  expectGetError "array index oob" doc "/foo/9" 4
  expectGetError "invalid array index" doc "/foo/x" 5
  expectGetError "scalar traverse" doc "/foo/0/extra" 2
  expectGetError "invalid pointer" doc "no-leading-slash" 1

  match get? doc "/foo/0" with
  | some (JsonValue.string "bar") => pure ()
  | other => throw <| IO.userError s!"get? hit: expected some string bar, got {repr other}"
  if (get? doc "/nope").isSome then
    throw <| IO.userError "get? miss: expected none"

  expectGetOk "numeric root field" (← parseDoc "{\"0\":true}") "/0" fun v =>
    v == JsonValue.bool true

end JsonPointerTest

def main : IO Unit :=
  JsonPointerTest.main