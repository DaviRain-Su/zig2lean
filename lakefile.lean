import Lake
open Lake DSL
open System

package «zig2lean» where
  testDriver := "test"

lean_lib ZigLean

script test do
  let suites := #[
    ("JsonTest", "json_test"),
    ("CryptoHashTest", "crypto_hash_test"),
    ("CodecTest", "codec_test"),
    ("CompressTest", "compress_test"),
    ("CryptoExtendedTest", "crypto_extended_test"),
    ("JsonAstTest", "json_ast_test"),
    ("JsonStreamTest", "json_stream_test"),
    ("JsonPointerTest", "json_pointer_test")
  ]
  for (name, exe) in suites do
    IO.println s!"== {name} =="
    let out ← IO.Process.output { cmd := "lake", args := #["exe", exe] }
    unless out.stdout.isEmpty do
      IO.print out.stdout
    if out.exitCode != 0 then
      unless out.stderr.isEmpty do
        IO.eprintln out.stderr
      IO.eprintln s!"{name} failed with exit code {out.exitCode}"
      return out.exitCode
  IO.println "All tests passed."
  return 0

lean_exe json_test where
  root := `JsonTest
  srcDir := "test"
  supportInterpreter := true

lean_exe crypto_hash_test where
  root := `CryptoHashTest
  srcDir := "test"
  supportInterpreter := true

lean_exe codec_test where
  root := `CodecTest
  srcDir := "test"
  supportInterpreter := true

lean_exe compress_test where
  root := `CompressTest
  srcDir := "test"
  supportInterpreter := true

lean_exe crypto_extended_test where
  root := `CryptoExtendedTest
  srcDir := "test"
  supportInterpreter := true

lean_exe json_ast_test where
  root := `JsonAstTest
  srcDir := "test"
  supportInterpreter := true

lean_exe json_stream_test where
  root := `JsonStreamTest
  srcDir := "test"
  supportInterpreter := true

lean_exe json_pointer_test where
  root := `JsonPointerTest
  srcDir := "test"
  supportInterpreter := true

extern_lib liblean_ziglean pkg := do
  let libName := nameToStaticLib "lean_ziglean"
  let outDir := pkg.buildDir / "native"
  let libFile := outDir / "lib" / libName
  let rootSrcJob ← inputFile (pkg.dir / "native" / "src" / "root.zig") true
  let jsonSrcJob ← inputFile (pkg.dir / "native" / "src" / "json.zig") true
  let jsonStreamSrcJob ← inputFile (pkg.dir / "native" / "src" / "json_stream.zig") true
  let cryptoSrcJob ← inputFile (pkg.dir / "native" / "src" / "crypto_hash.zig") true
  let cryptoStreamSrcJob ← inputFile (pkg.dir / "native" / "src" / "crypto_hash_stream.zig") true
  let kdfSrcJob ← inputFile (pkg.dir / "native" / "src" / "crypto_kdf.zig") true
  let signSrcJob ← inputFile (pkg.dir / "native" / "src" / "crypto_sign.zig") true
  let aeadSrcJob ← inputFile (pkg.dir / "native" / "src" / "crypto_aead.zig") true
  let checksumSrcJob ← inputFile (pkg.dir / "native" / "src" / "hash_checksum.zig") true
  let leb128SrcJob ← inputFile (pkg.dir / "native" / "src" / "leb128.zig") true
  let codecSrcJob ← inputFile (pkg.dir / "native" / "src" / "codec.zig") true
  let compressSrcJob ← inputFile (pkg.dir / "native" / "src" / "compress.zig") true
  let cSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_json.c") true
  let jsonStreamCSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_json_stream.c") true
  let cryptoCSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_crypto_hash.c") true
  let cryptoStreamCSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_crypto_hash_stream.c") true
  let kdfCSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_crypto_kdf.c") true
  let signCSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_crypto_sign.c") true
  let aeadCSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_crypto_aead.c") true
  let checksumCSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_hash_checksum.c") true
  let leb128CSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_leb128.c") true
  let codecCSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_codec.c") true
  let compressCSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_compress.c") true
  let hdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_json.h") true
  let jsonStreamHdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_json_stream.h") true
  let cryptoHdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_crypto_hash.h") true
  let cryptoStreamHdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_crypto_hash_stream.h") true
  let kdfHdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_crypto_kdf.h") true
  let signHdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_crypto_sign.h") true
  let aeadHdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_crypto_aead.h") true
  let checksumHdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_hash_checksum.h") true
  let leb128HdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_leb128.h") true
  let codecHdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_codec.h") true
  let compressHdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_compress.h") true
  let buildJob ← inputFile (pkg.dir / "native" / "build.zig") true
  let depJob :=
    buildJob.mix <|
      rootSrcJob.mix <|
        jsonSrcJob.mix <|
          jsonStreamSrcJob.mix <|
            cryptoSrcJob.mix <|
            cryptoStreamSrcJob.mix <|
              kdfSrcJob.mix <|
              signSrcJob.mix <|
                aeadSrcJob.mix <|
                  checksumSrcJob.mix <|
                    leb128SrcJob.mix <|
                      codecSrcJob.mix <|
                        compressSrcJob.mix <|
                          cSrcJob.mix <|
                            jsonStreamCSrcJob.mix <|
                              cryptoCSrcJob.mix <|
                              cryptoStreamCSrcJob.mix <|
                                kdfCSrcJob.mix <|
                                signCSrcJob.mix <|
                                  aeadCSrcJob.mix <|
                                    checksumCSrcJob.mix <|
                                      leb128CSrcJob.mix <|
                                        codecCSrcJob.mix <|
                                          compressCSrcJob.mix <|
                                            hdrJob.mix <|
                                              jsonStreamHdrJob.mix <|
                                                cryptoHdrJob.mix <|
                                                cryptoStreamHdrJob.mix <|
                                                  kdfHdrJob.mix <|
                                                  signHdrJob.mix <|
                                                    aeadHdrJob.mix <|
                                                      checksumHdrJob.mix <|
                                                        leb128HdrJob.mix <|
                                                          codecHdrJob.mix compressHdrJob
  buildFileAfterDep libFile depJob fun _ => do
    IO.FS.createDirAll libFile.parent.get!
    let leanPrefixOut ← IO.Process.output {
      cmd := "lean",
      args := #["--print-prefix"]
    }
    if leanPrefixOut.exitCode != 0 then
      error s!"lean --print-prefix failed: {leanPrefixOut.stderr}"
    let leanPrefix := leanPrefixOut.stdout.trimAsciiEnd.toString
    let zigOutPrefix := outDir / "zig-out"
    let procOut ← IO.Process.output {
      cmd := "zig",
      args := #[
        "build",
        "-p", zigOutPrefix.toString,
        "--cache-dir", (outDir / "zig-cache").toString,
        s!"-Dlean-prefix={leanPrefix}"
      ],
      cwd := pkg.dir / "native"
    }
    if procOut.exitCode != 0 then
      error s!"zig build failed:\nstdout:\n{procOut.stdout}\nstderr:\n{procOut.stderr}"
    let builtLib := zigOutPrefix / "lib" / libName
    IO.FS.writeBinFile libFile (← IO.FS.readBinFile builtLib)
