# v2.0.0 — 体验深化与品牌定调（按钮/图标微交互升级）

**版本**：2.0.0+16
**状态**：release（major upgrade）
**构建日期**：2026-07-14

## 概述

v2.0.0 是志极的「体验深化与品牌定调」版本——从 1.x 的"功能堆叠"阶段转向 2.x 的"交互体验与极致细节"阶段。本版本聚焦按钮、图标的物理反馈与微交互升级，并加入全局动效开关让用户可控。

## 新增功能

### 1. 按钮物理反馈与样式重写

- `GoldButton` / `DarkButton` 升级为 `ConsumerStatefulWidget`，内部用 `AnimationController` + `GestureDetector` 实现按动反馈：
  - **按动瞬间**：缩小至 0.95 倍，阴影偏移降低（blurRadius 10 → 6，offset 4 → 2），曲线 `Curves.easeIn`
  - **抬起瞬间**：用 `Cubic(0.34, 1.56, 0.64, 1)`（`easeOutBack` 变体）弹回 1.0 倍，阴影回归，时长 260ms
  - **质感来自曲线而非饱和度**：配色保持黑金低饱和度，不引入光污染
- 配色遵循 oklch 思路（黑金低饱和度）
- 移除原生 `MaterialButton` 默认水波纹
- 内部自动读 `AppConfig.animationsEnabled`，开关关闭时降级为静态按钮

### 2. 图标状态切换动画（AnimatedExpandIcon）

- 新增 `shared/widgets/animated_expand_icon.dart`
- 底层 `AnimatedRotation`：0° → 90°（可配置 `expandedAngle`）
- 点击瞬间 `AnimatedScale` 呼吸反馈：1.0 → 0.86 → 1.0
- 曲线 `Curves.easeOutCubic`，时长 240ms
- 用于首页「使用方法」卡片的展开/收起，替换默认 chevron

### 3. 全局动效常量封装

- 新增 `core/theme/animations.dart`：
  - 集中定义所有时长（pressDown/pressRelease/iconRotate/iconScale/cardStagger/cardRise/panelExpand）
  - 集中定义所有曲线（pressDownCurve/pressReleaseCurve/iconRotateCurve/cardRiseCurve/panelExpandCurve）
  - 提供 `staggeredIntervals(count)` 帮助函数生成错峰 Interval 数组
- 统一所有微交互的视觉节奏，避免散落硬编码

### 4. 全局动效总开关

- `AppConfig` 新增 `animationsEnabled` 字段（默认 true）
- `ConfigNotifier` 新增 `setAnimationsEnabled` 方法，持久化到 `SharedPreferences`
- 设置页新增「动效」section + 「启用微交互动效」SwitchListTile
- 关闭后所有 `GoldButton` / `DarkButton` / `AnimatedExpandIcon` 降级为静态组件，不影响核心功能

### 5. 首页「使用方法」卡片升级

- `ExpansionTile` 用 `ExpansibleController` 外部控制
- trailing 用 `AnimatedExpandIcon` 替换默认 chevron，带呼吸反馈
- 状态颜色：展开时 gold，收起时 textSubtitle
- 通过 `onExpansionChanged` 同步状态

## 技术要点

- **不引入新依赖**：选择自定义动画而非 `flutter_animate` 等第三方库，与现有 `InteractableCard` 风格一致，避免 APK 体积膨胀
- **按钮内部读 config**：`GoldButton` / `DarkButton` 改为 `ConsumerStatefulWidget`，调用方零改动即可响应开关
- **`AnimatedExpandIcon` 留参数**：`animationsEnabled` 仍可显式传入（如非 Riverpod 上下文）
- **`ExpansibleController` 替代废弃的 `ExpansionTileController`**：Flutter 3.31+ 推荐
- **所有 AnimationController 显式 dispose**：`_press` / `_breath` 在 State.dispose 中释放，无内存泄漏
- **flutter analyze 0 issue**
- **TextPainter dispose 链路审计**：项目中 10 处 TextPainter 全部正确 dispose（chouqian/luopan×2/daliuren×3/ziwei/xiaoliuren×2/zhouyi），无内存泄漏

## 验收标准对照

| 标准 | 状态 |
|------|------|
| 点击按钮、折叠/展开列表，所有动作反馈都"丝滑、有质感" | ✓ 按钮按动 0.95 缩放 + easeOutBack 弹回 |
| 动效符合禅意、黑金配色，没有高饱和光污染 | ✓ 配色沿用 AppColors 黑金低饱和度 |
| 所有动画可以通过设置页全局控制开关 | ✓ 「启用微交互动效」SwitchListTile |
| 关闭后不影响任何核心功能使用 | ✓ 按钮降级为静态，仅响应点击 |
| `flutter analyze` 为 0 issue | ✓ |
| 无内存溢出 | ✓ TextPainter/AnimationController 全部 dispose |

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|
| Android | Jeenith_2.0.0_release_20260714_01.apk | 53.06 MB / 55634715 B | 9E60148F51876CAF35CFC9D04FFE4075265E1FE56FDB502BE75F415413D58095 |
| Windows x64 | Jeenith_2.0.0_release_20260714_01_windows_x64.zip | 21.00 MB / 22017518 B | 4D8EAA6204C008D1BB046574FC9C07464B158510BDDC9DFD5066C606D15158D |

## 后续阶段预告

- v2.1.0：周易/梅花卦辞爻辞内容深化
- v2.2.0：紫微斗数 v2 算法精细化
- v2.3.0：结果分享增强 + 历史导出 JSON

---

志极 Jeenith · 叩问本心
