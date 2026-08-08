# v2.10.4 — DarkButton 浅色适配补齐 + configProvider 订阅修复 + SvgIcon fallback 主题感知

## 概述

v2.10.0 浅色模式深度适配时遗漏了 DarkButton 组件——它仍用 v2.0.0 旧色板（紫黑渐变 + 浅金字硬编码 `Color(0xFF...)`），浅色模式下与设置页 / GoldButton 配色不一致，混用深浅元素。本版本补齐 DarkButton 主题感知，并修复其 configProvider 订阅问题（设置页切换动画开关后按钮不即时重建），同时为 SvgIcon 的 fallback 色补上主题感知。

经全项目审计确认：DarkButton 是 v2.10.0 浅色适配时**唯一遗漏的共享组件**，其余 32 个 widget/page 文件（含 starfield / divination_wheel / 各术主页面）均已正确主题感知。

## 修复内容

### 1. DarkButton 主题感知补齐

**问题**：DarkButton 的 `labelColor` / `gradTop` / `gradBottom` / `borderColor` 全部硬编码深色常量（紫黑渐变 `0xFF3A2F4A`→`0xFF241C30` + 浅金字 `0xFFF0E6CF`），浅色模式下与设置页配色基准不一致。

**修复**：颜色全部改用 `AppClr.of(context)` + `c.resolve(深色, 浅色)`：
- 深色：沿用紫黑渐变 + 浅金字
- 浅色：切换为浅米渐变（`AppColorsLight.buttonTop/buttonBottom`）+ 深棕字（`0xFF2E2210`），与设置页配色基准对齐

**影响文件**：`mobile/lib/shared/widgets/dark_button.dart`

### 2. DarkButton configProvider 订阅修复

**问题**：`_animEnabled` 旧实现是 `bool get _animEnabled => ref.read(configProvider)...` getter。`ref.read` 不建立订阅，设置页切换 `animationsEnabled` 开关后按钮不会即时重建（动画/静态形态不切换）。

**修复**：改为 **build 中 `ref.watch` 订阅 + 实例字段缓存** 模式（与 GoldButton / AnimatedExpandIcon 统一）：
- 新增实例字段 `bool _animEnabled = true`
- build 首行 `_animEnabled = ref.watch(configProvider).valueOrNull?.animationsEnabled ?? true`
- tap 回调（`_onTapDown` / `_onTapUp` / `_onTapCancel`）读字段缓存，避免在非 build 上下文调 `ref.watch`

**影响文件**：`mobile/lib/shared/widgets/dark_button.dart`

### 3. SvgIcon fallback 主题感知

**问题**：SvgIcon 的 fallback 色用 `theme.color` 硬编码，无 IconTheme 时无主题感知。

**修复**：改为 `color ?? theme.color ?? context.appClr.textPrimary`，浅色模式下回退为深棕字（`0xFF2E2210`），对比度充足。

**影响文件**：`mobile/lib/shared/widgets/svg_icon.dart`

### 4. 文档同步

- 同步 `docs/工作流程.md` 至 v1.1.0 / 2026-07-23：补全 features 目录（chenggu / taiyi / liuyao 三新术）+ 附录里程碑 v2.4.1~v2.10.3 + 示例版本号更新
- 更新 `CLAUDE.md` 第五节后续阶段：补充 v2.10.4 条目，更新"后续可考虑"为仪式动画浅色适配 / 引导遮罩扩展 / v3.0.0 规划

**影响文件**：`docs/工作流程.md`、`CLAUDE.md`

## 验证

- `flutter analyze`：No issues found（5 个关键文件 + 全项目）
- 浅色模式审计：32 个文件已主题感知，DarkButton 是唯一遗漏（本版本已补齐）
- DarkButton configProvider 订阅：设置页切换开关即时重建，与 GoldButton 行为一致

## 自 v2.10.3 以来的提交

| Commit | 类型 | 说明 |
|--------|------|------|
| `0bc617c` | fix | DarkButton 浅色适配补齐 + configProvider 订阅修复 + SvgIcon fallback 主题感知 |
| `7a4c8c3` | docs | 同步工作流程文档至 v2.10.3+43 + 补全版本里程碑 |
| `c54e3fa` | docs | 更新 CLAUDE.md 后续阶段至 v2.10.4 + 清理 HANDOFF 文档 |

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.10.4_fix_20260723_01.apk | 58.84 MB | `738AC0B62CA672BC7EC72BF07B9892ED562BDDA26D75DECB9DEDCB042BE81F5F` |
| Windows x64 | Jeenith_2.10.4_fix_20260723_01_windows_x64.zip | 15.66 MB | `5B535462CF3F1A862581D6A92F3817221D9A224BD6E0A53B2E9A53D33524D7FA` |

## 版本信息

- **版本号**：2.10.4+44
- **构建状态**：fix（修复版）
- **构建日期**：2026-07-23
