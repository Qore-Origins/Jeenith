#requires -Version 7
<#
.SYNOPSIS
  发布 GitHub Release（基于 gh CLI）。元数据来自 builds/release/release_history.json。

.DESCRIPTION
  用 `gh release create` 一条命令创建 release + 上传 assets + 贴 notes——gh 处理认证
  与大文件上传，比手写 curl + REST API 更稳更短。需先 `gh auth login`。
  实际 repo：Qore-Origins/Jeenith。

.PARAMETER Tag
  release tag，如 v2.8.1

.EXAMPLE
  pwsh -File scripts/publish_release.ps1 -Tag v2.8.1
#>
param([Parameter(Mandatory)][string]$Tag)
$ErrorActionPreference = 'Stop'
# 合并系统+用户 PATH（pwsh 经 git bash 启动时可能未继承用户级 PATH，导致 gh 等找不到）
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
$root = (Resolve-Path "$PSScriptRoot/../..").Path   # 项目根 Jeenith/

# 读 release_history.json 取该 tag 的元数据
$hist = Get-Content "$root/builds/release/release_history.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$rel = $hist.releases | Where-Object { $_.tag -eq $Tag } | Select-Object -First 1
if (-not $rel) { throw "release_history.json 中未找到 tag=$Tag" }

$notesPath = Join-Path $root ($rel.notesFile -replace '/', '\')
if (-not (Test-Path $notesPath)) { throw "notes 文件不存在: $notesPath" }

# 组装 gh release create 参数
$ghArgs = @(
    'release', 'create', $rel.tag,
    '--repo', 'Qore-Origins/Jeenith',
    '--target', $rel.target,
    '--title', $rel.title,
    '--latest',
    "--notes-file=$notesPath"
)
if ([bool]$rel.isPreRelease) { $ghArgs += '--prerelease' }
foreach ($a in $rel.assets) {
    $p = Join-Path $root ($a.localPath -replace '/', '\')
    if (Test-Path $p) { $ghArgs += $p }
    else { Write-Warning "asset 缺失，跳过: $p" }
}

Write-Host "gh $($ghArgs -join ' ')" -ForegroundColor DarkGray
& gh @ghArgs
if ($LASTEXITCODE -ne 0) { throw "gh release create 失败 (exit $LASTEXITCODE)" }

Write-Host "[RELEASE] $Tag 已发布" -ForegroundColor Green
Write-Host "  https://github.com/Qore-Origins/Jeenith/releases/tag/$Tag"
