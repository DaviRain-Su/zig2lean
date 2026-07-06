import ZigLean

namespace CompressTest

open ZigLean.Compress

def bytes (s : String) : ByteArray :=
  s.toUTF8

def assertBytes (name : String) (actual expected : ByteArray) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: byte arrays differ; expected size {expected.size}, got {actual.size}"

def expectDecompressOk (name : String) (actual : Except CompressError ByteArray) (expected : ByteArray) : IO Unit := do
  match actual with
  | Except.ok out => assertBytes name out expected
  | Except.error err => throw <| IO.userError s!"{name}: expected success, got code {err.code}"

def expectDecompressError (name : String) (actual : Except CompressError ByteArray) (expectedCode : UInt32) : IO Unit := do
  match actual with
  | Except.ok out => throw <| IO.userError s!"{name}: expected error, got {out.size} bytes"
  | Except.error err =>
    if err.code != expectedCode then
      throw <| IO.userError s!"{name}: expected code {expectedCode}, got {err.code}"

def roundTrip
    (name : String)
    (compress : ByteArray -> IO ByteArray)
    (decompress : ByteArray -> IO (Except CompressError ByteArray))
    (input : ByteArray) : IO Unit := do
  let compressed ← compress input
  if compressed.size == 0 && input.size > 0 then
    throw <| IO.userError s!"{name}: compression returned empty output"
  expectDecompressOk name (← decompress compressed) input

def main : IO Unit := do
  let hello := bytes "hello world"
  let empty := ByteArray.empty

  roundTrip "gzip hello" gzipCompress gzipDecompress hello
  roundTrip "gzip empty" gzipCompress gzipDecompress empty
  roundTrip "zlib hello" zlibCompress zlibDecompress hello
  roundTrip "deflate hello" deflateCompress deflateDecompress hello

  expectDecompressError "gzip invalid" (← gzipDecompress (bytes "not gzip")) 1

  for _ in [0:20] do
    roundTrip "repeat gzip" gzipCompress gzipDecompress hello

end CompressTest

def main : IO Unit :=
  CompressTest.main