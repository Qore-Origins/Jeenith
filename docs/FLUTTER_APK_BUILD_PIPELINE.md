# Flutter APK 构建流水线规范（可复用版 / Agent-Ready）

> **目标**：将"构建 → 重命名 → 备份 → 归档 → 记录历史"全流程标准化，可直接套用到任意 Flutter Android 项目。
>
> **受众**：人类开发者 **+ AI 智能体**。第 0 章为智能体必读 SOP，可独立消费。
>
> **来源**：从 Loop 项目实战提炼。Loop 已用此规范管理 27+ 个构建产物，零文件覆盖、零版本冲突。
>
> **版本**：v1.1.0 / 2026-07-02

---

## 目录

- [**0. 智能体必读 SOP**](#0-智能体必读-sop-agent-only)
- [1. 设计原则](#1-设计原则)
- [2. 整体目录结构](#2-整体目录结构)
- [3. 命名规范](#3-命名规范)
- [4. 版本号管理](#4-版本号管理)
- [5. 构建状态（status）](#5-构建状态status)
- [6. 构建脚本](#6-构建脚本)
- [7. 构建历史记录](#7-构建历史记录)
- [8. 使用流程](#8-使用流程)
- [9. 跨项目迁移步骤](#9-跨项目迁移步骤)
- [10. 常见问题](#10-常见问题)

---

## 1. 设计原则

| 原则 | 说明 |
|------|------|
| **永不覆盖** | 同版本/同日期/同状态的多次构建自动加序号（`_01` → `_02` → `_03`），所有历史产物永久保留 |
| **永不冲突** | `versionCode` 严格递增，Android 系统可识别为升级，避免"同 versionCode 无法覆盖安装"问题 |
| **版本前置** | 构建前先更新 `pubspec.yaml`，构建失败自动回滚，保证版本号与产物一一对应 |
| **持久化归档** | 产物存放在 `builds/` 而非 `build/`，不受 `flutter clean` 影响 |
| **可追溯** | 每次构建在两份 `build_history.json` 留迹，包含 SHA256、时间戳、源路径、目标路径 |

---

## 2. 整体目录结构

```
your_project/                       # 仓库根目录（solution root）
├── your_app/                       # Flutter 应用目录（项目根）
│   ├── pubspec.yaml                # 版本号来源：version: X.Y.Z+N
│   ├── scripts/
│   │   ├── build_apk.ps1          # 主构建脚本（核心）
│   │   ├── rename_apk.ps1         # 仅重命名（可选）
│   │   └── README.md              # 脚本说明
│   ├── build/                      # Flutter 原始构建产物（不入版本控制）
│   │   └── app/outputs/flutter-apk/
│   │       ├── app-release.apk              # Flutter 原始输出
│   │       ├── Loop_0.1.3_fix_*.apk         # 重命名后的文件
│   │       └── backup/                       # 原始 APK 时间戳备份
│   │           └── app_app-release.apk_20260702_191429.apk
│   └── build_history.json          # 历史记录副本 1（项目内）
│
└── builds/                         # 持久化归档目录
    └── release/                    # 正式分发产物（按平台分类）
        ├── android/                # Android APK（脚本自动归档）
        │   ├── Loop_0.0.14_fix_20260625_01.apk
        │   ├── Loop_0.0.14_fix_20260625_02.apk
        │   └── Loop_0.1.0_fix_20260702_01.apk
        ├── windows/                # Windows 桌面 zip（手动归档）
        │   └── Loop_0.1.0_fix_20260702_01_windows_x64.zip
        ├── release_notes/          # 各版本 Release 说明 markdown
        │   └── release_notes_v0.1.0.md
        ├── build_history.json      # 构建历史（归档区主副本）
        └── release_history.json    # 平台发布记录（GitHub Release 等）

```

**关键路径说明**：

| 路径 | 用途 | 是否入版本控制 |
|------|------|----------------|
| `scripts/build_apk.ps1` | 主构建脚本 | ✅ 是 |
| `build/app/outputs/flutter-apk/` | Flutter 原始输出 | ❌ 否（gitignore） |
| `build/app/outputs/flutter-apk/backup/` | 原始 APK 时间戳备份 | ❌ 否 |
| `builds/release/android/`、`builds/release/windows/` | 持久化归档区（按平台分类，APK/zip） | ❌ 否（产物，用 NAS/云盘备份） |
| `build_history.json`（两份） | 构建历史 JSON | ✅ 是 |
| `builds/release/release_history.json` | 平台发布记录 | ✅ 是 |
| `builds/release/release_notes/*.md` | 各版本 Release 说明 markdown | ✅ 是 |

---

## 3. 命名规范

### 3.1 文件名格式

```
{程序名}_{版本号}_{状态}_{构建日期}_{构建序号}.apk
```

**示例**：

```
Loop_0.1.3_fix_20260702_01.apk
^^^^ ^^^^^ ^^^ ^^^^^^^^ ^^
│    │     │   │        └─ 序号（同日同版本递增）
│    │     │   └────────── 日期 YYYYMMDD
│    │     └────────────── 状态英文标识
│    └──────────────────── 版本号 X.Y.Z（来自 pubspec.yaml）
└───────────────────────── 程序名（PascalCase）
```

### 3.2 序号规则（关键）

> **序号的存在是为了让"同日同版本多次构建"的所有产物都保留，绝不覆盖。**

| 触发条件 | 序号取值 |
|----------|----------|
| 新版本（X.Y.Z 变化） | 从 `01` 开始 |
| 同版本但日期变化 | 从 `01` 开始（不同日期独立计数） |
| 同版本同日期第 1 次构建 | `01` |
| 同版本同日期第 2 次构建 | `02` |
| 同版本同日期第 N 次构建 | `NN`（两位零填充） |

序号通过扫描 `builds/` 目录中匹配的文件计算，**不依赖 `build/` 目录**（因为 `flutter clean` 会清空 `build/`）。

### 3.3 命名冲突保护

脚本在 `Rename-APK` 步骤会检测目标文件名是否已存在：

```powershell
if (Test-Path $newPath) {
    Write-Warning "Target already exists: $newPath"
    return $false
}
```

理论上序号机制保证不会冲突，这是双保险。

---

## 4. 版本号管理

### 4.1 pubspec.yaml 格式

```yaml
version: 0.1.3+21
        ^^^^^ ^^
        │     └─ buildNumber（Android versionCode）
        └─────── versionName（X.Y.Z 三段式）
```

Flutter 构建时会自动把 `+N` 部分作为 Android `versionCode`，前半段作为 `versionName`。

### 4.2 自动递增规则

| status | 递增字段 | 示例 |
|--------|----------|------|
| `release` | minor+1，patch 归零 | `0.1.3+21` → `0.2.0+22` |
| 其他所有状态（fix/alpha/beta/...） | patch+1 | `0.1.3+21` → `0.1.4+22` |
| 手动指定 `-TargetVersion` | 任意跳转 | `0.1.3+21` → `1.0.0+22`（major 升级） |

**`buildNumber` 永远 +1**，确保 Android 能识别为升级。

### 4.3 版本前置策略（重要）

```
正确顺序：更新 pubspec.yaml → flutter build → 重命名归档
                  ↑
              构建前完成
```

**为什么前置？**

- APK 内部的 `versionCode` / `versionName` 在构建时**烧录**到 `AndroidManifest.xml`
- 必须在 `flutter build` 之前修改 `pubspec.yaml`，APK 内部版本才会与文件名一致
- 早期版本曾"先构建再改版本号"，导致 APK 内部 versionCode 与文件名不匹配，无法覆盖安装

**构建失败回滚**：

```powershell
if ($LASTEXITCODE -ne 0) {
    Update-VersionInPubspec ... $Version $BuildNumber  # 还原
    Write-Error "Build failed! Version rolled back"
    exit 1
}
```

---

## 5. 构建状态（status）

| 英文标识 | 中文名称 | 完整性 | 使用场景 |
|----------|----------|--------|----------|
| `release` | 正式版 | ✅ 完全体 | 生产发布，触发 minor+1 递增 |
| `rc` | 候选版 | ✅ 接近完全体 | 发布前最终测试 |
| `fix` | 修复版 | ✅ 完全体 | Bug 修复（最常用） |
| `hotfix` | 紧急修复 | ✅ 完全体 | 生产严重问题紧急修复 |
| `beta` | 测试版 | ⚠️ 非完全体 | 公测 |
| `feature` | 功能版 | ⚠️ 非完全体 | 新功能开发分支 |
| `alpha` | 内测版 | ❌ 非完全体 | 内部测试 |
| `dev` | 开发版 | ❌ 非完全体 | 日常开发 |
| `debug` | 调试版 | ❌ 非完全体 | 调试用 |

---

## 6. 构建脚本

### 6.1 完整脚本（build_apk.ps1）

> **复制即用**：把 `Loop` 替换为你的应用名（`$appName` 变量）。

```powershell
param(
    [ValidateSet("debug", "release", "profile")]
    [string]$BuildType = "release",

    [ValidateSet("release", "beta", "alpha", "rc", "fix", "hotfix", "feature", "dev", "debug")]
    [string]$Status = "release",

    [string]$TargetVersion,

    [switch]$NoPub
)

$ErrorActionPreference = "Stop"

# === 配置区（迁移时改这里） ===
$appName = "Loop"   # TODO: 改成你的应用名

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$pubspecPath = Join-Path $projectRoot "pubspec.yaml"

function Get-VersionFromPubspec {
    param([string]$pubspecPath)
    if (-not (Test-Path $pubspecPath)) {
        Write-Error "pubspec.yaml not found: $pubspecPath"
        exit 1
    }
    $content = Get-Content $pubspecPath -Raw
    if ($content -match "version:\s*(\d+\.\d+\.\d+)\+(\d+)") {
        return @{ Version = $matches[1]; BuildNumber = [int]$matches[2] }
    }
    Write-Error "Cannot read version from pubspec.yaml"
    exit 1
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
        default { $patch++ }
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
    if ($existing.Count -eq 0) { return 1 }
    $max = 0
    foreach ($f in $existing) {
        if ($f.Name -match "${appName}_${version}_${status}_${buildDate}_(\d{2})\.apk") {
            $s = [int]$matches[1]
            if ($s -gt $max) { $max = $s }
        }
    }
    return $max + 1
}

function Backup-OriginalAPK {
    param([string]$apkPath)
    $backupDir = Join-Path (Split-Path $apkPath) "backup"
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir | Out-Null
    }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupName = "app_$(Split-Path $apkPath -Leaf)_$timestamp.apk"
    $backupPath = Join-Path $backupDir $backupName
    Write-Host "[BACKUP] $(Split-Path $apkPath -Leaf) -> backup\$backupName" -ForegroundColor Yellow
    Copy-Item -Path $apkPath -Destination $backupPath -Force
}

function Rename-APK {
    param([string]$apkPath, [string]$status, [string]$version, [string]$buildDate, [int]$sequence, [string]$appName)
    $sequenceStr = $sequence.ToString("00")
    $newName = "${appName}_${version}_${status}_${buildDate}_${sequenceStr}.apk"
    $newPath = Join-Path (Split-Path $apkPath) $newName
    if (Test-Path $newPath) {
        Write-Warning "Target already exists: $newPath"
        return $false
    }
    Write-Host "[RENAME] $(Split-Path $apkPath -Leaf) -> $newName" -ForegroundColor Green
    Rename-Item -Path $apkPath -NewName $newName -Force
    return $true
}

# === 主流程 ===
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "$appName APK Build Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$versionInfo = Get-VersionFromPubspec -pubspecPath $pubspecPath
$Version = $versionInfo.Version
$BuildNumber = $versionInfo.BuildNumber
$buildDate = Get-BuildDate
$apkOutputDir = Join-Path $projectRoot "build\app\outputs\flutter-apk"

$solutionRoot = Split-Path -Parent $projectRoot
$buildsDir = Join-Path $solutionRoot "builds\release"
if (-not (Test-Path $buildsDir)) {
    New-Item -ItemType Directory -Path $buildsDir | Out-Null
}

# APK 按平台分类归档到 builds/release/android/（Windows zip 手动归档到 builds/release/windows/）
$androidDir = Join-Path $buildsDir "android"
if (-not (Test-Path $androidDir)) {
    New-Item -ItemType Directory -Path $androidDir | Out-Null
}

# 计算新版本号
if ($TargetVersion) {
    if ($TargetVersion -notmatch '^\d+\.\d+\.\d+$') {
        Write-Error "Invalid TargetVersion format. Expected 'X.Y.Z', got: $TargetVersion"
        exit 1
    }
    $releaseVersion = $TargetVersion
} else {
    $releaseVersion = Get-IncrementedVersion -currentVersion $Version -status $Status
}
$releaseBuildNumber = $BuildNumber + 1

Write-Host "Version: $Version+$BuildNumber -> $releaseVersion+$releaseBuildNumber" -ForegroundColor Cyan

# 关键：先更新 pubspec.yaml，再构建
Update-VersionInPubspec -pubspecPath $pubspecPath -newVersion $releaseVersion -newBuildNumber $releaseBuildNumber

$buildSequence = Get-BuildSequence -buildsDir $androidDir -buildDate $buildDate -status $Status -version $releaseVersion -appName $appName

Write-Host "Building..." -ForegroundColor Green
Set-Location $projectRoot
$flutterBuildArgs = @("build", "apk", "--$BuildType")
if ($NoPub) { $flutterBuildArgs += "--no-pub" }
& flutter @flutterBuildArgs

if ($LASTEXITCODE -ne 0) {
    # 构建失败：回滚版本号
    Update-VersionInPubspec -pubspecPath $pubspecPath -newVersion $Version -newBuildNumber $BuildNumber
    Write-Error "Build failed! Version rolled back to $Version+$BuildNumber"
    exit 1
}

# 处理产物
$apkFile = Join-Path $apkOutputDir "app-$BuildType.apk"
if (-not (Test-Path $apkFile)) {
    Write-Error "APK not found: $apkFile"
    exit 1
}

Backup-OriginalAPK -apkPath $apkFile

if (Rename-APK -apkPath $apkFile -status $Status -version $releaseVersion -buildDate $buildDate -sequence $buildSequence -appName $appName) {
    $newApkName = "${appName}_${releaseVersion}_${Status}_${buildDate}_$($buildSequence.ToString('00')).apk"
    $newApkPath = Join-Path $apkOutputDir $newApkName
    $buildsApkPath = Join-Path $androidDir $newApkName

    Copy-Item -Path $newApkPath -Destination $buildsApkPath -Force
    Write-Host "[ARCHIVE] Copied to builds/release/android: $newApkName" -ForegroundColor Green

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Build Complete!" -ForegroundColor Green
    Write-Host "  APK:      $buildsApkPath" -ForegroundColor White
    $fileInfo = Get-Item $buildsApkPath
    Write-Host "  Size:     $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
    Write-Host "  Version:  $releaseVersion+$releaseBuildNumber" -ForegroundColor Gray
    Write-Host "  Sequence: $($buildSequence.ToString('00'))" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Cyan
} else {
    Write-Error "Rename failed!"
    exit 1
}
```

### 6.2 调用方式

```powershell
# 必须用 pwsh（PowerShell 7+），因为脚本含中文注释
# 旧版 powershell.exe (5.x) 会因 UTF-8 编码问题报错

# 标准构建（fix 状态，patch+1 递增）
pwsh -File scripts/build_apk.ps1 -BuildType release -Status fix

# 测试版
pwsh -File scripts/build_apk.ps1 -Status beta

# 正式版（minor+1 递增）
pwsh -File scripts/build_apk.ps1 -Status release

# 指定目标版本（跨 minor/major 升级）
pwsh -File scripts/build_apk.ps1 -Status fix -TargetVersion "1.0.0"

# Debug 构建
pwsh -File scripts/build_apk.ps1 -BuildType debug -Status dev
```

### 6.3 PowerShell 版本要求（重要）

| Shell | 是否可用 | 原因 |
|-------|----------|------|
| `pwsh`（PowerShell 7+） | ✅ 推荐 | 完美支持 UTF-8 中文注释 |
| `powershell.exe`（Windows PowerShell 5.x） | ❌ 不可用 | 默认编码 GBK，解析中文注释会报"意外的标记"错误 |

---

## 7. 构建历史记录

### 7.1 双份历史策略

| 文件位置 | 角色 | schema 风格 |
|----------|------|-------------|
| `your_app/build_history.json` | 项目内副本 | version 与 buildNumber 分离 |
| `builds/release/build_history.json` | 归档区主副本 | version 合并显示（带 buildNumber） |

> 产物按平台分类归档后，记录里的 `targetPath` / `filePath` 也相应带平台子目录：
> APK → `builds/release/android/`，Windows zip → `builds/release/windows/`。

**为什么要两份？**

- 归档区副本（`builds/`）随产物一起走，是 **唯一的真相来源**
- 项目内副本（`your_app/`）方便 git 跟踪和团队成员查阅，不需要进入 `builds/` 即可看到历史

### 7.2 Schema 示例

**builds/release/build_history.json（主副本，详细字段）**：

```json
{
  "project": "Loop",
  "description": "Loop - 周期计划管理应用",
  "namingRule": "{程序名}_{版本号}_{状态}_{日期}_{序号}.{扩展名}",
  "builds": [
    {
      "version": "0.1.3+21",
      "status": "fix",
      "statusLabel": "修复版",
      "date": "20260702",
      "sequence": 1,
      "filename": "Loop_0.1.3_fix_20260702_01.apk",
      "timestamp": "2026-07-02T19:14:29",
      "fileSize": 108766172,
      "fileSizeFormatted": "103.73 MB",
      "sha256": "E6518E29...",
      "sourcePath": "D:\\Code\\Project\\Loop\\loop_app\\build\\app\\outputs\\flutter-apk\\app-release.apk",
      "targetPath": "D:\\Code\\Project\\Loop\\builds\\android\\Loop_0.1.3_fix_20260702_01.apk",
      "backupPath": "D:\\Code\\Project\\Loop\\loop_app\\build\\app\\outputs\\flutter-apk\\backup\\app_app-release.apk_20260702_191429.apk",
      "platform": "android-arm64,android-arm,android-x64",
      "verificationPassed": true
    }
  ]
}
```

**your_app/build_history.json（项目内副本）**：

```json
{
  "project": "Loop",
  "namingFormat": "{app_name}_{version}_{status}_{date}_{seq}.{ext}",
  "builds": [
    {
      "version": "0.1.3",
      "buildNumber": 21,
      "status": "fix",
      "date": "20260702",
      "sequence": 1,
      "filename": "Loop_0.1.3_fix_20260702_01.apk",
      "originalName": "app-release.apk",
      "filePath": "d:\\Code\\Project\\Loop\\builds\\android\\Loop_0.1.3_fix_20260702_01.apk",
      "fileSize": 108766172,
      "fileSizeHuman": "103.73 MB",
      "sha256": "E6518E29...",
      "buildType": "apk",
      "platform": "android",
      "timestamp": "2026-07-02T19:14:29",
      "configSource": "pubspec.yaml"
    }
  ]
}
```

### 7.3 追加规则

每次构建完成后，由独立的"version-manager"子代理（或脚本）负责：

1. **计算实际值**：用 PowerShell 算出真实的 `fileSize` 和 `SHA256`
2. **读取 → 追加 → 写回**：`ConvertFrom-Json` → `+=` 新记录 → `ConvertTo-Json -Depth 10`
3. **保持 schema 一致**：两个文件的字段命名各自独立维护，不要强行统一
4. **校验**：写完后用 `ConvertFrom-Json` 重新解析，确保 JSON 有效性
5. **永远追加，不覆盖**：任何已有记录都不能修改

### 7.4 SHA256 计算命令

```powershell
Get-FileHash "D:\path\to\file.apk" -Algorithm SHA256 | Select-Object -ExpandProperty Hash
```

返回大写 64 位 hex 字符串，**写入历史时保持大写**以匹配现有格式。

### 7.5 平台发布记录（release_history.json + release_notes/）

`builds/release/release_history.json` 记录在 GitHub 等平台发布的 Release 信息，字段对应 GitHub "New release" 表单：

| 字段 | 说明 |
|------|------|
| `tag` / `target` | Release 标签（`v<语义版本>`）/ 目标分支 |
| `title` | Release 标题 |
| `notesFile` | 指向 `builds/release/release_notes/release_notes_<tag>.md`——**notes 正文存独立 md 文件**（真实换行，便于直接复制粘贴到平台 notes 框，避免 JSON `\n` 转义在粘贴时失效） |
| `assets[]` | 发布附件（APK + Windows zip），含 `size` / `sha256` / `localPath` / `downloadUrl` |
| `label` / `isLatest` / `isPreRelease` | Latest / Pre-release 标记 |
| `status` | `draft`（待发布）/ `published`（已发布）/ `unpublished`（仅本地构建，未上平台） |
| `url` / `publishedAt` / `downloadUrl` | 发布后回填 |

**为什么 notes 用独立 md 而非 JSON 字符串？** JSON 字符串里的 `\n` 是字面转义，从文本编辑器复制粘贴到 GitHub Release notes 框时不会被解释成换行。独立 md 文件是真实换行，全选复制粘贴即可正常 Preview。

---

## 8. 使用流程

### 8.1 单次构建完整流程

```
开发者执行命令
    ↓
脚本读取 pubspec.yaml 当前版本
    ↓
计算新版本号（自动递增 or -TargetVersion）
    ↓
更新 pubspec.yaml（关键前置步骤）
    ↓
flutter build apk --release
    ↓
   ┌─ 成功 → 继续
   └─ 失败 → 回滚 pubspec.yaml → 退出
    ↓
扫描 builds/ 计算序号
    ↓
备份原始 app-release.apk 到 backup/
    ↓
重命名为标准格式
    ↓
复制到 builds/ 持久化目录
    ↓
追加两份 build_history.json
    ↓
验证 APK 内部 versionCode/versionName 与文件名一致
```

### 8.2 验证 APK 内部版本

```powershell
# 用 Android aapt 工具读取 APK 内部版本
& "$env:ANDROID_HOME\build-tools\34.0.0\aapt.exe" dump badging "path\to\app.apk" |
    Select-String "versionCode|versionName"
```

输出示例：

```
package: name='com.example.loop' versionCode='21' versionName='0.1.3' ...
```

确认 `versionCode` 和 `versionName` 与文件名完全一致，否则无法正常覆盖安装。

---

## 9. 跨项目迁移步骤

把这套规范套到新 Flutter 项目，只需 5 步：

### Step 1：准备目录结构

```
your_repo/
├── your_app/           # 已存在的 Flutter 项目
│   └── scripts/        # 新建
│       └── build_apk.ps1
└── builds/             # 新建（与 your_app 平级）
```

### Step 2：复制脚本

把本文档第 6.1 节的脚本完整复制到 `your_app/scripts/build_apk.ps1`。

### Step 3：修改应用名

打开脚本，找到：

```powershell
$appName = "Loop"
```

改成你的应用名（PascalCase）：

```powershell
$appName = "MindCareAI"
```

### Step 4：确认 pubspec.yaml 格式

确保 `pubspec.yaml` 顶部有：

```yaml
version: 0.0.1+1
```

格式必须是 `X.Y.Z+N`（三段版本号 + 加号 + buildNumber）。

### Step 5：首次构建测试

```powershell
cd your_app
pwsh -File scripts/build_apk.ps1 -Status alpha
```

预期输出：

```
[VERSION] Updated: 0.0.2+2
[BACKUP] app-release.apk -> backup\app_app-release.apk_*.apk
[RENAME] app-release.apk -> MindCareAI_0.0.2_alpha_20260101_01.apk
[ARCHIVE] Copied to builds: MindCareAI_0.0.2_alpha_20260101_01.apk
```

迁移完成。

---

## 10. 常见问题

### Q1: 同样的代码为什么每次构建 SHA256 都不同？

**A**: 即使源码完全相同，Flutter 构建过程会注入构建时间戳、Gradle 缓存 ID 等，导致字节级差异。这是正常现象，不影响功能。

### Q2: 跨日期构建序号会重置吗？

**A**: 会。序号只在"同日同版本同状态"维度下递增，跨日期或跨版本都会从 `01` 重新开始。这是为了让"今天构建了多少次"一目了然。

### Q3: 同 versionCode 的两个 APK 能互相覆盖安装吗？

**A**: 不能。Android 系统通过 `versionCode` 判断升级，相同则拒绝覆盖。所以脚本每次都让 `buildNumber` +1，确保 versionCode 持续递增。

### Q4: 如何手动指定版本号（比如跳到 1.0.0）？

**A**: 用 `-TargetVersion` 参数：

```powershell
pwsh -File build_apk.ps1 -Status fix -TargetVersion "1.0.0"
```

脚本会跳过自动递增逻辑，直接用指定版本。注意 `buildNumber` 仍然 +1。

### Q5: 构建失败会污染 pubspec.yaml 吗？

**A**: 不会。脚本检测 `$LASTEXITCODE -ne 0` 后会立即调用 `Update-VersionInPubspec` 还原原版本号，然后退出。

### Q6: 为什么必须用 pwsh 而不是 powershell.exe？

**A**: 脚本含中文注释，PowerShell 5.x 默认用 GBK 编码读取，会因 UTF-8 字符解析失败报"意外的标记}"错误。PowerShell 7+ 默认 UTF-8，无此问题。

### Q7: builds/ 目录需要 git 跟踪吗？

**A**: 一般**不入 git**（APK 是大二进制文件，会让仓库膨胀）。推荐方案：
- `builds/` 加入 `.gitignore`
- 用 NAS / 云盘 / 团队共享盘备份
- `build_history.json`（两份）入 git，作为构建记录的可追溯凭证

### Q8: 如何列出所有历史构建？

```powershell
# 按时间倒序
Get-ChildItem "D:\Code\Project\Loop\builds" -Filter "Loop_*.apk" |
    Sort-Object LastWriteTime -Descending |
    Select-Object Name, @{N='Size(MB)';E={[math]::Round($_.Length/1MB,2)}}, LastWriteTime
```

---

## 附录：实战数据样本（Loop 项目）

截至 2026-07-02，Loop 项目用此规范积累了 **27 个构建产物**：

| 维度 | 数据 |
|------|------|
| 跨日期范围 | 2026-03-31 ~ 2026-07-02（94 天） |
| 版本演进 | 0.0.1 → 0.1.3（13 个 versionName） |
| versionCode 范围 | 1 → 21 |
| 状态分布 | alpha×8, fix×19 |
| 单日最大构建次数 | 4（2026-06-25 同版本构建 _01/_02/_03 + 跨版本构建） |
| 文件覆盖事件 | 0（永不覆盖） |
| versionCode 冲突事件 | 0（持续递增） |

**结论**：规范经实战验证稳定可靠，可直接迁移到任何 Flutter Android 项目。
