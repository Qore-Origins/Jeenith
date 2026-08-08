# v2.12.0 — 紫微流年/小限

## 概述

紫微斗数新增**流年运势**推演：以值年地支为流年命宫，叠加流年四化与小限宫，在本命盘上高亮显示流年命宫（红）/ 小限宫（蓝），并给出流年断辞。排盘后可开关流年、输入任意年份查看该年运势走向。

## 新增功能

### 流年盘

- **流年命宫**：以值年地支为流年命宫（如丙午年以午宫为流年命宫），十二宫逆布方向同本命
- **流年三方四正**：流年命宫 + 财帛 + 官禄 + 迁移，自动定位
- **流年四化**：流年天干查表（复用 sihuaByGan），断辞标注每颗流年化星落宫与含义（禄/权/科/忌）

### 小限

- **小限宫**：从生年支起一岁，逐年顺行一位（不分性别），标注该年主导心境之宫

### 命盘叠加绘制

- 流年命宫：红色边框 + 红色地支字
- 小限宫：蓝色边框 + 蓝色地支字
- 切换流年时即时重绘

### 交互

- 排盘结果区新增「流年运势」开关
- 开启后显示年份输入（默认当前年）+ 刷新按钮 + 流年干支与虚岁
- 「◆ 流年运势」断辞面板：命宫主星基调 + 四化落宫 + 小限
- 复制结果文本含流年段

## 影响文件

- `mobile/lib/features/ziwei/algorithm/liu_nian.dart`（新）— LiuNianInfo + computeLiuNian + liuNianPoints
- `mobile/lib/features/ziwei/ui/star_chart_painter.dart` — 流年命宫/小限高亮
- `mobile/lib/features/ziwei/ui/ziwei_page.dart` — 流年切换 UI + 断辞面板 + copyText
- `mobile/test/ziwei_liunian_test.dart`（新）— 算法单测

## 验证

- `flutter analyze`：No issues found
- `flutter test`：computeLiuNian 8 项全过（干支 / 虚岁 / 小限 / 三方四正 / 流年四化）

## 自 v2.11.1 以来的提交

| Commit | 类型 | 说明 |
|--------|------|------|
| `32eb559` | feat | 紫微流年/小限（流年命宫 + 四化 + 小限宫 + 断辞 + 单测）|

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.12.0_release_20260724_01.apk | 59.20 MB | `78BE7F9505AB620D7030B26F4E2F9CA30A5EF0487C8612B43711689BC4CCC80F` |
| Windows x64 | Jeenith_2.12.0_release_20260724_01_windows_x64.zip | 15.71 MB | `6A0FC5B577564DF0C54D702D9B4DB034BD84037F9261CC1853FC8E84F3704C4F` |

## 版本信息

- **版本号**：2.12.0+47
- **构建状态**：release
- **构建日期**：2026-07-24
