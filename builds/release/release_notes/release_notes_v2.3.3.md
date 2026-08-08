# v2.3.3 — 首页按钮间距修复 + MIT LICENSE + Windows 图标产物归档

**版本**：2.3.3+23
**状态**：release
**构建日期**：2026-07-15

## 概述

v2.3.3 是志极 v2.3.x 系列的微调版本。本版本修复了首页右上角「使用手册」与「设置」两个按钮间距过近的视觉问题；正式添加项目 MIT LICENSE 并在 README 中声明开源协议；同时本次 Windows 桌面产物首次包含 v2.3.2 修复后正确嵌入的志极品牌图标（v2.3.2 仅修复 exe 但未重新打包 ZIP，正确图标实际随 v2.3.3 归档发布）。`flutter analyze` 0 issue 通过。

## 一、首页右上角按钮间距修复

### 问题

[home_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/home/home_page.dart) 首页右上角的「使用手册」与「设置」两个 [HoverableIconButton](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/shared/widgets/hoverable_icon_button.dart) 直接相邻渲染。由于 `HoverableIconButton` 本身无内置 padding，直接渲染 24px 图标，在 Row 中相邻会视觉拥挤。

### 修复

在两个按钮之间插入 `const SizedBox(width: 8)`，提供 8px 视觉间距：

```dart
HoverableIconButton(
  icon: const SvgIcon('manual'),
  tooltip: '使用手册',
  onPressed: () => _startExit(() => context.go('/manual')),
),
const SizedBox(width: 8),  // v2.3.3 新增
HoverableIconButton(
  icon: const Icon(Icons.settings_outlined),
  tooltip: '设置',
  onPressed: () => _startExit(() => context.go('/settings')),
),
```

提交：`8e90d0a` — fix: 首页右上角使用手册与设置按钮间距过近。

## 二、MIT LICENSE 添加

### 背景

志极项目此前未明确开源协议。按 `D:\Code\.Rules\OrganizationAndUser.md` 身份信息规范，组织为 Qore（叩心），项目为开源友好型卜算合集，经评估后采纳 MIT 协议（宽松、兼容性好、无 copyleft 约束）。

### 实施

1. **新建 [LICENSE](file:///d:/Code/Project/Qore/Jeenith/LICENSE)**：标准 MIT 协议文本，版权行 `Copyright (c) 2026 Qore`（按规范去除 "All rights reserved."，因 MIT 协议本身即已授予使用权）。
2. **更新 [README.md](file:///d:/Code/Project/Qore/Jeenith/README.md)**：
   - 版权行改为：`版权：Copyright (c) 2026 Qore.`
   - 新增许可证声明：`许可证：**MIT**（详见根目录 [LICENSE](LICENSE) 文件）`

提交：`d07d7bd` — docs: 添加 MIT LICENSE 并更新 README 版权说明。

## 三、Windows 桌面产物首次归档正确图标

### 背景

v2.3.2 修复了 Windows exe 默认图标问题（[release_notes_v2.3.2.md](file:///d:/Code/Project/Qore/Jeenith/builds/release_notes/release_notes_v2.3.2.md) 第三章），通过 `flutter clean` + 重构建让 CMake 重新编译 `Runner.rc` 嵌入多尺寸志极 `.ico`，并提取 exe 32x32 图标验证主色调为志极深紫（RGB ≈ 27,23,27）。但 v2.3.2 的修复 commit `b08a153` 仅重建了 exe，**未将新 exe 重新打包成 ZIP 归档**，故 v2.3.2 归档的 ZIP 仍为旧默认图标 exe。

### 本版本归档

v2.3.3 重新构建 Windows 产物（基于 v2.3.2 修复后的 `.ico` 资源），并完整打包为 ZIP 归档发布。这是首次在归档产物中包含正确嵌入志极品牌图标的 Windows exe。

### 验证

从本次构建的 exe 提取 32x32 图标，统计主色调：

```
27,23,27: 341  (#1B171B 类，志极深色背景)
28,23,28: 75
27,24,27: 71
28,23,27: 60
27,22,27: 35
```

Top 5 颜色全部为志极深紫色系，无 Flutter 蓝（#54C5F8 类），证明 exe 已正确嵌入志极品牌图标。

### 注意事项

Windows 资源管理器对 exe 图标有缓存机制。若替换 exe 后仍显示旧图标：
- 按 `Ctrl+Shift+Esc` 打开任务管理器 → 重启「Windows 资源管理器」进程
- 或清空图标缓存：`ie4uinit.exe -show`（命令行执行）

## 四、版本号更新

- pubspec.yaml：2.3.2+22 → 2.3.3+23
- 构建序号：20260715 第 01 序

## 五、自 v2.3.2 以来的提交

| Commit | 类型 | 说明 |
|--------|------|------|
| `8e90d0a` | fix | 首页右上角使用手册与设置按钮间距过近 |
| `d07d7bd` | docs | 添加 MIT LICENSE 并更新 README 版权说明 |
| `b08a153` | fix | v2.3.2 重构建 Windows 产物修复 exe 图标未应用（exe 已正确，本版本归档） |

## 六、下载

| 平台 | 文件名 | 大小 | SHA-256 |
|------|--------|------|---------|
| Android | Jeenith_2.3.3_release_20260715_01.apk | 55.00 MB / 57667575 B | E3F5E13FA6E7BFB7F3A45D31BC2DE421D32CC5379E1E777B0F440794180F625D |
| Windows x64 | Jeenith_2.3.3_release_20260715_01_windows_x64.zip | 13.27 MB / 13911748 B | FF691015789058AD59E730EB6F1338BBDEE860E6C62A5E214CEB4906C31074A8 |
