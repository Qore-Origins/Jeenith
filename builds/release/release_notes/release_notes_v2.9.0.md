# v2.9.0 — 六爻断法深化（旬空 + 六冲六合）

**版本**：2.9.0+37
**状态**：feature
**构建日期**：2026-07-20

## 概述

v2.9.0 深化六爻纳甲断法——新增**旬空（空亡）**与**六冲/六合卦**两项核心断卦要素。空亡判断用神虚实，六冲六合断卦象聚散。`flutter analyze` 0 issue，12 项单测全过。

## 新增断法

### 旬空（空亡）
- 以**日柱**所在旬推空亡地支（甲子旬空戌亥、甲戌旬空申酉…）
- 用神落空亡 → 断辞提示（动空「出空则应」/ 静空「待出空或冲空之日」）+ 旺衰 score 减分
- UI：用神爻显示「空」tag，hero 日辰行显示日空地支

### 六冲 / 六合卦
- **六冲**：六爻地支两两冲（初冲四、二冲五、三冲上）→ 主散、主变、事多反复
- **六合**：六爻地支两两合 → 主合、主聚、事多缓成
- UI：hero 显示「六冲卦」/「六合卦」chip + 断辞要点

## 验证

3 项新单测（共 12 项全过）：乾为天六冲、天地否六合、甲子旬空戌亥。

## 技术细节

- `najia_data.dart`：加 xunKong（旬空表）、chongMap（六冲）、liuHeMap（六合）
- `divine.dart`：加 `_xunTou`/`_dayKongOf`（旬空计算）、`_isLiuChong`/`_isLiuHe`（卦格局判断），LiuyaoResult 加 dayKong/yongKong/isLiuChong/isLiuHe 字段，`_judge` 整合空亡 + 六冲六合断辞
- `liuyao_page.dart`：hero 加格局 chip + 日空显示，用神爻加「空」tag

## 版本号

- [pubspec.yaml](file:///d:/Code/Project/Qore/Jeenith/mobile/pubspec.yaml)：2.8.1+35 → 2.9.0+37

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.9.0_feature_20260720_01.apk | 58.83 MB / 61685838 B | 4021CB2421882971ED84221E9CD07C978B50D4904F15269868108142FC5AD495 |
| Windows x64 | Jeenith_2.9.0_feature_20260720_01_windows_x64.zip | 15.65 MB / 16414042 B | 337D16AF48E0ABAA736E83FE40D703795D43B4E99623883820BAF19FA00BBE82 |

---

志极 Jeenith · 叩问本心
