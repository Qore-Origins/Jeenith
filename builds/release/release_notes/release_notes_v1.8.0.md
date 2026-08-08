# v1.8.0 — 使用手册页面 + 圆角修复 + 历史复制 + 默认深色

**版本**：1.8.0+15
**状态**：feature（v1.7.0 之后的功能性增强）
**构建日期**：2026-07-13

## 概述

本版本聚焦用户体验完善：新增「使用手册」页面解决时辰边界与历法体系两大常见困惑；修复圆角卡片点击区域与视觉不一致的问题；为历史记录增加复制功能；将默认主题模式从「跟随系统」改为「深色模式」以契合志极的整体视觉调性。

## 新增功能

### 使用手册页面（features/manual/）

- 新增 SVG 手册图标 `assets/icons/manual.svg`（menu_book 风格）
- 新增 `ManualPage`，5 个章节：
  - **基础使用**：4 条使用方法
  - **时辰边界 Q&A**：4 组 Q&A，含用户实际案例
    - 8:40-9:00 出生，辰时还是巳时？
    - 8:58 出生，公历填 8 还是 9？
    - 整点（如 9:00 整）归哪个时辰？
    - 出生时间不确定怎么办？
  - **历法体系区分**：农历体系 vs 节气干支历体系 + 普遍错觉成因
  - **各术数历法归属**：志极 10 个术数的历法归属表
  - **实操提醒**：5 条易错点提示
- 新增 `/manual` 路由
- 首页右上角加手册 IconButton（与设置按钮并排），通过 `SvgIcon('manual')` 加载

### 历史记录复制功能（features/history/）

- 新增 `_copyEntry(HistoryEntry e)` 方法：组装"【术数名】摘要 / 时间 / 详情 / 备注"格式
- 列表 trailing 加 IconButton(Icons.copy_all) 快速复制
- 详情对话框 actions 加"复制"按钮（在删除和保存备注之前）
- 复制完成 SnackBar 提示

## Bug 修复

### 圆角点击区域问题

- **settings_page.dart**：`_card()` Container 加 `clipBehavior: Clip.antiAlias`；ExpansionTile 的 `shape: const Border()` 改为 `RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))`；3 个 SwitchListTile 加 `shape: RoundedRectangleBorder`
- **home_page.dart**：`_guideCard()` Container 加 `clipBehavior: Clip.antiAlias`；ExpansionTile 的 shape 和 collapsedShape 改为圆角矩形
- **decorative_panel.dart**：Container 加 `clipBehavior: Clip.antiAlias`
- **history_page.dart**：ListTile 加 `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))`
- 修复后点击水波纹不再溢出圆角外，点击区域与视觉边界一致

### app_config.dart 默认值语法错误

- `defaults` 静态常量中 `xiaoliurenCinematic = true` 改为 `xiaoliurenCinematic: true`（const 表达式中应使用命名参数语法 `:`）

## 配置变更

### 默认主题模式改为「深色」

- **app_config.dart**：`themeMode` 默认值从 `ThemeMode.system` 改为 `ThemeMode.dark`
- **config_providers.dart**：`_parseThemeMode` 默认 fallback 改为 `ThemeMode.dark`，新增 `case 'system'` 显式分支
- **app.dart**：`_effectiveLight` 的 fallback 从 `ThemeMode.system` 改为 `ThemeMode.dark`
- 影响范围：仅对全新安装的用户生效；已存在的用户偏好（持久化在 SharedPreferences）不受影响

## 技术要点

- 使用手册页面采用 `_section` + `_panel` + `_qa` + `_bullet` + `_numItem` + `_calendarTable` 组合结构
- 历法归属表使用 `Table` widget + `TableBorder.all` + `FlexColumnWidth(2)` 三列等宽布局
- 圆角点击修复策略：Container `clipBehavior: Clip.antiAlias` 强制 clip + ListTile `shape: RoundedRectangleBorder` 让 InkWell 形状与外层一致
- 复制按钮 IconButton 用 `BoxConstraints(minWidth: 36, minHeight: 36)` + `padding: EdgeInsets.zero` 减小触控区，避免与 chevron_right 视觉冲突
- flutter analyze 0 issue

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|
| Android | Jeenith_1.8.0_feature_20260713_01.apk | 53.04 MB / 55618339 B | 4D3AB64D180AE83445AC31A71F4D991C5B387235D7F94F6CE8E718EFA326B81B |
| Windows x64 | Jeenith_1.8.0_feature_20260713_01_windows_x64.zip | 13.06 MB / 13694696 B | 3007DC4362AAF81C6200EC95B03929EB0EA77AE3C1CE913EB06654BEFCD1247A |

---

志极 Jeenith · 叩问本心
