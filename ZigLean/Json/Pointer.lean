import ZigLean.Json.Ast

namespace ZigLean.Json.Pointer

structure PointerError where
  code : UInt32
  message : String
deriving Repr, BEq

def unescapeToken (token : String) : String :=
  (token.replace "~1" "/").replace "~0" "~"

def splitPointer (pointer : String) : Except PointerError (List String) :=
  if pointer.isEmpty then
    Except.ok []
  else if !pointer.startsWith "/" then
    Except.error { code := 1, message := "pointer must be empty or start with /" }
  else
    let tokens := pointer.splitOn "/" |>.filter (· != "") |>.map unescapeToken
    Except.ok tokens

def lookupField? (fields : List (String × JsonValue)) (key : String) : Option JsonValue :=
  match fields.find? (fun p => p.1 == key) with
  | some (_, value) => some value
  | none => none

def resolveSegment (value : JsonValue) (token : String) : Except PointerError JsonValue :=
  match value with
  | .object fields =>
    match lookupField? fields token with
    | some child => Except.ok child
    | none => Except.error { code := 3, message := s!"key not found: {token}" }
  | .array elems =>
    match token.toNat? with
    | none => Except.error { code := 5, message := s!"invalid array index: {token}" }
    | some idx =>
      if h : idx < elems.size then
        Except.ok elems[idx]
      else
        Except.error { code := 4, message := s!"index out of bounds: {token}" }
  | _ =>
    Except.error { code := 2, message := "cannot traverse scalar json value" }

def resolve (value : JsonValue) (tokens : List String) : Except PointerError JsonValue :=
  tokens.foldlM (fun acc token => resolveSegment acc token) value

def get (value : JsonValue) (pointer : String) : Except PointerError JsonValue := do
  let tokens ← splitPointer pointer
  resolve value tokens

def get? (value : JsonValue) (pointer : String) : Option JsonValue :=
  match get value pointer with
  | Except.ok v => some v
  | Except.error _ => none

end ZigLean.Json.Pointer