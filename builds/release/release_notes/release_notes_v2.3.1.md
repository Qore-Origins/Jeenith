# v2.3.1 — 动效体系 Phase 3-6 全面落地

**版本**：2.3.1+21
**状态**：release
**构建日期**：2026-07-15

## 概述

v2.3.1 是志极 2.x 阶段动效体系（NEXT_PLAN_v2.1.0_ANIMATION Phase 3-6）的最终落地版本。v2.3.0 计划但延后的 Phase 3 CustomPainter 绘制过程动画、Phase 4 RevealAnimation 结果揭示封装、Phase 5 剩余微交互、Phase 6 性能调优全部在本版本一次性补齐。代码层面 `flutter analyze` 0 issue 通过。

## 一、Phase 3 — CustomPainter 绘制过程动画

### 1. 紫微斗数 StarChartPainter 命盘顺时针展开

- **`progress` 参数**：[star_chart_painter.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/ziwei/ui/star_chart_painter.dart) 新增 `final double progress`（默认 1.0 向后兼容），由 `ziwei_page._chartAnim` AnimationController（1.2s）驱动。
- **三段绘制时序**：
  - 0.0 → 0.55：12 宫按命宫 → 顺时针方向逐个绘制（每宫错峰，带 scale 0.5→1.0 入场）
  - 0.55 → 1.0：星曜按主星 → 辅星顺序逐颗降落（带淡入）
  - 0.7 → 1.0：中央信息（太极圆点、命宫干支、五行局）淡入
- **辅助函数**：`_seg(start, end)` 线性映射 + clamp；`_easeOut(t)` 三次缓出。
- **shouldRepaint**：精确比较 progress 字段，避免无谓重绘。

### 2. 现有 CustomPainter 保留自带动画

- **小六壬 `divination_wheel.dart`**：StatefulWidget + Timer 三阶段动画（ignite → walk → idle），无需 Phase 3 改造。
- **周易 `hexagram_view.dart`**：StatefulWidget + Timer.periodic 逐爻揭示，无需 Phase 3 改造。
- **大六壬 `_TianPanPainter`**：纯静态绘制，包裹在 RevealAnimation 中由外层驱动揭示。

### 3. 架构发现

设计方案 NEXT_PLAN_v2.1.0_ANIMATION 中列举的"10 处 CustomPainter"实际仅 3 处存在（xiaoliuren / ziwei / zhouyi），其余 7 术（qimen / daliuren / luopan / meihua / chouqian / cezi / jiaobei）使用 Widget 布局，没有 painter 文件可改造。

## 二、Phase 4 — RevealAnimation 结果揭示封装

### 1. 统一封装组件（Phase 4.1）

[reveal_animation.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/core/animation/reveal/reveal_animation.dart) 新建：

- **三段揭示时序**：
  - `hero`：主图（卦象/大字/命盘），墨晕开（Opacity 渐入）
  - `title`：主标题（"乾为天" / "阳遁第3局" 等），打字机逐字显示
  - `sections`：段落详情，按 `sectionStagger`（默认 200ms）错峰淡入上浮
- **总时长公式**：`hero + title + sections 错峰 + 末段时长`，clamp(800, 6000) ms
- **`sectionSpacing`**：自动在段落间插入固定间距 SizedBox（不参与动画，仅做视觉分隔），默认 10.0
- **`enabled` 开关**：关闭时所有内容直接静态显示，由 `AppConfig.isAnimationEnabled(techId)` 控制
- **`onComplete` 回调**：全部揭示完成后触发

### 2. 8 术结果页接入（Phase 4.2）

| 术数 | 文件 | hero | sections |
|------|------|------|----------|
| 八字推演 | [bazi_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/bazi/ui/bazi_page.dart) | 顶部信息卡 | 四柱 / 大运 / 流年 / 神煞 / 命格批断 / 五行分析 / 劫数预警 |
| 测字 | [cezi_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/cezi/ui/cezi_page.dart) | 大字展示框 | 笔画五行 chips / 字形拆解 / 断语诗 / 解字 / 详注 |
| 测名字 | [name_test_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/name_test/ui/name_test_page.dart) | 姓名横幅 | 缺失警告 / 康熙笔画 / 五格数理 / 五行分布 / 综合批断 |
| 抽签 | [chouqian_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/chouqian/ui/chouqian_page.dart) | 等级标签 | 签题 / 签诗 / 解曰 / 详注 |
| 大六壬 | [daliuren_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/daliuren/ui/daliuren_page.dart) | 顶部信息卡 | 四课 / 三传 / 天盘加临图 / 十二天将加临 |
| 奇门遁甲 | [qimen_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/qimen/ui/qimen_page.dart) | 顶部信息卡 | 局盘九宫 / 四盘详表 |
| 掷筊 | [jiaobei_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/jiaobei/ui/jiaobei_page.dart) | 本轮卡片 | （无 sections，仅 hero 渐入） |
| 紫微斗数 | [ziwei_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/ziwei/ui/ziwei_page.dart) | 顶部信息卡 | 命盘星图（含 _chartAnim 内嵌绘制过程）/ 拖拽提示 / 宫位详情 |

### 3. 保留现状的术数

- **梅花易数 `meihua_page.dart`**：已通过 `EntranceItem` + 多 `Interval` 实现完整错峰 reveal 动画（取数 / 主卦名 / 卦象 / 体用 / 本卦辞 / 动爻辞 / 之卦辞），保留不重写以维持入场节奏。
- **小六壬 / 周易**：已有自带 reveal 动画（详见 Phase 3 部分）。

### 4. ConsumerStatefulWidget 改造

接入 RevealAnimation 的 8 个页面中 7 个由 `StatefulWidget` 改为 `ConsumerStatefulWidget`（chouqian 已是），通过 `ref.watch(configProvider).valueOrNull?.isAnimationEnabled(techId)` 读取各术动画开关，设置页切换时即时重建。

## 三、Phase 5 — 剩余微交互

### 1. InteractableCard 桌面端 hover

[interactable_card.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/shared/widgets/interactable_card.dart)：

- 桌面端（`PlatformInfo.isDesktop`）新增 `MouseRegion`，捕获 hover 事件
- hover 时卡片上浮 4px + 描边 alpha 提升至 0.8 + 阴影 blur 增至 18
- 移动端不受影响
- `cursor: SystemMouseCursors.click`（可点击时）

### 2. CopyResultButton 勾选图标切换

[copy_result_button.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/shared/widgets/copy_result_button.dart)：

- 由 `StatelessWidget` 改为 `StatefulWidget`
- 复制成功后图标从 `copy_all` 切换为 `check`（鎏金 #D4A857）
- `AnimatedSwitcher`（400ms）+ `RotationTransition`（0.5→0 turns）+ `ScaleTransition` 复合入场
- 1.6 秒后自动复位为 `copy_all`
- 文字同步切换"复制结果" ↔ "已复制"

### 3. GuideDialog 中心放大入场

[guide_dialog.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/shared/widgets/guide_dialog.dart)：

- 新增 `SingleTickerProviderStateMixin` + `AnimationController _enter`（280ms）
- 背景模糊渐入：`BackdropFilter` + `ImageFilter.blur(sigmaX/Y: 5 * blurT)`
- 背景暗化渐入：`Colors.black.withValues(alpha: 0.4 * blurT)`
- 卡片中心放大：`Transform.scale(0.85 → 1.0)`，配合 `Curves.easeOutBack` 弹回
- 与原 3 秒倒计时机制无缝衔接

### 4. HoverableIconButton 组件（新增）

[hoverable_icon_button.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/shared/widgets/hoverable_icon_button.dart)：

- 桌面端 hover：图标旋转 5°（0.0872 rad）+ 颜色变鎏金（200ms）
- 按下：scale 0.9 + 反弹（150ms）
- 关闭时颜色恢复基础色
- 通过 `AnimatedRotation` + `AnimatedScale` + `AnimatedDefaultTextStyle` + `IconTheme` 嵌套实现
- 避免 `Matrix4.scale` 弃用警告

### 5. 首页 IconButton 替换

[home_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/home/home_page.dart)：

- 历史记录 / 使用手册 / 设置 3 处 `IconButton` 替换为 `HoverableIconButton`
- 桌面端鼠标移过有微旋转 + 鎏金高亮反馈
- 移动端保持原有点击行为

## 四、Phase 6 — 性能调优

### 1. RepaintBoundary 隔离

- `ziwei_page._buildResult`：CustomPaint 外层套 `RepaintBoundary`，避免外层 RevealAnimation rebuild 时重绘命盘
- 已有的 8 术结果区 RepaintBoundary（包裹整个结果区，用于 ShareResultButton 截图）保留不变

### 2. shouldRepaint 精确控制

- `StarChartPainter.shouldRepaint` 新增 `progress` 字段比较
- 仅在命宫 / 身宫 / 干支 / 五行局 / 星盘数据 / progress 任一变化时重绘
- `_TianPanPainter`、`_SticksPainter`、`_HexagramView` 等已有 shouldRepaint 保留

### 3. flutter analyze 验证

- 全项目 `flutter analyze` **0 issue**（无警告、无错误）

## 五、Bug 修复

### 1. 小六壬"起卦"按钮在 Row 中坍塌为竖线

- **现象**：[xiaoliuren_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/xiaoliuren/ui/xiaoliuren_page.dart) 中"起卦"按钮渲染成"一小条竖线"，按钮文本不可见。
- **根因**：GoldButton 内部 build 链路 `GestureDetector → AnimatedBuilder → Transform.scale → DecoratedBox → Padding → Text` 中的 `Transform.scale` 阻断 intrinsic width 传递；Row 中无 Expanded 包裹的 GoldButton 无法被测量出宽度，被分配 0 宽度。zhouyi 的"摇卦"按钮用 `Expanded` 包裹不受影响。
- **修复**：[xiaoliuren_page.dart#L327](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/xiaoliuren/ui/xiaoliuren_page.dart#L327) `_buildInputRow` 中给 `GoldButton` 包 `SizedBox(width: 88)`，给按钮一个明确的 layout 宽度（"起卦"2 字 + horizontal padding 44 ≈ 74px，预留 14px 余量）。
- **遗留**：v2.3.0 release_notes 中"周易起卦按钮消失（联动排查小六壬）"条目实际只调整了 `_buildResultSliver` 的 bottom padding 28 → 96，并未根治按钮显示问题。v2.3.1 此处为真正修复。

### 2. GoldButton 快速点击丢失 onPressed

- **现象**：用户反馈"按钮按下之后并没有先缩小 0.95 再放大回去，但是如果多按一会就有这个效果"——快速点击时按钮物理反馈动画时序错乱，前几次点击的 `onPressed` 不触发。
- **根因**：[gold_button.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/shared/widgets/gold_button.dart) 旧实现 `_onTapUp` 用 `_press.reverse().then((_) { widget.onPressed?.call(); })` 等 260ms 弹回动画完成才回调 onPressed。快速点击松手时，下一次 `_onTapDown` 的 `forward()` 会中断进行中的 `reverse()`，导致 `.then(...)` Future 被 cancel，**onPressed 永远不会触发**。状态机错乱后用户多按几次会偶然命中"reverse 完成"窗口，才看到完整动画。
- **修复**：`_onTapUp` 改为立即触发 onPressed，弹回动画与功能执行并行：
  ```dart
  setState(() => _down = false);
  _press.reverse();
  widget.onPressed?.call();
  ```
  视觉缩放仍由 `_press` controller 驱动，体验与原设计一致；功能响应即时可靠。

## 六、版本号更新

- [pubspec.yaml](file:///d:/Code/Project/Qore/Jeenith/mobile/pubspec.yaml)：2.3.0+20 → 2.3.1+21

## 七、技术要点

- **不引入新依赖**：RevealAnimation 完全基于 Flutter Material + dart:ui 自实现
- **AppConfig Map 改造兼容**：所有 RevealAnimation 接入页面通过 `isAnimationEnabled(techId)` 查询，未在 Map 中记录时默认 true（向前兼容）
- **CustomPainter dispose 链路**：紫微 `StarChartPainter` 的 TextPainter 显式 dispose 链路保留，无 native handle 泄漏
- **oklch 配色**：所有新增 UI 沿用 `AppColors` 黑金低饱和度规范
- **桌面端 / 移动端差异化**：InteractableCard hover 与 HoverableIconButton 仅桌面端生效，移动端不引入鼠标交互副作用

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.3.1_release_20260715_01.apk | 54.98 MB / 57651191 B | C5DF5EBD4988BC37EDA91FE6C4FFDC7FFE236C8B8699D0902400DC03A11A506F |
| Windows x64 | Jeenith_2.3.1_release_20260715_01_windows_x64.zip | 13.30 MB / 13945376 B | 7AB41E9BA8CEA4F91DD3C2E3F21599F557EDB5E91751E9AEC7FA423B3A24B698 |

---

志极 Jeenith · 叩问本心
