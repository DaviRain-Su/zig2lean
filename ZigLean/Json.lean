import ZigLean.Json.FFI
import ZigLean.Json.Decode
import ZigLean.Json.Ast

namespace ZigLean.Json

def validate (input : ByteArray) : IO Bool := do
  pure ((← FFI.validateRaw input) == 0)

def parseTokens (input : ByteArray) : IO (Except JsonError (Array JsonToken)) := do
  pure <| decodeRawResult (← FFI.parseTokensRaw input)

def parse (input : ByteArray) : IO (Except JsonError JsonValue) := do
  match ← parseTokens input with
  | Except.error err => pure (Except.error err)
  | Except.ok tokens => pure (buildAst tokens input)

end ZigLean.Json
