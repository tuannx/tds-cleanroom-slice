# Build the browser build into web/ (wasm32-unknown-unknown + macroquad JS glue).
# ASCII only: this machine's PowerShell 5.1 reads BOM-less scripts as ANSI.
$ErrorActionPreference = "Stop"

$web = $PSScriptRoot
$game = Join-Path $web "..\game"

# cargo/rustup write progress to stderr; under ErrorActionPreference=Stop that
# becomes a fake terminating error, so native calls run with it relaxed and are
# judged by $LASTEXITCODE instead.
function Invoke-Native {
    param([scriptblock]$Command, [string]$What)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $Command
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previous
    }
    if ($code -ne 0) { throw "$What failed (exit $code)" }
}

Write-Host "== wasm target" -ForegroundColor Cyan
$installed = & rustup target list --installed
if (-not ($installed -match "wasm32-unknown-unknown")) {
    Invoke-Native { rustup target add wasm32-unknown-unknown } "rustup target add"
}

Write-Host "== cargo build --release --target wasm32-unknown-unknown" -ForegroundColor Cyan
Push-Location $game
try {
    Invoke-Native { cargo build --release --target wasm32-unknown-unknown } "cargo build (wasm)"
} finally {
    Pop-Location
}

$wasm = Join-Path $game "target\wasm32-unknown-unknown\release\tds-slice.wasm"
Copy-Item $wasm (Join-Path $web "tds.wasm") -Force

# The JS glue ships inside the macroquad crate; copy it once so the page is
# self-hosted and needs no CDN.
if (-not (Test-Path (Join-Path $web "mq_js_bundle.js"))) {
    $bundle = Get-ChildItem "$env:USERPROFILE\.cargo\registry\src\*\macroquad-*\js\mq_js_bundle.js" |
        Sort-Object FullName -Descending | Select-Object -First 1
    if (-not $bundle) { throw "mq_js_bundle.js not found in the cargo registry; run cargo build first" }
    Copy-Item $bundle.FullName (Join-Path $web "mq_js_bundle.js")
}

foreach ($file in @("index.html", "tds.wasm", "mq_js_bundle.js")) {
    if (-not (Test-Path (Join-Path $web $file))) { throw "missing $file" }
}

$kb = [math]::Round((Get-Item (Join-Path $web "tds.wasm")).Length / 1KB)
Write-Host "   ok   web\tds.wasm ($kb KB)" -ForegroundColor Green
Write-Host ""
Write-Host "serve it:  node web\serve.mjs   ->  http://localhost:8080/" -ForegroundColor Cyan
