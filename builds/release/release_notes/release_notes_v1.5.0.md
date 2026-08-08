# v1.5.0 — 主题切换 + 结果分享 + 历史导出

**版本**：1.5.0+12
**状态**：feature（多阶段计划第 4 阶段 · 完善性）
**构建日期**：2026-07-13

## 概述

为志极补充主题切换（深色/浅色/跟随系统）、结果截图分享、历史记录导出三大完善性功能。这是多阶段实施计划的第 4 阶段，聚焦于用户体验和实用工具，让用户可以保存和分享自己的卜算结果。

## 新增功能

### 主题切换

- 设置页新增「外观」分区
- 主题模式 SegmentedButton 三态切换：跟随系统 / 浅色 / 深色
- 浅色主题：浅米色背景（#F6F0E2）+ 深金色文字保证对比度
- 主题选择持久化到 SharedPreferences，重启后保持
- `app.dart` 根据 configProvider 动态切换 ThemeData + 背景色 + 星尘色
- Starfield 星点在浅色主题下使用深金色（#9B7A2A）保持可见性

### 结果分享按钮（6 术统一）

- 新建 `ShareResultButton` 组件：通过 `RepaintBoundary.toImage()` 截取结果区为 PNG
- 写入临时文件后调用系统分享（`Share.shareXFiles`）
- 截图失败时自动回退到纯文本分享（`Share.share(fallbackText)`）
- 集成到全部 6 个卜算页面：周易 / 梅花 / 紫微 / 奇门 / 小六壬 / 掷筊
- 与 `CopyResultButton` 并列布局，互不冲突
- 各页结果区包裹 `RepaintBoundary(key: _boundaryKey, ...)` 支持截图

### 历史记录导出

- 新建 `HistoryExport` 工具类，支持三种导出格式：
  - **JSON**：完整保真，可直接重新导入
  - **Markdown**：人类可读表格 + 详情块
  - **CSV**：Excel/WPS 可直接打开（含 UTF-8 BOM）
- 历史页 AppBar 新增导出按钮（`PopupMenuButton`）
- 三项选择：JSON / Markdown / CSV
- 列表为空时 SnackBar 友好提示
- 通过系统分享发送文件（`Share.shareXFiles`）

## 技术要点

- 主题切换链路：`app_config.dart` (themeMode 字段) → `config_providers.dart` (setThemeMode 持久化) → `app.dart` (build() 闭包捕获 config) → `settings_page.dart` (SegmentedButton UI)
- `effectiveLight` 计算移入 `MaterialApp.router` 的 `builder` 内，因为 `MediaQuery.platformBrightnessOf(context)` 必须用 MaterialApp 内部的 context
- ShareResultButton 失败回退链路：截取 RepaintBoundary → 失败 → fallbackText 文本分享 → 仍失败 → 静默
- 桌面端 sliver 页面（周易/小六壬）：将 `SliverList` 改为 `SliverToBoxAdapter` 包裹 `RepaintBoundary`，确保结果可整体截图
- 浅色色系 `AppColorsLight` 与深色 `AppColors` 保持同等五色系语义（金/木/水/火/土）和断语分级色
- 思源宋体因字体文件缺失跳过打包（计划假设 1），后续可补充
- 新增依赖：`share_plus ^10.0.0` + `path_provider ^2.1.0`
- flutter analyze 0 issue

## 修改文件清单

- `mobile/lib/core/theme/app_theme.dart`：新增 AppColorsLight + AppFonts + appTheme({bool isLight})
- `mobile/lib/core/config/app_config.dart`：新增 themeMode 字段 + copyWith
- `mobile/lib/core/config/config_providers.dart`：新增 setThemeMode + build() 读取
- `mobile/lib/app.dart`：动态主题 + 动态背景色 + Starfield isLight 参数
- `mobile/lib/shared/widgets/starfield.dart`：新增 isLight 参数 + 浅色星点色
- `mobile/lib/shared/widgets/share_result_button.dart`：新建文件
- `mobile/lib/core/history/history_export.dart`：新建文件
- `mobile/lib/features/settings/settings_page.dart`：新增「外观」分区 SegmentedButton
- `mobile/lib/features/history/history_page.dart`：新增导出 PopupMenuButton
- `mobile/lib/features/jiaobei/ui/jiaobei_page.dart`：集成 ShareResultButton + RepaintBoundary
- `mobile/lib/features/zhouyi/ui/zhouyi_page.dart`：同上
- `mobile/lib/features/meihua/ui/meihua_page.dart`：同上
- `mobile/lib/features/ziwei/ui/ziwei_page.dart`：同上
- `mobile/lib/features/qimen/ui/qimen_page.dart`：同上
- `mobile/lib/features/xiaoliuren/ui/xiaoliuren_page.dart`：同上
- `mobile/pubspec.yaml`：版本 → 1.5.0+12 + 新增依赖

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|
| Android | Jeenith_1.5.0_feature_20260713_01.apk | 52.43 MB / 54978704 B | 4CF4F3C6D999101E6D74724FA89B504DA47D73643908210628751159DFC2438D |
| Windows x64 | Jeenith_1.5.0_feature_20260713_01_windows_x64.zip | 12.70 MB / 13317110 B | CCE9778BDD889C0D3D995624B81444F2EE6A1527C9FF01AFDF05D272DDFB38A1 |

## 后续阶段预告

- v1.6.0 — 抽签求签 + 测字
- v1.7.0 — 大六壬全套 + 风水罗盘

---

志极 Jeenith · 叩问本心
