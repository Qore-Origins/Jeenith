# v2.3.0 — 新增八字推演与测名字，紫微命盘重构，设置页动画 Map 化

**版本**：2.3.0+20
**状态**：feature
**构建日期**：2026-07-14

## 概述

v2.3.0 是志极 2.x 阶段的首个"功能扩展 + 体验重塑"双轮迭代版本。本次迭代落地 9 项任务：修复 v1.5.0 起卦按钮被 `RepaintBoundary` 顶出可视区的 Bug；新增两大术数（八字推演、测名字）；重构紫微斗数命盘（径向排版 + 手动旋转 + 惯性减速）；将设置页分散的动画开关收敛为 `Map<String, bool> animationSettings`，并提供"一键全控"按钮；全局消灭 `Curves.linear`，统一为 `easeInOutCubic` / `easeOutCubic` / `easeOutBack`。

## 新增功能

### 1. 八字推演（features/bazi/，sortOrder=10）

- **生辰输入 UI**：复用紫微/奇门表单风格，**时辰字段为可选**——留空时算法自动跳过时柱与大运推演，UI 显式提示用户「若时辰未知，可不填写」。
- **核心算法**：基于 `lunar ^1.7.8`（寿星天文历）精确排盘
  - 年柱以**立春**为分界（非农历正月初一）
  - 月柱以**节气**为分界
  - 日柱、时柱按干支纪法
  - 大运顺逆排盘（阳男阴女顺排、阴男阳女逆排），起运天数精确到天
  - 流年按当前时间反查
- **神煞**：复用项目已有的华盖、太极贵人、文昌等 8 项查表逻辑，输出先天命格与劫数预警

### 2. 测名字 · 五格剖象（features/name_test/，sortOrder=11）

- **输入 UI**：中心化输入框，支持 2-3 字中文姓名
- **核心算法**：实现**五格剖象法**
  - 天格 / 人格 / 地格 / 总格 / 外格 五格计算
  - 基于**康熙字典笔画**（内置 490 字笔画表 `strokes_data.dart`）
  - 81 数理吉凶判定表
  - 输出五行生克关系与综合批断

### 3. 紫微斗数视觉重构

- **径向排版**：`StarChartPainter` 中重写 12 宫文字绘制，利用 `canvas.translate` + `canvas.rotate(centerAngle - π/2)`，让文字中心点对齐宫位扇区平分线，**文字头部（地支名）朝向圆心，尾部朝外**。
- **手动旋转**：`ziwei_page.dart` 引入 `double _rotationAngle` 状态，`GestureDetector` 包裹 `Transform.rotate` + `CustomPaint`，`_onPanUpdate` 计算拖拽角度增量并 `setState` 重绘。
- **惯性减速**：手指离开屏幕后，`FrictionSimulation(drag=0.45, angle, angularVelocity)` + `AnimationController` 让命盘继续旋转并自然减速停止，提升丝滑感。
- **防溢出**：`CustomPaint` 外层套 `ClipRect`，旋转时溢出文字被平滑裁切。

### 4. 设置页「动画/动效」分区重构

- **数据结构**：`AppConfig` 中移除 5 个分散 bool（`ritualAnimationsEnabled` / `painterAnimationsEnabled` / `revealAnimationsEnabled` / `transitionsEnabled` / `xiaoliurenCinematic`），合并为 `Map<String, bool> animationSettings`（Key 为各术 id）。
- **统一查询**：新增 `AppConfig.isAnimationEnabled(techId)` 方法，未在 Map 中记录时默认 true。
- **UI 整合**：原分散的「◆ 动效」与「◆ 动画设置」分区合并为单一「◆ 动画/动效」分区。
- **一键全控**：分区顶部放置「开启所有分类」与「关闭所有分类」两枚 OutlinedButton，点击后遍历 Map 批量置 true/false。
- **分类展开**：使用 `ExpansionTile` 按术数列出，每术一个开关（"开启此术动画"），写入 Map 并持久化到 `SharedPreferences`（前缀 `anim_<techId>`）。
- **微交互总开关**：保留 `animationsEnabled` 作为按钮缩放/图标旋转等全局微交互的总开关。

## Bug 修复

### 周易起卦按钮消失（联动排查小六壬）

- **根因**：v1.5.0 引入的 `RepaintBoundary` 包裹范围过大，把 Sliver 布局底部的起卦按钮和输入区一并包入，导致被顶出屏幕。
- **修复**：[zhouyi_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/zhouyi/ui/zhouyi_page.dart) 中 `_buildResultSliver()` 底部 padding 28 → 96，并添加注释明确 `RepaintBoundary` **仅包裹卦象展示结果区**。
- **联动**：[xiaoliuren_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/xiaoliuren/ui/xiaoliuren_page.dart) 同样 padding 调整 + 注释，防止同类隐藏问题。

## 全局优化

### 动画曲线审计（消灭生硬感）

- 全局搜索 `Curves.linear`，[typewriter_text.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/core/animation/reveal/typewriter_text.dart) 中打字机字符计数从 `StepTween` 改为 `CurvedAnimation(curve: Curves.easeOutCubic)`。
- 所有微交互（卡片上浮、列表展开、按钮抬起）已统一为 `easeInOutCubic` / `easeOutCubic` / `easeOutBack`，符合志极禅意质感。

### 路由层动画判定

- `home_page._onTapTech` 与 `app_router.dart` 统一改读 `isAnimationEnabled(id)`，决定走 `/ritual/<id>` 还是 `/tech/<id>`。
- `_ritualTechs` Set 显式列出 10 个有仪式动画的术，防止新增 bazi / name_test 误走不存在的 `/ritual/bazi` 路由。

## 技术要点

- **不引入新依赖**：八字与测名字算法完全自实现 + lunar 库已有依赖；五格笔画表内嵌常量。
- **AppConfig 兼容**：旧 `SharedPreferences` 中遗留的 5 个 sub-switch key 不会被读取，但也不会被删除（避免破坏现有用户数据）；新增 `anim_<techId>` 前缀独立存储。
- **CustomPainter dispose 链路**：紫微 `StarChartPainter` 的 TextPainter 显式 dispose 链路保留，无 native handle 泄漏。
- **oklch 配色**：所有新增 UI 沿用 `AppColors` 黑金低饱和度规范，无光污染。
- **flutter analyze 0 issue**：全项目无警告、无错误。

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.3.0_feature_20260715_01.apk | 54.89 MB | 394A39102CDF00ED00B6B361A2E8AB2FA9B01519FFE3668B12FA6F2BC641C7A8 |
| Windows x64 | Jeenith_2.3.0_feature_20260715_01_windows_x64.zip | 13.29 MB | 1BF39245A3A5CC607CEB22DBBB913F033395B5D59DA28B609D0B80CCC9FE376C |

## 后续阶段预告

- ~~v2.3.x：Phase 3 CustomPainter 绘制过程动画~~ → 已在 v2.3.1 实施（紫微 StarChartPainter progress 参数驱动命盘顺时针展开；xiaoliuren/zhouyi 已有自带动画；其余 7 术使用 Widget 布局无 painter）
- ~~v2.4.0：Phase 4.1-4.2 RevealAnimation 结果揭示封装 + 10 术结果页接入~~ → 已在 v2.3.1 实施（RevealAnimation 统一封装 + bazi/cezi/chouqian/daliuren/jiaobei/name_test/qimen/ziwei 全 8 术接入；meihua 保留 EntranceItem 自带动画）
- ~~v2.4.x：Phase 5 剩余微交互 + Phase 6 性能优化~~ → 已在 v2.3.1 实施（InteractableCard 桌面 hover / CopyResultButton 勾选切换 / GuideDialog 中心放大入场 / HoverableIconButton 组件 / 首页 IconButton 替换 / RepaintBoundary 全量审计 / flutter analyze 0 issue）

---

志极 Jeenith · 叩问本心
