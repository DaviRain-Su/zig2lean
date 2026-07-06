import ZigLean.Json.FFI
import ZigLean.Json.Decode

namespace ZigLean.Json

def validate (input : ByteArray) : IO Bool := do
  pure ((← FFI.validateRaw input) == 0)

def parseTokens (input : ByteArray) : IO (Except JsonError (Array JsonToken)) := do
  pure <| decodeRawResult (← FFI.parseTokensRaw input)

end ZigLean.Json
