# v2.4.4 — 思源宋体子集化 + 复杂术引导遮罩 + 共享组件浅色收尾

**版本**：2.4.4+28
**状态**：feature
**构建日期**：2026-07-19

## 概述

v2.4.4 是体积优化 + 体验补全版本。三大改动：思源宋体子集化（字体砍 88%，APK 75→58 MB、Windows 32→16 MB）；紫微/奇门/大六壬三术新增首次使用引导遮罩；剩余共享组件浅色适配收尾。`flutter analyze` 0 issue。

## 一、思源宋体子集化（体积优化）

- pyftsubset 提取 GB2312 一级汉字 + 符号区约 4500 字，子集化 Regular + Bold
- 字体体积：11 MB/weight → 1.4 MB/weight（共 22 MB → 2.7 MB，**砍 88%**）
- 原 7 字重 OTF 移出 git（.gitignore 忽略 `SourceHanSerifCN-*`，本地保留备用）
- [pubspec.yaml](file:///d:/Code/Project/Qore/Jeenith/mobile/pubspec.yaml) 引用子集 `SourceHanSerif-Regular.otf` / `Bold.otf`
- 基本区外罕见字回退系统字体（GB2312 一级覆盖绝大多数 UI 文字）

### 体积对比

| 平台 | v2.4.3 | v2.4.4 | 削减 |
|------|--------|--------|------|
| Android APK | 75.01 MB | 58.26 MB | **-16.75 MB** |
| Windows zip | 32.37 MB | 15.58 MB | **-16.79 MB** |

## 二、复杂术数首次使用引导遮罩

- 新增 [TechGuideOverlay](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/shared/widgets/tech_guide_overlay.dart)（参数化 `title` + `steps`，复用 GuideDialog 入场动画：背景模糊渐入 + 卡片 scale `easeOutBack` + 3s 倒计时禁关，主题感知 AppClr）
- 紫微 / 奇门 / 大六壬 page initState 首次进入显示指引（SharedPreferences `tech_guide_<id>` 控制只弹一次）
- 内容涵盖排盘输入 / 盘面解读 / 历法 / 交互，降低复杂术上手门槛

## 三、共享组件浅色收尾

- [hoverable_icon_button.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/shared/widgets/hoverable_icon_button.dart)：默认 baseColor / hoverColor 走 AppClr
- [copy_result_button.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/shared/widgets/copy_result_button.dart)：复制图标色 + SnackBar 背景主题感知
- [divination_loading_indicator.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/shared/widgets/divination_loading_indicator.dart)：painter 注入 accent（goldBright），主色走 AppClr
- [guide_dialog.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/shared/widgets/guide_dialog.dart)：全面主题感知（card / goldBright / textBody / gold / textHint / goldBorder）
- [share_result_button.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/shared/widgets/share_result_button.dart)：分享图标色走 AppClr
- interactable_card 已 isLight 适配（保留）

## 四、版本号更新

- [pubspec.yaml](file:///d:/Code/Project/Qore/Jeenith/mobile/pubspec.yaml)：2.4.3+27 → 2.4.4+28

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.4.4_feature_20260719_01.apk | 58.26 MB / 61079626 B | BFB34AFD5C9B11B52F3BAB542F347F61FA8BE4134344E9298776C95BD2508FFD |
| Windows x64 | Jeenith_2.4.4_feature_20260719_01_windows_x64.zip | 15.58 MB / 16329558 B | 65A572877C99FAC527261D38B4D4D6A8D3EA72F1641C9A32C714E25B75F4FF71 |

---

志极 Jeenith · 叩问本心
