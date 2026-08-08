# packages/ — 包管理器分发产物

本目录存放推送 GitHub Packages（或其他包仓库）的产物，与 `release/`（人工/渠道分发）分离。

**包是跨端的**——不按平台划分，按**包生态**划分：

| 目录 | 包形态 | 生态 / 仓库 | 适用 |
|------|--------|-------------|------|
| `npm/` | `.tgz` | npm（GitHub Packages npm registry） | JS/TS/跨端共享代码（一个包多处用，不分平台） |
| `maven/` | `.aar` / `.jar` + pom | Maven（GitHub Packages Maven registry） | Android 组件（坐标 `groupId:artifactId:version`） |
| `nuget/` | `.nupkg` | NuGet（GitHub Packages NuGet registry） | .NET / Windows 组件 |
| `release_notes/` | `md` | — | 每个包版本的说明 |

## 约定

- 产物（tgz/aar/nupkg）由 CI / 发布脚本生成，**不入库**（见根 .gitignore）
- 推送前在 `release_notes/` 写对应版本说明；发布后回填记录
- 发布流程参考 `D:\Code\.Rules\common\core\npm-private-publish.md`（GitHub Packages 私有包规范）
