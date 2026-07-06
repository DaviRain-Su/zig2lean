import ZigLean

namespace JsonAstTest

open ZigLean.Json

def bytes (s : String) : ByteArray :=
  s.toUTF8

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def expectParseOk (name : String) (input : String) (check : JsonValue -> Bool) : IO Unit := do
  match ← parse (bytes input) with
  | Except.ok value =>
    if !check value then
      throw <| IO.userError s!"{name}: parse check failed for {repr value}"
  | Except.error err =>
    throw <| IO.userError s!"{name}: parse failed with code {err.code}"

def main : IO Unit := do
  expectParseOk "null" "null" fun v => v == JsonValue.null
  expectParseOk "bool true" "true" fun v => v == JsonValue.bool true
  expectParseOk "number" "42" fun v =>
    match v with
    | JsonValue.number raw => raw == "42"
    | _ => false
  expectParseOk "string" "\"hello\"" fun v =>
    match v with
    | JsonValue.string raw => raw == "hello"
    | _ => false
  expectParseOk "array" "[1,true,null]" fun v =>
    match v with
    | JsonValue.array elems => elems.size == 3
    | _ => false
  expectParseOk "object" "{\"a\":1,\"b\":[false]}" fun v =>
    match v with
    | JsonValue.object fields =>
      match fields with
      | (k, JsonValue.number n) :: _ => k == "a" && n == "1"
      | _ => false
    | _ => false

  match ← parse (bytes "{\"a\":1,}") with
  | Except.ok _ => throw <| IO.userError "expected parse error for trailing comma"
  | Except.error err => assertEq "trailing comma code" err.code 1

end JsonAstTest

def main : IO Unit :=
  JsonAstTest.main