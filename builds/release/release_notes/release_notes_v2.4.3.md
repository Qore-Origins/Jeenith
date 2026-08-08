# v2.4.3 — 历史预览 + 罗盘视觉统一 + 康熙笔画数据集 + 揭示动画修复

**版本**：2.4.3+27
**状态**：feature
**构建日期**：2026-07-19

## 概述

v2.4.3 是体验深化版本。落地四大功能 + 一项动画修复：历史记录「预览恢复卦象」（11 术全闭环，旧记录置灰）；小六壬罗盘视觉统一（入场仪式同心圆→罗盘金环+刻度，卜算罗盘卜算时旋转）；测字与五格接入开源康熙笔画数据集（2 万字，取代原 ~200/490 字表）；修复 RevealAnimation 第二次卜算不重放的动画 bug。`flutter analyze` 0 issue。

## 一、历史记录预览（11 术全闭环）

- [history_store.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/core/history/history_store.dart) 的 `HistoryEntry` 加 `extra` 字段（结构化恢复数据）+ 新增 `pendingRestoreProvider`
- [history_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/history/history_page.dart) 列表加「恢复卦象」按钮：有 extra 鎏金可点 → 跳转该术 page 预填重建；旧记录（v2.4.3 前）置灰 + tooltip「旧记录不支持恢复」
- 11 术（除风水罗盘实时方位不入历史）：
  - **确定性术**（小六壬/测字/梅花/抽签/测名字/八字/紫微/奇门/大六壬）存输入重算
  - **随机术**（周易/掷筊）存结果快照重建
- 各术 page `initState _maybeRestore` 消费 provider，不走起卦动画 / 不重新入历史

## 二、小六壬罗盘视觉统一

- [xiaoliuren_ritual.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/xiaoliuren/ui/xiaoliuren_ritual.dart) 入场仪式 4 个同心圆改为罗盘样式（金环 + 周边 24 刻度，主刻度更粗），保留错峰展开 + 交替顺逆旋转动画
- [divination_wheel.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/xiaoliuren/ui/divination_wheel.dart) 卜算页外环 48 刻度卜算时旋转（idle 静止），呼应起卦动态；金环为圆旋转不可见故静止，中心太极本就随 pulse 转

## 三、康熙笔画数据集（测字 + 五格统一）

- 接入开源数据 [breezyreeds/kangxi-strokecount](https://github.com/breezyreeds/kangxi-strokecount)（MIT License，6.3 万字康熙笔画 CSV）
- 提取 CJK 基本区 **20717 字** → `data/kangxi_strokes.dart`（共享数据源）
- 测字（[cezi/divine.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/cezi/algorithm/divine.dart)）：删除原 ~200 字**简体**笔画表，`strokesOf` 改查康熙数据
- 五格（[name_test/strokes_data.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/name_test/algorithm/strokes_data.dart)）：原 ~490 字表替换为共享 2 万字，修正简体计画错误（如「生」4→5 康熙）
- 测字「笔画→五行→断语」与五格剖象现共用同一康熙数据源，覆盖率与准确性双升

## 四、RevealAnimation 第二次卜算重放修复

- **问题**：RevealAnimation 是 StatefulWidget，controller 仅 `initState` forward；同一页面第二次起卦时 State 持久、controller 不重置，结果**瞬间显示无动画**
- **修复**：加 `replayKey` + `didUpdateWidget`，replayKey 变化时 `forward(from:0)` 重放
- 8 处调用传 replayKey（八字/紫微/奇门/大六壬/测字/抽签/测名字传结果对象，掷筊传 `_last`）
- `_buildTypewriter` substring 加 clamp 防 title 长度变化越界
- **排查同类**：xiaoliuren/zhouyi/meihua 自带 `AnimationController` 每次卜算 `forward(from:0)` 无此 bug；EntranceItem 基于传入 animation 也无此 bug。RevealAnimation 是唯一病灶

## 五、版本号更新

- [pubspec.yaml](file:///d:/Code/Project/Qore/Jeenith/mobile/pubspec.yaml)：2.4.2+26 → 2.4.3+27

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.4.3_feature_20260719_01.apk | 75.01 MB / 78645746 B | 15668644284A17AA3ECF07D1100293F97A9BA7447385D09E213A3F4B936D2F67 |
| Windows x64 | Jeenith_2.4.3_feature_20260719_01_windows_x64.zip | 32.37 MB / 33947979 B | 97EEBB04F2CBD0C5B492E4569BB5B21B47413F951FCF5616E45967F094C846EE |

---

志极 Jeenith · 叩问本心
