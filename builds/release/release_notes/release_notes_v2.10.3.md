# v2.10.3 — GoldButton 竖线坍塌第五次根治 + 周易 ActionBar 单行自适应

## 概述

v2.10.2 发布后用户反馈：周易卜算页面的「起卦」按钮在 320-411px 小屏手机上仍坍塌为一条金线。这是该 BUG 的**第 5 次复发**（v2.3.1 / v2.7.1 / v2.10.0 / v2.10.1 / v2.10.3）。v2.10.1 的 `ConstrainedBox(minWidth:88)` 单层方案虽防护了 loose / unbounded 场景，却遗漏了 **tight(W<88) 矛盾约束场景**：父级 Expanded 在窄屏给 GoldButton 传 tight(width<88) 约束时，`ConstrainedBox.enforce` 把 child 撑到 88 但 size 被父级 clamp 回 0，造成 size=0 / child=88 的撕裂，release 模式渲染降级为竖线。

本版本采用**双层修复**（布局层 + 防御层），并在此过程中修复了一个新引入的嵌套 viewport 崩溃，最终落地为「单行 + FittedBox 自适应」方案。

## 修复内容

### 1. 周易 ActionBar 单行自适应布局

**问题**：原 `_buildActionBar` 用 `Expanded(child: GoldButton(...))` 单行排布 4 个按钮（摇卦 / 重置 / 复制 / 分享）。4 按钮非弹性子节点 minWidth 之和约 404px，在 320px 屏（可用 288px）、360px 屏（328px）、411px 屏（379px）均超出可用宽度，Expanded 给 GoldButton 的 width < 88 触发矛盾约束。

**修复**：弃用 `Expanded(GoldButton)`，4 按钮按 intrinsic 宽度并排（`Row(mainAxisSize: min)`），外层 `Center + FittedBox(fit: scaleDown, alignment: center)`：

- **大屏（≥480px）**：4 按钮 intrinsic 总宽 < 可用宽，原尺寸居中，左右留白
- **小屏（<480px）**：4 按钮 intrinsic 总宽 > 可用宽，整体等比缩小到一行容纳，无溢出

同步 `_PinHeaderDelegate` extent 90 → 104 → 90（最终单行），与 `Container minHeight: 90` 一致。

**影响文件**：`mobile/lib/features/zhouyi/ui/zhouyi_page.dart`

### 2. GoldButton 矛盾约束防御层（第五次根治核心）

**问题**：v2.10.1 的 `ConstrainedBox(minWidth:88)` 单层结构在 tight(W<88) 矛盾约束下反而加剧坍塌——`enforce` 把 child 撑到 88，但 ConstrainedBox.size 被 parent maxWidth<88 clamp 回 0（甚至 0），造成 size=0 / child=88 的 painting 与 layout 撕裂。

**修复**：GoldButton 内部 `expandedBox` 加 `LayoutBuilder` 防御层，检测 tight(maxWidth<88) 矛盾约束：

```dart
final expandedBox = LayoutBuilder(
  builder: (context, constraints) {
    final isContradiction = constraints.maxWidth.isFinite &&
        constraints.maxWidth < 88 &&
        constraints.minWidth == constraints.maxWidth; // tight 约束
    if (isContradiction) {
      return box; // 降级：放弃 minWidth:88 强制，按可用宽度渲染
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 88),
      child: box,
    );
  },
);
```

矛盾时放弃 minWidth:88 强制，直接按可用宽度渲染 box——按钮文字可能裁剪，但按钮本体可见可点击，不再坍塌为竖线。仅矛盾约束触发，其他 14 个 GoldButton 调用点行为不变（tight≥88 / loose / unbounded 均走原 ConstrainedBox 分支）。

**影响文件**：`mobile/lib/shared/widgets/gold_button.dart`

### 3. 嵌套 viewport 崩溃修复

**问题**：实施过程中曾尝试用 `SingleChildScrollView(horizontal)` 横向滚动方案。`SingleChildScrollView` 内部是 `_RenderSingleChildViewport`，嵌在 `pinned SliverPersistentHeader` 内导致 hit test 时外层 viewport 取 `sliver.geometry` 为 null，抛 `Null check operator used on a null value`（viewport.dart:886），周易页面点击即崩。

**修复**：去掉 `SingleChildScrollView`，改用 `FittedBox(scaleDown)`（`RenderFittedBox`，proxy box，非 viewport），不破坏 sliver geometry 链。

**影响文件**：`mobile/lib/features/zhouyi/ui/zhouyi_page.dart`

## 方案演进（同日三次迭代）

1. **两行布局**（extent=104）：Row1=摇卦+重置，Row2=复制+分享。用户反馈「按钮太宽」
2. **单行 + 横向滚动**（`SingleChildScrollView` + `IntrinsicWidth`，extent=90）：引发嵌套 viewport 崩溃
3. **单行 + FittedBox(scaleDown)**（最终）：无嵌套 viewport、无溢出、无空指针，大小屏均正常

## 验证

- `flutter analyze`：No issues found (4.3s)
- 周易 _buildActionBar：4 按钮单行居中，大屏原尺寸、小屏等比缩放，不再坍塌、不再崩溃
- GoldButton 防御层：LayoutBuilder 矛盾检测仅 tight(W<88) 时触发，其他 14 个调用点行为不变
- DarkButton：未动，v2.10.2 AnimatedSwitcher 文字过渡动画完整保留

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.10.3_fix_20260722_01.apk | 58.84 MB | `8DBA3F53C4F39340DE8143ADE6095660212734905C130DD7B045F50B1DA2C417` |
| Windows x64 | Jeenith_2.10.3_fix_20260722_01_windows_x64.zip | 15.66 MB | `93F5CA62B6D489DDD658281A9B8DD3870CE1DECF944BE45E6AB75E3AE5A14C51` |

## 版本信息

- **版本号**：2.10.3+43
- **构建状态**：fix（修复版）
- **构建日期**：2026-07-22
- **频发 BUG 文档**：`docs/频发BUG/GoldButton竖线坍塌.md`（复用次数 5）
