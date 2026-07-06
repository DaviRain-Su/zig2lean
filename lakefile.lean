import Lake
open Lake DSL
open System

package «zig2lean» where

lean_lib ZigLean

lean_exe json_test where
  root := `JsonTest
  srcDir := "test"
  supportInterpreter := true

lean_exe crypto_hash_test where
  root := `CryptoHashTest
  srcDir := "test"
  supportInterpreter := true

extern_lib liblean_ziglean pkg := do
  let libName := nameToStaticLib "lean_ziglean"
  let outDir := pkg.buildDir / "native"
  let libFile := outDir / "lib" / libName
  let rootSrcJob ← inputFile (pkg.dir / "native" / "src" / "root.zig") true
  let zigSrcJob ← inputFile (pkg.dir / "native" / "src" / "json.zig") true
  let cryptoSrcJob ← inputFile (pkg.dir / "native" / "src" / "crypto_hash.zig") true
  let cSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_json.c") true
  let cryptoCSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_crypto_hash.c") true
  let hdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_json.h") true
  let cryptoHdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_crypto_hash.h") true
  let buildJob ← inputFile (pkg.dir / "native" / "build.zig") true
  let depJob :=
    buildJob.mix <|
      rootSrcJob.mix <|
        zigSrcJob.mix <|
          cryptoSrcJob.mix <|
            cSrcJob.mix <|
              cryptoCSrcJob.mix <|
                hdrJob.mix cryptoHdrJob
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
