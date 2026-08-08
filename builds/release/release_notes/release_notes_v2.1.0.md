# v2.1.0 — 动效体系 Phase 1 + Phase 2a（5 套仪式动画落地）

**版本**：2.1.0+17
**状态**：feature
**构建日期**：2026-07-14

## 概述

v2.1.0 是志极「全术仪式化动效体系」的奠基版本。用户点击卡片后，先经历一段 4-6s 的仪式动画（铜钱抛落 / 命盘展开 / 九宫飞布 / 双盘旋转 / 罗盘扫描），再进入操作页。3s 后出现「跳过」按钮，关闭「仪式动画」开关后可直接进入。

按用户约束实现：80% 大动效 + 20% 微动效；黑金低饱和度无光污染；性能流畅可承载大量动画；4 个 sub-switch 独立可控（仪式/绘制/揭示/转场）。

## 新增功能

### Phase 1：基础设施

#### 1. 仪式动画抽象基类
- `RitualAnimation extends ConsumerStatefulWidget`：持有 `onCompleted` 回调
- `RitualAnimationState<T> with TickerProviderStateMixin`：子类创建自己的 `AnimationController`
- `ritualScaffold(content)`：Scaffold + `AppColors.bg` 背景 + 3s 后淡入的「跳过」按钮

#### 2. CustomPainter 动画基类
- `progress` 参数驱动绘制（0.0 → 1.0）
- 工具函数：`seg` / `easeOut` / `easeInOut` / `easeOutBack` / `lerpAngle` / `lerp`

#### 3. 粒子系统
- `ParticleBurst`：粒子爆发组件
- `LightTrail`：金光线段，用于星曜降落光尾

#### 4. 结果揭示动画组件
- `TypewriterText`：逐字显示 + 光标闪烁
- `StaggeredReveal`：段落错峰淡入上浮
- `InkSpread`：ShaderMask + RadialGradient 墨晕开
- `ScaleReveal`：缩放 + 透明度揭示

#### 5. 配置开关升级
- `AppConfig` 新增 4 个字段（均默认 true）
  - `ritualAnimationsEnabled` / `painterAnimationsEnabled` / `revealAnimationsEnabled` / `transitionsEnabled`
- 设置页新增 4 个 sub-switch，条件显示在主开关下

#### 6. 仪式时长常量
- `core/theme/animations.dart` 新增仪式动画时长常量
  - `ritualZhouyi = 5000ms` / `ritualZiwei = 6000ms` / `ritualQimen = 5000ms`
  - `ritualDaliuren = 5000ms` / `ritualLuopan = 4000ms`
  - `skipButtonDelay = 3000ms`

### Phase 2a：5 套仪式动画

#### 周易铜钱抛落（5s）
- 6 轮金钱卦，每轮 3 枚铜钱从屏幕顶部抛落 + 翻滚
- 落地时显示正反（字/背），从下到上堆叠成六爻

#### 紫微命盘展开（6s，视觉冲击最大）
- 5 阶段：背景渐显 → 中心金光爆 → 12 宫辐射展开 → 14 主星降落（带光尾） → 金边描边

#### 奇门九宫飞布（5s）
- 6 阶段：九宫格显现 → 值符值使飞入 → 八门按方位 → 九星从天顶 → 八神四角落座 → 整盘金光

#### 大六壬双盘旋转（5s）
- 7 阶段：背景 → 外环 → 内环 → 双盘收敛对位 → 四课浮现 → 三传降下 → 金光

#### 风水罗盘扫描（4s）
- 7 阶段：表盘绘制 → 指针出现 → 指针旋转扫描 → 24 山依次点亮 → 稳定 → 十字线八卦 → 金光

### 路由集成
- 新增 5 个 `/ritual/<tech>` 路由
- 首页 `_onTapTech` 扩展：受 `animationsEnabled` + `ritualAnimationsEnabled` 双重控制

## 技术要点

- **不引入新依赖**：自定义动画而非 `flutter_animate`，避免 APK 体积膨胀
- **性能**：所有动画用 RepaintBoundary 隔离 + AnimationController dispose 严格管理
- **基类修复**：`qimen_ritual.dart` 创建过程中发现基类错误引用 `AppColors.background`，已统一为 `AppColors.bg`
- **flutter analyze 0 issue**

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.1.0_feature_20260714_01.apk | 53.48 MB | FFB7A63FCBDC41BDF43F653FAEF7E8B57B4B786DB0921DF72AB406B006309EC1 |
| Windows x64 | Jeenith_2.1.0_feature_20260714_01_windows_x64.zip | 13.10 MB | C8697456546718C5EFE3D94A1724C5F5C223BB797684D8F6770E3C3B2371680A |

## 后续阶段预告

- v2.2.0：Phase 2b 后 4 套仪式动画（梅花/掷筊/抽签/测字）+ Phase 4.3 路由转场差异化 + Phase 5.1 加载指示器

---

志极 Jeenith · 叩问本心
