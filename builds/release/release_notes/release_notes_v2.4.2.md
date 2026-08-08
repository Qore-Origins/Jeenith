# v2.4.2 — 浅色模式全面适配（深浅渐变切换 + 12 术主题感知）

**版本**：2.4.2+26
**状态**：feature
**构建日期**：2026-07-18

## 概述

v2.4.2 是志极浅色模式的全面落地版本。深 ↔ 浅主题切换加 450 ms 渐变过渡（`Color.lerp` 插值 + `ThemeAnimScope`），`AppClr` 主题色访问器覆盖 `AppColors` 全部色字段；12 术 page + 使用手册全面主题感知；紫微命盘 / 大六壬天盘 / 风水罗盘等透明背景 `CustomPainter` 注入 `AppClr` 跟随主题；掐指盘与入场仪式保留深色器物本体。`flutter analyze` 0 issue。

## 一、深浅主题渐变切换

### 1. AppClr 插值体系

- `AppClr` 改为基于动画插值 `t`（0=深，1=浅）的 `Color.lerp` 访问器，覆盖 `AppColors` 全部色字段（背景 / 鎏金 / 文字 / 面板 / 五行 / 爻色 / 断语分级 / `bgOuter` / `buttonTop` / `buttonBottom` 等）
- 用法：`context.appClr.card` 或 `AppClr.of(context).gold`；罕见色用 `c.resolve(深色, 浅色)`
- v2.4.1 及之前为「深浅二选一瞬切」，切换生硬；本版改为插值渐变

### 2. ThemeAnimScope + AnimationController

- [app_theme.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/core/theme/app_theme.dart) 新增 `ThemeAnimScope`（InheritedWidget）承载插值 `t`
- [app.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/app.dart) `JeenithApp` 改 `ConsumerStatefulWidget` + `AnimationController`（450 ms `easeInOutCubic`）
- 首次启动直接设值（避免开场动画），`themeMode` 变化时渐变过渡
- builder 内 `ColoredBox` + `Starfield` 同步随 `t` 渐变

## 二、12 术 page + 使用手册全面主题感知

逐术将硬编码 `AppColors.x` 替换为 `AppClr.of(context).x`（去 `const`）：

- 小六壬 / 掷筊 / 梅花 / 周易 / 抽签 / 测字 / 大六壬 / 紫微 / 风水罗盘 / 奇门 / 八字 / 测名字 — **12 术全部完成**
- [manual_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/manual/manual_page.dart) 使用手册页（`StatelessWidget` → `StatefulWidget`，8 个 helper 取 `AppClr`）
- 首页 / 历史 / 设置 / `DecorativePanel` 等共享组件同步主题感知

## 三、CustomPainter 注入 AppClr

透明背景图表（靠 `DecorativePanel` 衬底）必须主题感知，否则浅色底上深色文字不可见：

| 文件 | 角色 | 注入方式 |
|------|------|----------|
| [star_chart_painter.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/ziwei/ui/star_chart_painter.dart) | 紫微命盘 | painter 持有 `clr`，`shouldRepaint` 加 `clr.t` 判断 |
| [daliuren_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/daliuren/ui/daliuren_page.dart) `_TianPanPainter` | 大六壬天盘 | 同上 |
| [luopan_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/luopan/ui/luopan_page.dart) `_LuopanPainter` | 风水罗盘 | 同上 |
| [hexagram_view.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/zhouyi/ui/hexagram_view.dart) `_HexPainter` | 周易六爻 | 同上 |

## 四、保留深色器物本体的组件

以下自带深色背景的「器物级」可视化保留深色，不随主题变浅（避免丢失玄秘感）：

- [divination_wheel.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/xiaoliuren/ui/divination_wheel.dart)（小六壬掐指盘）：自带径向渐变深色底，像一个嵌入式深色仪表盘
- [xiaoliuren_ritual.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/xiaoliuren/ui/xiaoliuren_ritual.dart)（入场仪式）：3.8 s 全屏深色过场，沉浸式仪式感

## 五、已知限制（后续处理）

- 少数共享 widget（`gold_button` / `dark_button` 保持黑金；`guide_dialog` / `hoverable_icon_button` 等经 `ThemeData` 间接感知）后续可逐个审计
- 思源宋体**子集化**（`pyftsubset` 提取常用 3500 字 → 每 weight ~3 MB）以缩减 APK 体积
- 历史记录预览 + 测字康熙笔画数据集接入（v2.4.3）

## 六、版本号更新

- [pubspec.yaml](file:///d:/Code/Project/Qore/Jeenith/mobile/pubspec.yaml)：2.4.1+25 → 2.4.2+26

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_2.4.2_feature_20260718_01.apk | 74.06 MB / 77662646 B | 3E573869E85B1E918CE11AC190290CBE18320D9987CAB520610DD053B1B9001D |
| Windows x64 | Jeenith_2.4.2_feature_20260718_01_windows_x64.zip | 32.09 MB / 33650599 B | AE80E9461E426C4D4C00466D52BB76861DDD0D6A2AAA6F5A124EF304BC8A624C |

---

志极 Jeenith · 叩问本心
