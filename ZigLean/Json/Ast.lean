import ZigLean.Json.Decode

namespace ZigLean.Json

inductive JsonValue where
  | null
  | bool (b : Bool)
  | number (raw : String)
  | string (raw : String)
  | array (elems : Array JsonValue)
  | object (fields : List (String × JsonValue))
deriving Repr, BEq, Inhabited

def sliceUtf8 (input : ByteArray) (offset len : Nat) : String :=
  String.fromUTF8! (input.extract offset (offset + len))

def tokenSlice (input : ByteArray) (tok : JsonToken) : String :=
  sliceUtf8 input tok.offset.toNat tok.length.toNat

def parseBoolLiteral (s : String) : Option Bool :=
  if s == "true" then some true
  else if s == "false" then some false
  else none

def parseNullLiteral (s : String) : Option Unit :=
  if s == "null" then some () else none

def unexpectedToken (idx : Nat) : JsonError :=
  { code := 9101, offset := UInt64.ofNat idx, message := "unexpected json token" }

mutual
  partial def buildArrayLoop (tokens : Array JsonToken) (input : ByteArray) (idx : Nat) (elems : Array JsonValue)
      : Except JsonError (JsonValue × Nat) := do
    if idx >= tokens.size then
      throw (unexpectedToken idx)
    if tokens[idx]!.kind == .arrayEnd then
      return (JsonValue.array elems, idx + 1)
    let (value, next) ← buildValue tokens input idx
    buildArrayLoop tokens input next (elems.push value)

  partial def buildObjectLoop (tokens : Array JsonToken) (input : ByteArray) (idx : Nat) (fields : List (String × JsonValue))
      : Except JsonError (JsonValue × Nat) := do
    if idx >= tokens.size then
      throw (unexpectedToken idx)
    if tokens[idx]!.kind == .objectEnd then
      return (JsonValue.object fields, idx + 1)
    if tokens[idx]!.kind != .string then
      throw (unexpectedToken idx)
    let key := tokenSlice input tokens[idx]!
    let (value, next) ← buildValue tokens input (idx + 1)
    buildObjectLoop tokens input next (fields ++ [(key, value)])

  partial def buildValue (tokens : Array JsonToken) (input : ByteArray) (idx : Nat)
      : Except JsonError (JsonValue × Nat) := do
    if idx >= tokens.size then
      throw (unexpectedToken idx)
    match tokens[idx]!.kind with
    | .objectStart => buildObjectLoop tokens input (idx + 1) []
    | .arrayStart => buildArrayLoop tokens input (idx + 1) #[]
    | .string =>
      return (JsonValue.string (tokenSlice input tokens[idx]!), idx + 1)
    | .number =>
      return (JsonValue.number (tokenSlice input tokens[idx]!), idx + 1)
    | .bool =>
      let raw := tokenSlice input tokens[idx]!
      match parseBoolLiteral raw with
      | some b => return (JsonValue.bool b, idx + 1)
      | none => throw (unexpectedToken idx)
    | .null =>
      let raw := tokenSlice input tokens[idx]!
      match parseNullLiteral raw with
      | some () => return (JsonValue.null, idx + 1)
      | none => throw (unexpectedToken idx)
    | .objectEnd | .arrayEnd =>
      throw (unexpectedToken idx)
end

def buildAst (tokens : Array JsonToken) (input : ByteArray) : Except JsonError JsonValue := do
  let (value, next) ← buildValue tokens input 0
  if next != tokens.size then
    throw { code := 9102, offset := UInt64.ofNat next, message := "trailing json tokens" }
  else
    return value

end ZigLean.Json