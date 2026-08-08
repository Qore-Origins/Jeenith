# v1.6.0 — 抽签求签 + 测字

**版本**：1.6.0+13
**状态**：feature（多阶段计划第 5 阶段 · 扩展性）
**构建日期**：2026-07-13

## 概述

为志极新增两个卜算术：抽签求签与测字。这是多阶段实施计划的第 5 阶段，聚焦框架扩展性——通过 DivinationTech 注册模式加新术只需新建 feature 目录 + 注册一行。

## 新增功能

### 抽签求签（chouqian · sortOrder 6）

- 30 签样例数据：覆盖五等级（上上 5 / 上 5 / 中 10 / 下 5 / 下下 5），每签含签题、级别、签诗、解曰、详注（财运/事业/姻缘/健康）
- 签诗采用传统四句体裁，签题取意于中国传统意象（紫气东来、鲤鱼化龙、金榜题名等）
- 竹签筒可视化：CustomPainter 绘制筒内一束竹签 + 筒口装饰
- 摇签动画：阻尼振荡 `sin(8π·t) × (1-t) × 0.18` 模拟竹签筒左右摆动
- 落签动画：fall.value 0→1 时一支竹签从筒中升起（含签头红色装饰 + 「签」字标记）
- 真随机引擎：通过 `ref.read(trueRandomProvider).generate(count: 1, vmax: 30)` 取签号，遵循硬约束
- 结果展示：签号 + 等级徽章（颜色分级：上上绿/上青/中金/下浅/下下红）+ 签题 + 签诗（楷体竖排居中）+ 解曰 + 详注
- 复制/分享按钮 + RepaintBoundary 截图分享

### 测字（cezi · sortOrder 7）

- 内置 200+ 常用汉字笔画表（简体计画）
- 未收录字按 unicode 哈希估算（伪笔画但稳定，保证可重现）
- 五行属性按笔画尾数映射：1/2 木、3/4 火、5/6 土、7/8 金、9/0 水
- 字形拆解：根据笔画数判断「繁复/适中/简练」三档结构特征
- 断语诗：按五行生成不同四句诗（金/木/水/火/土 各一首）
- 大字展示：110×110 卡片居中显示用户输入字（64px 字号），五行色描边
- 三属性徽章：笔画 / 五行 / 性情
- 输入校验：regex `^[\u4e00-\u9fa5]$` 限制单个汉字，非汉字 SnackBar 提示
- 复制/分享按钮 + RepaintBoundary 截图分享
- 测字要诀说明面板（凝神→浮现→拆字三步）

## 技术要点

- 新术注册：`divination_registry.dart` 列表追加 `ChouqianTech(), CeziTech(),` 两行
- 首页 grid 自动出现新卡片（visibleTechsProvider 按 sortOrder 排序）
- TextPainter 在 _SticksPainter 中显式 dispose()（遵循硬约束）
- 测字算法纯函数式：`divine(inputChar)` 输入确定即输出确定，无 RNG 依赖
- 抽签用 `trueRandomProvider`（与 xiaoliuren 同模式），保证多源熵混合
- 等级颜色映射复用 AppColors.grade* 系列（gradeGreat/Good/Steady/Rough/Bad）
- flutter analyze 0 issue

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|
| Android | Jeenith_1.6.0_feature_20260713_01.apk | 52.54 MB / 55093452 B | B9E446462F981A1F9D81E341EC195590CED926642581FADA818635E96F36544D |
| Windows x64 | Jeenith_1.6.0_feature_20260713_01_windows_x64.zip | 13.00 MB / 13633367 B | D62B6EF22662B46908E72184E36F39F3805C0821E9A1CA101311526D6708876D |

## 后续阶段预告

- v1.7.0 — 大六壬全套 + 风水罗盘

---

志极 Jeenith · 叩问本心
