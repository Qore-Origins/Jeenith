# v2.2.0 — 动效体系 Phase 2b + Phase 4.3 + Phase 5.1（仪式动画补全 + 路由转场差异化）

**版本**：2.2.0+18
**状态**：feature
**构建日期**：2026-07-14

## 概述

v2.2.0 承接 v2.1.0 的动效体系，落地设计方案的 Phase 2b（后 4 套仪式动画）+ Phase 4.3（路由转场差异化）+ Phase 5.1（DivinationLoadingIndicator）。

10 术全部具备仪式入场动画（v2.1.0 完成 5 套 + 小六壬，本次补全剩余 4 套）；每术路由转场有专属视觉语言；加载指示器全面中国风化。

## 新增功能

### Phase 2b：后 4 套仪式动画

#### 梅花数字撞击（4s）
- 5 阶段：环境金光渐显 + 两数字飘落 → 撞击爆发（16 颗金光粒子） → 数字消散成五行色光 + 卦象淡入 → 动爻从顶降临 → 金色描边
- 复用 `features/meihua/algorithm/divine.dart` 的算法（先天八卦序 + 动爻计算）

#### 掷筊翻转落地（3s）
- 4 阶段：黑底渐显 → 杯筊抛物线下落 + 翻滚 2 周 → 落地弹跳 + squash 形变 → 结果定型（圣/笑/阴筊光晕）
- 新月形杯筊用 `Path.quadraticBezierTo` 构成，旋转 π 翻转方向

#### 抽签卷轴展开（5s）
- 5 阶段：签筒摇晃 ±15° sin 波 → 签条跳出（弧形轨迹） → 卷轴展开（width 动画） → 签诗逐行毛笔书写（clipRect 左→右） → 金光描边
- 卷轴纸面用米黄 `Color(0xFFE8D9B8)`，避免光污染

#### 测字字形浮现 + 五行色染（5s）
- 4 阶段：虚空粒子背景 → 「道」字浮现（easeOutBack 回弹） → 木行色（#6BAB6B）从字中心向外扩散染色 → 金色描边圆环描绘
- 染色机制：`TextStyle(foreground: Paint()..shader = RadialGradient)`
- 演示字固定为「道」，与项目「志极 Jeenith」志/道主题呼应

### Phase 4.3：路由转场差异化

- `TechTransition.build(key, child, techId, transitionsEnabled)` 工厂方法
- 10 术专属转场（switch by id）：
  - **小六壬**：太极旋入（scale 0.5 + rotate 90°）
  - **周易**：爻堆叠（slide up + scale Y）
  - **梅花**：数字合体（slide from left + easeOutBack）
  - **掷筊**：抛物线（slide from top）
  - **紫微**：辐射（scale 0.5 + rotate -30°）
  - **奇门**：九宫分块（scale 0.8 + slight rotation）
  - **抽签**：卷轴展开（slide up + easeInOutCubic）
  - **测字**：字符浮现（scale 0.6 + easeOutBack）
  - **大六壬**：双盘旋转（scale 0.7 + rotate 60°）
  - **风水罗盘**：指针扫描（rotate -45° + scale 0.85）
- 关闭 `transitionsEnabled` 后退回纯 FadeTransition

### Phase 5.1：DivinationLoadingIndicator

- 替换默认 `CircularProgressIndicator`
- 设计：六边形外环旋转（2.4s/圈）+ 中心八卦点环反向旋转（1.5 倍速）+ 中心金光呼吸（1.8s/圈）
- 4 层绘制：呼吸光晕 → 6 段短弧（错峰 alpha） → 8 个金点（反向旋转） → 中心脉冲点
- 用于 `history_page` 和 `settings_page` 加载状态

### 仪式动画时长常量

- `core/theme/animations.dart` 新增 4 个常量
  - `ritualMeihua = 4000ms` / `ritualJiaobei = 3000ms` / `ritualCezi = 5000ms` / `ritualChouqian = 5000ms`

## 技术要点

- **仪式动画全覆盖**：10 术每术都有 3-6s 仪式入场动画
- **路由转场差异化**：10 术每术有专属视觉转场
- **加载指示器**：所有 `CircularProgressIndicator` 替换为中国风 `DivinationLoadingIndicator`
- **可控性**：4 个 sub-switch 独立可控 + 微交互动效总开关
- **性能**：所有新增组件用 RepaintBoundary 隔离；CustomPainter `shouldRepaint` 精确控制；AnimationController 严格 dispose
- **flutter analyze 0 issue**

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.2.0_feature_20260714_01.apk | 53.60 MB | 4BE5BECB02B2FC15583FC7426947475F829D4CF637AB848A84641A30937B2ABD |
| Windows x64 | Jeenith_2.2.0_feature_20260714_01_windows_x64.zip | 13.12 MB | 47A2D4EFF14C7134B642D6D77AD42721AC610F96FA442D3CE8A2350F0AD0C4B8 |

## 后续阶段预告

- v2.3.0：Phase 3 CustomPainter 绘制过程动画 + Phase 4.1-4.2 结果揭示封装 + Phase 5 剩余微交互 + Phase 6 性能优化

---

志极 Jeenith · 叩问本心
