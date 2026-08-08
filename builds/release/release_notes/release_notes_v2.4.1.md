# v2.4.1 — 思源宋体接入 + 分享图主题背景 + 首页折叠 + 首页卡片浅色修复

**版本**：2.4.1+25
**状态**：fix
**构建日期**：2026-07-18

## 概述


v2.4.1 是志极 v2.4.x 系列的体验定调版本。本次落地 4 项：接入思源宋体作为全局默认字体，强化中国风仪式感与可读性；分享结果图补上主题背景，修复透明背景导致文字「浮空」的违和；首页「使用方法」卡片默认折叠，降低首屏信息过载；首页 12 术卡片浅色模式残留深色渐变修复。代价是字体让 APK 体积由 55 MB 涨到 74 MB（子集化留待后续）。`flutter analyze` 0 issue 通过。

## 一、思源宋体接入

### 1. 字体资源

- 思源宋体（SourceHanSerifCN，OTF）的 **Regular + Bold** 两 weight 入库，置于 `mobile/assets/fonts/`
- [pubspec.yaml](file:///d:/Code/Project/Qore/Jeenith/mobile/pubspec.yaml) 声明 `family: SourceHanSerif`，映射 Regular（400）/ Bold（700）
- 仅这两个 weight 进 git（共 ~22 MB）；其余 5 个字重（ExtraLight / Light / Medium / SemiBold / Heavy）写入 `.gitignore` 忽略，避免仓库膨胀（此前误入库 7 字重 78 MB 已清理）

### 2. 全局应用

- [app_theme.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/core/theme/app_theme.dart) 新增字体常量 `AppFonts.serif = 'SourceHanSerif'`
- `_darkTheme()` / `_lightTheme()` 均设 `fontFamily: AppFonts.serif`
- `MaterialApp` 全局生效，所有 `Text` 默认走宋体；缺失字形自动回退系统字体，不丢字

### 3. 体积影响

| 平台 | v2.4.0 | v2.4.1 | 增量 |
|------|--------|--------|------|
| Android APK | 55.14 MB | 73.89 MB | +18.75 MB |
| Windows zip | 13.01 MB | 40.01 MB | +27.00 MB |

增量主要来自两 weight 字体（~22 MB）+ 桌面端字体渲染依赖。后续可用 `pyftsubset` 子集化（提取常用 3500 字 → 每 weight ~3 MB）大幅缩减。

## 二、分享结果图主题背景

### 问题

`RepaintBoundary` 截图默认透明背景。分享到浅色背景的聊天 / 社交 App 时，深色文字「浮空」、鎏金描边无衬底，观感割裂；深色背景下又看不出边界。

### 修复

[share_result_button.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/shared/widgets/share_result_button.dart) 新增 `_composeWithBackground(raw, isLight)`：

- 截图后用 `Canvas` 合成主题背景再分享，不再透出底色
- 背景：`LinearGradient`——深色主题玄黑（`#0C0A12 → #1B1626`），浅色主题浅米（`#F6F0E2 → #EBE2CC`）
- 边框：鎏金 stroke（`goldBorder`，~4px），与 app 鎏金描边一致
- `isLight` 由 `Theme.of(context).brightness == Brightness.light` 判定，深 / 浅主题各得其所
- 内边距 16 px，确保截图内容不贴边

## 三、首页「使用方法」默认折叠

### 改动

[home_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/home/home_page.dart)：

- `_guideExpanded` 初值改为 `false`（默认折叠）
- `ExpansionTile` + `ExpansibleController` 受控展开 / 收起
- `AnimatedExpandIcon` 状态切换动画保留（展开鎏金 / 收起 textSubtitle）
- 用户首次进入首页不再被大段使用说明占据首屏，12 术选术卡片更突出；需要时点开即可

## 四、首页卡片浅色修复

### 问题

首页 12 术 `InteractableCard` 在浅色模式下右下角仍残留深色渐变（`buttonBottom` 深色常量），与浅色卡片底色违和，像一块「没擦干净的深色补丁」。

### 修复

[interactable_card.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/shared/widgets/interactable_card.dart)：

- `isLight = Theme.of(context).brightness == Brightness.light`
- `cardColor = isLight ? AppColorsLight.card : AppColors.card`
- 卡片渐变第二色改用 `cardColor`，浅色模式下整体协调

## 五、已知限制（后续版本处理）

- **浅色模式全面适配**：v2.4.1 仅修复首页卡片；历史 / 设置及各术 page 的卡片、文字、CustomPainter 仍未跟随主题。**v2.4.2 专项处理**——深 / 浅主题切换加 450 ms 渐变过渡（`Color.lerp` 插值 + `ThemeAnimScope`），12 术 page 全面主题感知（`AppColors.x → AppClr.of(context).x`），命盘 / 天盘 / 罗盘等透明背景 CustomPainter 注入 `AppClr` 跟随主题；掐指盘 / 入场仪式保留深色器物本体。
- **历史记录预览**：v2.4.3+ 新历史存结构化数据后支持「预览恢复卦象」；旧历史（仅文本）预览按钮置灰。
- **测字词库扩展**：v2.4.3+ 接入开源康熙笔画数据集（替代当前 ~400 字 `Map`）。

## 六、版本号更新

- [pubspec.yaml](file:///d:/Code/Project/Qore/Jeenith/mobile/pubspec.yaml)：2.4.0+24 → 2.4.1+25

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.4.1_fix_20260718_01.apk | 73.89 MB / 77482422 B | A427A2401D4A22E9AE57F6543BFBD9677F2B7AB581D8B7B652A239237777A774 |
| Windows x64 | Jeenith_2.4.1_fix_20260718_01_windows_x64.zip | 40.01 MB / 41952823 B | 3622DA62B9429FA86B877258DC0ECF6C383F9C57E6EA12AFEABA625CFF622C14 |

---

志极 Jeenith · 叩问本心
