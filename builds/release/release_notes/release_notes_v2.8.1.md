# v2.8.1 — 修复周易/小六壬桌面端 pinned header 崩溃

**版本**：2.8.1+35
**状态**：fix
**构建日期**：2026-07-19

## 概述

v2.8.1 修复 v2.8.0 暴露的桌面端崩溃：周易、小六壬页面 `SliverPersistentHeader` 的 delegate extent 与 ActionBar child 高度不匹配，产生 `paintExtent < layoutExtent` 异常 geometry，致后续 sliver 不被 layout、viewport paint 时空指针循环崩溃。`flutter analyze` 0 issue。

## BUG 修复

### 周易/小六壬桌面端 pinned header 崩溃（根治）

- **现象**：桌面端进入周易/小六壬页面，`Null check operator used on a null value` 循环报错，页面无法渲染。
- **根因**：`_PinHeaderDelegate` 的 `extent` 与 `_buildActionBar` 的 `minHeight` 不一致——
  - 周易：extent 90 vs child minHeight 80
  - 小六壬：extent 200 vs child minHeight 150

  child 实际高度 < extent，产生 `SliverGeometry(paintExtent < layoutExtent)` 异常，后续 result sliver 不被 layout（geometry null），viewport `_paintContents` 执行 `child.geometry!` 空指针。桌面端 `CustomScrollView` 触发（移动端 `DraggableScrollableSheet` 的 viewport 实现不同，未触发，故此前未暴露）。
- **修复**：ActionBar `minHeight` 对齐 delegate extent（周易 80→90，小六壬 150→200），消除异常 geometry。两术移动端/桌面端一并修好。
- **溯源**：周易这条由 v2.7.1 引入（ActionBar 去 `Container(alignment)` 改 `Row.crossAxisAlignment` 后，Row 自然高度掉到 80 < extent 90）；小六壬为同模式潜在 bug。

## 版本号

- [pubspec.yaml](file:///d:/Code/Project/Qore/Jeenith/mobile/pubspec.yaml)：2.8.0+34 → 2.8.1+35

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.8.1_fix_20260719_01.apk | 58.81 MB / 61669450 B | E75A63ED592A6392088491716CA67BFFCF728A33D540FF968EF0092756680DB1 |
| Windows x64 | Jeenith_2.8.1_fix_20260719_01_windows_x64.zip | 15.65 MB / 16413722 B | 2EAFD245A64884FA6F99C92FE1377A6C08519A6ABC42E56D2AE60A92F0FA9013 |

---

志极 Jeenith · 叩问本心
