namespace ZigLean.Json

inductive JsonTokenKind where
  | objectStart
  | objectEnd
  | arrayStart
  | arrayEnd
  | string
  | number
  | bool
  | null
deriving Repr, BEq, Inhabited

instance : ToString JsonTokenKind where
  toString
    | .objectStart => "objectStart"
    | .objectEnd => "objectEnd"
    | .arrayStart => "arrayStart"
    | .arrayEnd => "arrayEnd"
    | .string => "string"
    | .number => "number"
    | .bool => "bool"
    | .null => "null"

structure JsonToken where
  kind : JsonTokenKind
  offset : UInt64
  length : UInt64
deriving Repr, BEq, Inhabited

instance : ToString JsonToken where
  toString t := s!"{t.kind}@{t.offset}+{t.length}"

structure JsonError where
  code : UInt32
  offset : UInt64
  message : String
deriving Repr, BEq

def kindOfCode? : UInt32 -> Option JsonTokenKind
  | 1 => some .objectStart
  | 2 => some .objectEnd
  | 3 => some .arrayStart
  | 4 => some .arrayEnd
  | 5 => some .string
  | 6 => some .number
  | 7 => some .bool
  | 8 => some .null
  | _ => none

def readU32LE? (b : ByteArray) (off : Nat) : Option UInt32 := do
  if off + 4 > b.size then none else
  let b0 := b[off]!.toUInt32
  let b1 := b[off + 1]!.toUInt32
  let b2 := b[off + 2]!.toUInt32
  let b3 := b[off + 3]!.toUInt32
  some (b0 ||| (b1 <<< 8) ||| (b2 <<< 16) ||| (b3 <<< 24))

def readU64LE? (b : ByteArray) (off : Nat) : Option UInt64 := do
  if off + 8 > b.size then none else
  let rec loop (i : Nat) (factor acc : UInt64) : UInt64 :=
    if _h : i < 8 then
      loop (i + 1) (factor * 256) (acc ||| (b[off + i]!.toUInt64 * factor))
    else
      acc
  some (loop 0 1 0)

def decodeRawResult (b : ByteArray) : Except JsonError (Array JsonToken) := Id.run do
  let some status := readU32LE? b 0
    | return Except.error { code := 9001, offset := 0, message := "short native result" }
  let some countOrCode := readU32LE? b 4
    | return Except.error { code := 9001, offset := 0, message := "short native result" }
  let some errOffset := readU64LE? b 8
    | return Except.error { code := 9001, offset := 0, message := "short native result" }
  if status != 0 then
    return Except.error { code := countOrCode, offset := errOffset, message := "json parse failed" }
  let count := countOrCode.toNat
  let expectedSize := 16 + count * 24
  if b.size != expectedSize then
    return Except.error { code := 9002, offset := 0, message := "native result size mismatch" }
  let mut toks := #[]
  for i in [0:count] do
    let base := 16 + i * 24
    let some kindCode := readU32LE? b base
      | return Except.error { code := 9002, offset := 0, message := "missing token kind" }
    let some kind := kindOfCode? kindCode
      | return Except.error { code := 9003, offset := 0, message := "unknown token kind" }
    let some offset := readU64LE? b (base + 8)
      | return Except.error { code := 9002, offset := 0, message := "missing token offset" }
    let some length := readU64LE? b (base + 16)
      | return Except.error { code := 9002, offset := 0, message := "missing token length" }
    toks := toks.push { kind, offset, length }
  return Except.ok toks

end ZigLean.Json
