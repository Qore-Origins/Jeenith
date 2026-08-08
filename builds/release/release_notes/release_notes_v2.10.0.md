# v2.10.0 — 浅色模式深度适配 + GoldButton 竖线 BUG 第三次根治

**版本**：2.10.0+40
**状态**：feature
**构建日期**：2026-07-21

## 概述

v2.10.0 完成两项核心工作：**浅色模式深度适配**（参照设置页配色，全部 15 个卜算术页面去硬编码，引入 AppClr 主题感知色板）+ **周易起卦按钮竖线 BUG 第三次"根治"**（ConstrainedBox 三重防护方案，避免在 SliverPersistentHeader + DraggableScrollableSheet loose 约束场景下坍塌）。`flutter analyze` 0 issue。

## 一、浅色模式深度适配（参照 settings_page 配色）

- **GoldButton / DarkButton 颜色主题感知**：浅色用浅米渐变 + 深鎏金描边，深色保持紫黑渐变 + 亮鎏金描边
- **`_WheelPainter` 接受 AppClr 参数**：小六壬罗盘背景径向渐变、太极两色、外装饰金环、刻度、连接环、激发爆光、六宫节点描边、宫名/五行方位文字、游走指针 + 拖尾全部主题感知
- **`_SticksPainter` 主题感知**：抽签筒竹签/签尖/红色装饰/文字色
- **`_jiaoPiece` 4 处硬编码改主题感知**：掷筊阳面鎏金/阴面褐色
- **zhouyi / xiaoliuren 拖拽把手 + Divider** 改 `c.gold.withValues(alpha:)`
- **daliuren `_TianPanPainter` / luopan `_LuopanPainter`** 放射线改 `clr.gold.withValues(alpha:)`
- **bazi DatePicker `onPrimary`** 浅色用浅米字保证对比度
- 全部 15 个卜算术页面硬编码颜色清零（小六壬/周易/梅花/掷筊/紫微/奇门/抽签/测字/大六壬/风水罗盘/八字/测名字/称骨/太乙/六爻）

## 二、周易起卦按钮竖线 BUG 第三次"根治"（v2.10.0）

| 历次修复 | 方案 | 失效原因 |
|------|------|---------|
| v2.3.1 | 局部 `SizedBox(width:88)` | 仅在 zhouyi 页生效，其他页面仍可能复发 |
| v2.7.1 | 全局 `SizedBox(width:double.infinity)` | 在 SliverPersistentHeader + DraggableScrollableSheet loose 约束下 fallback 到 0 |
| **v2.10.0** | `ConstrainedBox(minWidth:88, maxWidth:double.infinity) + SizedBox(width:double.infinity)` 三重防护 | tight 撑满 / loose 兜底 / unbounded 取 minWidth |

- **DarkButton 同步加防御**：`ConstrainedBox(minWidth:72, maxWidth:double.infinity) + SizedBox(width:double.infinity)`

## 三、新增频发 BUG 复用 issues 文档

`docs/频发BUG/GoldButton竖线坍塌.md` —— 7 章节：现象 / 根因 / 三次"根治"历史 / 复用排查清单 / 相关代码位置 / 预防措施 / 版本演进时间线。后续若再复发，按此文档复用排查。

## 验证

`flutter analyze` No issues found! (ran in 36.2s)

## 版本号

- [pubspec.yaml](file:///d:/Code/Project/Qore/Jeenith/mobile/pubspec.yaml)：2.9.2+39 → 2.10.0+40

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.10.0_feature_20260721_01.apk | 58.84 MB / 61702222 B | 7FFAAD49DC8D4D118268057A83DF9B988106FE927B972649995D252134D026AC |
| Windows x64 | Jeenith_2.10.0_feature_20260721_01_windows_x64.zip | 15.66 MB / 16421949 B | DE21FCD8B1A4A3B0BD11BB8805902FF3A3FBF78478ECE8221AD9547C986EBA1D |

---

志极 Jeenith · 叩问本心
