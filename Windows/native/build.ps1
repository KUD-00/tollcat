# 在 Windows 11 + 官方 Swift 工具链上把 MeterCoreCLR 编成 dll。
# 需要：https://www.swift.org/install/windows/ 当前稳定版，VS 2026 + Windows App SDK 工作负载。
param(
    [ValidateSet("x64", "arm64")]
    [string]$Arch = "x64",
    [ValidateSet("debug", "release")]
    [string]$Config = "release"
)

$ErrorActionPreference = "Stop"
# $PSScriptRoot 已经是 <repo>/Windows/native，不要再拼一层。
$Native = $PSScriptRoot
$Triple = if ($Arch -eq "arm64") { "aarch64-unknown-windows-msvc" } else { "x86_64-unknown-windows-msvc" }
$Out = Join-Path $Native "dist\$Arch"

Write-Host "swift build --triple $Triple -c $Config"
Push-Location $Native
try {
    swift build --package-path $Native --triple $Triple -c $Config
    $build = Join-Path $Native ".build\$Triple\$Config"
    New-Item -ItemType Directory -Force -Path $Out | Out-Null
    Copy-Item -Force (Join-Path $build "MeterCoreCLR.dll") $Out
    Get-ChildItem $build -Filter "*.dll" | Copy-Item -Destination $Out -Force
    Write-Host "copied dlls -> $Out"
} finally {
    Pop-Location
}
