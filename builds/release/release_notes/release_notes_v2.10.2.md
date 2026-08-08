# v2.10.2 — 合并 v2.10.1 修复 + InteractableCard 崩溃修复 + 文字过渡动画

## 概述

v2.10.2 是 v2.10.0 的修复版本，合并了 v2.10.1（未单独发布）和 v2.10.2 的全部修复与改进。v2.10.0 发布后暴露两个问题：按钮双层嵌套导致周易所有按钮消失、首页 InteractableCard 偶发断言崩溃。本版本一并修复，并新增复制结果按钮的文字过渡动画。

## 关于 v2.10.1 未单独发布

v2.10.0 发布后用户反馈：周易卜算页面所有按钮消失、小六壬 DarkButton 失去宽度约束。根因是 v2.10.0 引入的 `ConstrainedBox(minWidth:88, maxWidth:inf) + SizedBox(width:inf)` 双层嵌套在 loose 约束场景下反向放大了竖线坍塌 BUG——内层 SizedBox.size=inf，外层 ConstrainedBox.size=clamp(inf,0,W)=W，强制撑满 Row 剩余宽度，后续按钮无空间。

v2.10.1（commit `028fc60`）修复了此问题，简化为 `ConstrainedBox(minWidth:88/72)` 单层结构。但修复后立即发现首页 InteractableCard 偶发 `'begin <= 1.0'` 断言崩溃（Interval.begin 越界）。为避免连续发布两个修复版本，v2.10.1 未单独构建发布，其修复内容合并入 v2.10.2 一并发布。

## 修复内容

### 1. GoldButton/DarkButton 竖线坍塌第四次根治（原 v2.10.1）

**问题**：v2.10.0 的双层嵌套约束在 loose(maxWidth=W) 下让按钮撑满整个 Row，导致周易所有按钮消失、小六壬 DarkButton 失去宽度约束。

**修复**：简化为 `ConstrainedBox(constraints: BoxConstraints(minWidth: 88/72), child: box)` 单层结构，去掉 `maxWidth: double.infinity` 和 `SizedBox(width: double.infinity)`。

**三场景验证**：
- tight(W) 下：撑满 W（Expanded / SizedBox(width:88) 包裹）
- loose(maxWidth=W) 下：minWidth 兜底，按 intrinsic 测量（Wrap / Row 非 Expanded 子节点）
- loose unbounded(maxWidth=inf) 下：minWidth 兜底，不再坍塌为竖线（SliverPersistentHeader）

**影响文件**：`mobile/lib/shared/widgets/gold_button.dart`、`mobile/lib/shared/widgets/dark_button.dart`

### 2. InteractableCard 崩溃修复（v2.10.2）

**问题**：首页 techs 卡片入场动画 `Interval(0.28 + i*0.08, ...)` 的 `begin` 没有 clamp。当前项目 12+ 卜算术，`i` 可达 11+，`begin = 0.28 + 11*0.08 = 1.16 > 1.0`，触发 `Interval.transformInternal` 的 `'begin <= 1.0'` 断言崩溃。偶发是因为仅 `i >= 10` 的卡片越界。

**修复**：begin 增加 `.clamp(0.0, 0.92)`，与 end 的 `.clamp(0.0, 1.0)` 配合，确保 end - begin >= 0.08 避免除零。

**影响文件**：`mobile/lib/features/home/home_page.dart`

### 3. DarkButton 文字过渡动画（v2.10.2）

**改进**：DarkButton 内部 label 用 `AnimatedSwitcher`（`key: ValueKey(widget.text)`）包裹，text 变化时自动播放淡入 + 上滑过渡（250ms）。

**效果**：CopyResultButton 点击复制后，图标已有旋转 + 缩放动画（400ms），文字"复制结果"→"已复制"同步淡入 + 上滑（250ms），两者呼应。text 不变时（如"重置"按钮）AnimatedSwitcher 不触发动画，无副作用。

**设计决策**：不受 `AppConfig.animationsEnabled` 控制（与图标动画一致），属 UI 操作反馈而非装饰性动画。

**影响文件**：`mobile/lib/shared/widgets/dark_button.dart`

## 验证

- `flutter analyze`：No issues found (22.3s)
- 周易 _buildActionBar：GoldButton 用 Expanded 包裹（tight）撑满；DarkButton/Copy/Share 在 Row 中按 intrinsic 宽度
- 小六壬 _buildActionBar：GoldButton 用 SizedBox(width:88) 包裹（tight(88)）撑满；DarkButton 在 Wrap 中保持 intrinsic 宽度
- 首页 InteractableCard：12+ 卡片入场动画不再崩溃

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.10.2_fix_20260721_01.apk | 58.84 MB | `8A971AF9E5F172EC69ADECB947C519CD29E768BEB14A4802647523F902D3175C` |
| Windows x64 | Jeenith_2.10.2_fix_20260721_01_windows_x64.zip | 15.66 MB | `BEE2CB6683031617191D28CA73CC11E4F4A3389C97D3DF7E867E7FF289424F60` |

## 版本信息

- **版本号**：2.10.2+42
- **构建状态**：fix（修复版）
- **构建日期**：2026-07-21
- **包含 commit**：`028fc60`（v2.10.1 按钮修复）+ `1335f95`（v2.10.2 崩溃修复 + 文字动画）
