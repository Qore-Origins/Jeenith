# Copyright (c) 2026 Qore
# Jeenith APK 构建脚本（基于 docs/FLUTTER_APK_BUILD_PIPELINE.md 规范）
# 用法：pwsh -File scripts/build_apk.ps1 -Status release [-TargetVersion "1.0.1"]
param(
    [ValidateSet("debug", "release", "profile")]
    [string]$BuildType = "release",

    [ValidateSet("release", "beta", "alpha", "rc", "fix", "hotfix", "feature", "dev", "debug")]
    [string]$Status = "release",

    [string]$TargetVersion,

    [switch]$NoPub
)

$ErrorActionPreference = "Stop"

# === 配置区 ===
$appName = "Jeenith"

$scriptPath  = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$pubspecPath = Join-Path $projectRoot "pubspec.yaml"

function Get-VersionFromPubspec {
    param([string]$pubspecPath)
    if (-not (Test-Path $pubspecPath)) { Write-Error "pubspec.yaml not found: $pubspecPath"; exit 1 }
    $content = Get-Content $pubspecPath -Raw
    if ($content -match "version:\s*(\d+\.\d+\.\d+)\+(\d+)") {
        return @{ Version = $matches[1]; BuildNumber = [int]$matches[2] }
    }
    Write-Error "Cannot read version from pubspec.yaml"; exit 1
}

function Update-VersionInPubspec {
    param([string]$pubspecPath, [string]$newVersion, [int]$newBuildNumber)
    $content = Get-Content $pubspecPath -Raw -Encoding UTF8
    $newContent = $content -replace "version:\s*\d+\.\d+\.\d+\+\d+", "version: $newVersion+$newBuildNumber"
    [System.IO.File]::WriteAllText($pubspecPath, $newContent, [System.Text.UTF8Encoding]::new($false))
    Write-Host "[VERSION] Updated: $newVersion+$newBuildNumber" -ForegroundColor Yellow
}

function Get-IncrementedVersion {
    param([string]$currentVersion, [string]$status)
    $parts = $currentVersion.Split('.')
    $major = [int]$parts[0]; $minor = [int]$parts[1]; $patch = [int]$parts[2]
    switch ($status) {
        "release" { $minor++; $patch = 0 }
        default   { $patch++ }
    }
    return "$major.$minor.$patch"
}

function Get-BuildDate { Get-Date -Format "yyyyMMdd" }

function Get-BuildSequence {
    param([string]$buildsDir, [string]$buildDate, [string]$status, [string]$version, [string]$appName)
    if (-not (Test-Path $buildsDir)) { return 1 }
    $pattern = "${appName}_${version}_${status}_${buildDate}_\d{2}\.apk"
    $existing = Get-ChildItem -Path $buildsDir -Filter "*.apk" -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match $pattern }
    if ($null -eq $existing -or $existing.Count -eq 0) { return 1 }
    $max = 0
    foreach ($f in $existing) {
        if ($f.Name -match "${appName}_${version}_${status}_${buildDate}_(\d{2})\.apk") {
            $s = [int]$matches[1]; if ($s -gt $max) { $max = $s }
        }
    }
    return $max + 1
}

function Backup-OriginalAPK {
    param([string]$apkPath)
    $backupDir = Join-Path (Split-Path $apkPath) "backup"
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupName = "app_$(Split-Path $apkPath -Leaf)_$timestamp.apk"
    Copy-Item -Path $apkPath -Destination (Join-Path $backupDir $backupName) -Force
    Write-Host "[BACKUP] -> backup\$backupName" -ForegroundColor Yellow
}

function Rename-APK {
    param([string]$apkPath, [string]$status, [string]$version, [string]$buildDate, [int]$sequence, [string]$appName)
    $newName = "${appName}_${version}_${status}_${buildDate}_$($sequence.ToString('00')).apk"
    $newPath = Join-Path (Split-Path $apkPath) $newName
    if (Test-Path $newPath) { Write-Warning "Target exists: $newPath"; return $false }
    Rename-Item -Path $apkPath -NewName $newName -Force
    Write-Host "[RENAME] -> $newName" -ForegroundColor Green
    return $true
}

# === 主流程 ===
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "$appName APK Build Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$vi = Get-VersionFromPubspec -pubspecPath $pubspecPath
$Version = $vi.Version; $BuildNumber = $vi.BuildNumber
$buildDate = Get-BuildDate
$apkOutputDir = Join-Path $projectRoot "build\app\outputs\flutter-apk"

# 正式发布产物统一归档到仓库根的 builds/release/。
$buildsDir = Join-Path $projectRoot "..\builds\release"
if (-not (Test-Path $buildsDir)) { New-Item -ItemType Directory -Path $buildsDir | Out-Null }

# APK 按平台分类归档到 builds/release/android/（Windows zip 归档到 release/windows/）
$androidDir = Join-Path $buildsDir "android"
if (-not (Test-Path $androidDir)) { New-Item -ItemType Directory -Path $androidDir | Out-Null }

# 计算新版本号
if ($TargetVersion) {
    if ($TargetVersion -notmatch '^\d+\.\d+\.\d+$') { Write-Error "Invalid TargetVersion: $TargetVersion"; exit 1 }
    $releaseVersion = $TargetVersion
} else {
    $releaseVersion = Get-IncrementedVersion -currentVersion $Version -status $Status
}
$releaseBuildNumber = $BuildNumber + 1

Write-Host "Version: $Version+$BuildNumber -> $releaseVersion+$releaseBuildNumber" -ForegroundColor Cyan

# 关键：先更新 pubspec，再构建
Update-VersionInPubspec -pubspecPath $pubspecPath -newVersion $releaseVersion -newBuildNumber $releaseBuildNumber

$buildSequence = Get-BuildSequence -buildsDir $androidDir -buildDate $buildDate -status $Status -version $releaseVersion -appName $appName

Write-Host "Building..." -ForegroundColor Green
Set-Location $projectRoot
$flutterBuildArgs = @("build", "apk", "--$BuildType")
if ($NoPub) { $flutterBuildArgs += "--no-pub" }
& flutter @flutterBuildArgs
if ($LASTEXITCODE -ne 0) {
    Update-VersionInPubspec -pubspecPath $pubspecPath -newVersion $Version -newBuildNumber $BuildNumber
    Write-Error "Build failed! Version rolled back to $Version+$BuildNumber"; exit 1
}

$apkFile = Join-Path $apkOutputDir "app-$BuildType.apk"
if (-not (Test-Path $apkFile)) { Write-Error "APK not found: $apkFile"; exit 1 }

Backup-OriginalAPK -apkPath $apkFile

$newApkName = "${appName}_${releaseVersion}_${Status}_${buildDate}_$($buildSequence.ToString('00')).apk"
if (Rename-APK -apkPath $apkFile -status $Status -version $releaseVersion -buildDate $buildDate -sequence $buildSequence -appName $appName) {
    $newApkPath = Join-Path $apkOutputDir $newApkName
    $buildsApkPath = Join-Path $androidDir $newApkName
    Copy-Item -Path $newApkPath -Destination $buildsApkPath -Force
    Write-Host "[ARCHIVE] Copied to builds/release/android: $newApkName" -ForegroundColor Green

    # 追加双份 build_history.json
    $archiver = Join-Path $scriptPath "archive_history.py"
    if (Test-Path $archiver) {
        & python $archiver $newApkName
    }

    $fi = Get-Item $buildsApkPath
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Build Complete!" -ForegroundColor Green
    Write-Host "  APK:      $buildsApkPath" -ForegroundColor White
    Write-Host "  Size:     $([math]::Round($fi.Length / 1MB, 2)) MB" -ForegroundColor Gray
    Write-Host "  Version:  $releaseVersion+$releaseBuildNumber" -ForegroundColor Gray
    Write-Host "  Sequence: $($buildSequence.ToString('00'))" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Cyan
} else {
    Write-Error "Rename failed!"; exit 1
}
