# v2.7.1 — GoldButton 根治竖线坍塌 + 按压缩放延迟

**版本**：2.7.1+32
**状态**：fix
**构建日期**：2026-07-19

## 概述

v2.7.1 修复周易摇卦按钮的两个长期 BUG（v2.3.1 已知但仅修小六壬、周易遗漏）。修复点在共享组件 [GoldButton](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/shared/widgets/gold_button.dart)，一次性根治所有术的鎏金按钮。`flutter analyze` 0 issue。

## BUG 修复

### 1. 按钮坍塌为竖线（根治）
- **现象**：周易摇卦按钮不显示，只剩一小条竖线。
- **根因**：GoldButton 内部 `Transform.scale` 不报告 intrinsic 宽度，在 `Row/Expanded` 中被测量为 0 宽。v2.3.1 仅给小六壬外层套 `SizedBox(width:88)` 规避，周易未修。
- **根治**：box 内层加 `SizedBox(width: double.infinity)`，在 tight 宽度环境（Column stretch / Expanded / SizedBox 固定宽）下撑满，覆盖所有用法。

### 2. 按压缩放延迟（根治）
- **现象**：按下按钮没有立即缩小 0.95 再弹回，要多按一会（长按）才出现缩放。
- **根因**：`onTapDown` 参与 gesture arena，在 `DraggableScrollableSheet` 等滚动容器内被 tap-vs-scroll 竞争延迟识别。
- **根治**：改用 `Listener(onPointerDown/onPointerUp)` 立即驱动缩放（pointer 事件不参与 arena），`GestureDetector.onTap` 处理功能触发。

### 3. 周易 ActionBar 布局加固
- 去掉 `Container(alignment: Alignment.center)`（Align 会给 child loose 宽度约束，致 Row 中 Expanded 异常），改用 `Row(crossAxisAlignment: center)` 在 tight 高度内垂直居中。

## 版本号

- [pubspec.yaml](file:///d:/Code/Project/Qore/Jeenith/mobile/pubspec.yaml)：2.7.0+31 → 2.7.1+32

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.7.1_fix_20260719_01.apk | 58.64 MB / 61489230 B | 494941135F2DCBA167AC2E484EEE98FAEC01E9372507BA7A0695F3A61C10C822 |
| Windows x64 | Jeenith_2.7.1_fix_20260719_01_windows_x64.zip | 15.63 MB / 16393776 B | 8D0844BB389C2D85882121E4E7A6F5A0359774CC15ABB9B1D16C49B9700FBC16 |

---

志极 Jeenith · 叩问本心
