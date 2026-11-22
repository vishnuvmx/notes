# Builds native Rust `libtack_core.so` for all Android ABIs and places them
# in `android/app/src/main/jniLibs/` so Flutter/Gradle packages them cleanly.
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$crateDir = Join-Path $repoRoot "rust\tack_core"
$jniBase  = Join-Path $repoRoot "android\app\src\main\jniLibs"
$ndkBin   = "C:\Users\vmxvi\AppData\Local\Android\Sdk\ndk\28.2.13676358\toolchains\llvm\prebuilt\windows-x86_64\bin"

$targets = @(
    @{ Triple = "aarch64-linux-android";    Abi = "arm64-v8a";   Cc = "aarch64-linux-android21-clang.cmd" },
    @{ Triple = "armv7-linux-androideabi";  Abi = "armeabi-v7a"; Cc = "armv7a-linux-androideabi21-clang.cmd" },
    @{ Triple = "x86_64-linux-android";     Abi = "x86_64";      Cc = "x86_64-linux-android21-clang.cmd" }
)

Push-Location $crateDir
try {
    foreach ($t in $targets) {
        $triple = $t.Triple
        $abi = $t.Abi
        $ccPath = Join-Path $ndkBin $t.Cc
        $arPath = Join-Path $ndkBin "llvm-ar.exe"
        $envKey = $triple.Replace("-", "_")

        Set-Item -Path "Env:CC_$envKey" -Value $ccPath
        Set-Item -Path "Env:AR_$envKey" -Value $arPath

        Write-Host "==> Building tack_core ($triple -> $abi)..."
        cargo +stable-x86_64-pc-windows-gnu build --release --target $triple
        if ($LASTEXITCODE -ne 0) {
            throw "cargo build failed for $triple"
        }

        $outDir = Join-Path $jniBase $abi
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
        $srcSo = Join-Path $crateDir "target\$triple\release\libtack_core.so"
        $dstSo = Join-Path $outDir "libtack_core.so"
        Copy-Item -Force $srcSo $dstSo
        Write-Host "    Installed $dstSo ($([math]::Round((Get-Item $dstSo).Length / 1KB, 1)) KB)"
    }
} finally {
    Pop-Location
}
