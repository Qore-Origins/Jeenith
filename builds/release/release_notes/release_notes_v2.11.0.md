# v2.11.0 — 设置页数据与重置 + 周易/小六壬复制按钮修复

## 概述

本版本新增设置页「数据与重置」分区（清除数据 / 还原初设 / 归零重始三个应用维护入口），并修复周易、小六壬两术结果页复制/分享按钮失效的问题。

## 新增功能

### 1. 设置页「◆ 数据与重置」分区

新增三个按钮，覆盖从精细清除到彻底重置的需求：

| 按钮 | 功能 |
|------|------|
| **清除数据** | 勾选要清除的内容（卜算历史 / 使用指引标记）后清除并重启；设置不受影响 |
| **还原初设** | 将所有设置（主题 / 动画 / 随机 / 展示）恢复为默认，保留卜算历史 |
| **归零重始** | 清除全部数据 + 恢复所有设置（最彻底，不可撤销） |

**应用级重启机制**：新增 `RestartController`——触发时以新 key 重建 `ProviderScope`，所有 Riverpod 状态从已更新的 SharedPreferences 重新初始化，等价"重启应用"，无需新增任何依赖。数据清除逻辑集中到 `AppData`（历史 / 引导标记分类清除），设置重置由 `ConfigNotifier.resetSettings` 负责。

**影响文件**：`mobile/lib/features/settings/settings_page.dart`、`mobile/lib/main.dart`、`mobile/lib/core/app/restart_controller.dart`（新）、`mobile/lib/core/data/app_data.dart`（新）、`mobile/lib/core/config/config_providers.dart`

## Bug 修复

### 2. 周易 / 小六壬复制/分享按钮失效

**现象**：周易、小六壬结果页的"复制结果"/"分享结果"按钮，在已有结果的情况下点击无效（无法点击）。其余 12 个术数正常。

**根因**：两页底部操作栏是 pinned `SliverPersistentHeader`（粘顶固定），其 delegate 误设 `shouldRebuild(_) => false`。`build()` 返回构造时传入的 child，而 `false` 让 Flutter 在页面 setState 后**不重建 header 子树**——内容冻结在首次构建（`r == null`）状态。摇卦后结果区（普通 sliver）正常显示，但 header 不重建，复制/分享按钮的 `enabled` 永远停在初始的 `false`。

**为何摇卦按钮仍可用**：它冻结的状态恰好是 `_busy = false`（enabled），且 `onPressed` 闭包捕获同一 State 实例，仍能触发摇卦逻辑。

**修复**：两处 `shouldRebuild(_) => false` → `true`，并加注释防止回退。

**影响文件**：`mobile/lib/features/zhouyi/ui/zhouyi_page.dart`、`mobile/lib/features/xiaoliuren/ui/xiaoliuren_page.dart`

## 验证

- `flutter analyze`：No issues found
- 全局排查 `shouldRebuild`：仅此两处 pinned header，无其他遗漏
- 桌面/移动端共用同一 header，故两平台均有此 bug，移动端窄屏先暴露

## 自 v2.10.4 以来的提交

| Commit | 类型 | 说明 |
|--------|------|------|
| `5e4cd0a` | feat | 设置页数据与重置（清除数据/还原初设/归零重始）+ 应用级重启 |
| `e78353a` | fix | 周易/小六壬 pinned header 复制/分享按钮失效 |
| `94671b8` | chore | release 2.11.0+45 |

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.11.0_release_20260724_01.apk | 59.17 MB | `CDC3830CBA2702EC1A28426EF0F129BB20BC63D051C3E6C404D49CA45B3F6E09` |
| Windows x64 | Jeenith_2.11.0_release_20260724_01_windows_x64.zip | 15.70 MB | `22F41A8CED0E6CF800A00311038E5890FB108459B3C0E701B76DC93B166426E1` |

## 版本信息

- **版本号**：2.11.0+45
- **构建状态**：release
- **构建日期**：2026-07-24
