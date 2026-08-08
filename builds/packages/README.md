# packages/ — 包管理器分发产物

本目录存放推送 GitHub Packages（或其他包仓库）的产物，与 `release/`（人工/渠道分发）分离。

## 子目录

| 目录 | 内容 | 包仓库 |
|------|------|--------|
| `android/` | AAR / Maven 坐标产物 | GitHub Packages (Maven) |
| `windows/` | NuGet / 二进制包 | GitHub Packages (NuGet) |
| `release_notes/` | 每个包版本的说明 md | — |

## 约定

- 产物由 CI / 发布脚本生成，**不入库**（见根 .gitignore）
- 推送前在 `release_notes/` 写对应版本说明；发布后回填记录
- 发布流程参考 `D:\Code\.Rules\common\core\npm-private-publish.md`（GitHub Packages 私有包规范）
