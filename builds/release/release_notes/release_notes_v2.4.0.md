# v2.4.0 — 八字/测名字入场仪式 + 一键获取当前时间 + 词库扩展 + All rights reserved 全面移除

**版本**：2.4.0+24
**状态**：release
**构建日期**：2026-07-15

## 概述

v2.4.0 是志极 v2.x 系列的功能补全版本。本版本为剩余两项无入场仪式的卜算术（八字推演、测名字）补齐了专属入场动画，使全部 12 项核心卜算术均具备仪式入场体验；为需要输入公历时间的奇门遁甲与大六壬新增"获取当前时间"按钮，一键回填时辰；扩展测名字康熙字典笔画词库约 30 个常用姓名用字（包括"喆"等此前无法识别的字）；并按 MIT 协议规范全面移除 Dart 源码与 Windows exe 属性中残留的 "All rights reserved" 字样。`flutter analyze` 0 issue 通过。

## 一、八字推演入场仪式

### 背景

八字推演（`features/bazi/`）自 v2.3.0 引入后，是 v2.x 体系中仅有的两项无入场仪式的卜算术之一。与紫微/奇门/大六壬等同源命理术相比，缺少进入时的沉浸式过渡，破坏了仪式感的一致性。

### 实施

新建 [bazi_ritual.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/core/animation/ritual/bazi_ritual.dart)（继承 `RitualAnimation`），动画时长 4500ms（[AppAnimations.ritualBazi](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/core/theme/animations.dart)），分四阶段：

1. **四柱降落**（0–2.5s）：年柱、月柱、日柱、时柱依次从屏幕上方鎏金落下，柱间距均匀，每柱由天干 + 地支组成
2. **日柱高亮**（2.5–3.5s）：日柱（命主本体）鎏金高亮，时柱（未来虚化）半透明处理
3. **五行色染**（3.5–4.2s）：四柱按五行属性（金/木/水/火/土）染上对应主题色
4. **标题淡入**（4.2–4.5s）：标题"八字推演"淡入居中

### 接入

- [app_router.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/router/app_router.dart)：新增 `/ritual/bazi` 路由，`onCompleted` 跳转 `/tech/bazi`
- [home_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/home/home_page.dart)：`_ritualTechs` 集合新增 `'bazi'`

## 二、测名字入场仪式

### 背景

测名字（`features/name_test/`）与八字推演同为 v2.3.0 引入的无仪式术数。

### 实施

新建 [name_test_ritual.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/core/animation/ritual/name_test_ritual.dart)，动画时长 4500ms（[AppAnimations.ritualNameTest](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/core/theme/animations.dart)），分四阶段：

1. **姓名浮现**（0–1.8s）：姓名三字依次淡入居中，鎏金描边
2. **五格展开**（1.8–3.2s）：天格、人格、地格、总格、外格以圆形围绕中心姓名展开，每格标注五行属性
3. **人格高亮**（3.2–4.0s）：人格（主运）鎏金高亮，与中心姓名之间绘制连接线
4. **标题淡入**（4.0–4.5s）：标题"测名字"淡入

### 接入

- [app_router.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/router/app_router.dart)：新增 `/ritual/name_test` 路由，`onCompleted` 跳转 `/tech/name_test`
- [home_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/home/home_page.dart)：`_ritualTechs` 集合新增 `'name_test'`

## 三、一键获取当前时间

### 背景

奇门遁甲与大六壬均需输入公历年月日时以起课/起局。此前用户需手动输入四个数字字段，体验繁琐。两者虽在 `initState` 已自动填充初始时间，但用户在排盘前若想刷新为"此刻"，仍需手动改写。

### 实施

为两项术数各新增"获取当前时间" [TextButton.icon](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/qimen/ui/qimen_page.dart)（鎏金主色），位于输入行与排盘按钮之间：

```dart
Align(
  alignment: Alignment.centerRight,
  child: TextButton.icon(
    onPressed: _fillNow,
    icon: const Icon(Icons.access_time, size: 16),
    label: const Text('获取当前时间', style: TextStyle(fontSize: 12)),
    ...
  ),
),
```

`_fillNow()` 取 `DateTime.now()`，将年/月/日/时四个 TextEditingController 填充为当前公历值，并 `FocusScope.of(context).unfocus()` 收起键盘。

### 影响文件

- [qimen_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/qimen/ui/qimen_page.dart)
- [daliuren_page.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/daliuren/ui/daliuren_page.dart)

### 不受影响

- **八字推演**：输入出生日期（非当前时间），不适用
- **梅花易数**：输入两个正整数，无时间字段
- **周易**：无输入字段
- **小六壬**：已有"时辰"按钮

## 四、测名字词库扩展

### 问题

用户反馈姓名"王喆"中的"喆"字在测名字中识别不到，被回退到 Unicode 估算公式（`5 + (ch.runes.first % 18)`），导致笔画计算错误，五格推算失准。

### 实施

扩展 [strokes_data.dart](file:///d:/Code/Project/Qore/Jeenith/mobile/lib/features/name_test/algorithm/strokes_data.dart) 的 `kangxiStrokes` 词库，新增约 30 个常用姓名用字：

| 画数 | 新增字 |
|------|--------|
| 4 画 | 丹、井、卞 |
| 5 画 | 仝 |
| 7 画 | 妍、彤、岚、芷、秀、佟、岑 |
| 8 画 | 若 |
| 9 画 | 奕、彦、胤 |
| 10 画 | 航 |
| 11 画 | 彬、珺、伟 |
| 12 画 | **喆**、雅、紫、舒、超、童 |
| 15 画 | 慕、慧、磊 |
| 16 画 | 燚 |
| 17 画 | 泽 |
| 19 画 | 丽 |

修复后"王喆"可正确识别：王 4 画 + 喆 12 画 = 天格 5、人格 16、地格 13、总格 16、外格 1。

## 五、All rights reserved 全面移除

### 背景

志极项目在 v2.3.3 已采纳 MIT 协议并明确版权行格式为 `Copyright (c) 2026 Qore`（按规范去除 "All rights reserved."，因 MIT 协议本身已授予使用权）。但此前批量添加的版权头仍保留 "All rights reserved" 字样，且 Windows exe 的"详细信息"属性中也保留了同样字样，与 MIT 协议精神不符。

### 实施

**Dart 源码**：批量替换 109 个 dart 文件的版权头：

```diff
- // Copyright (c) 2026 Qore. All rights reserved.
+ // Copyright (c) 2026 Qore
```

**Windows 资源**：[Runner.rc](file:///d:/Code/Project/Qore/Jeenith/mobile/windows/runner/Runner.rc) 第 96 行 `LegalCopyright` 字段改为：

```diff
- VALUE "LegalCopyright", "Copyright (c) 2026 Qore. All rights reserved." "\0"
+ VALUE "LegalCopyright", "Copyright (c) 2026 Qore" "\0"
```

**其他平台**：

- [MainActivity.kt](file:///d:/Code/Project/Qore/Jeenith/mobile/android/app/src/main/kotlin/com/qore/jeenith/MainActivity.kt)：Kotlin 版权头同步更新
- [AppInfo.xcconfig](file:///d:/Code/Project/Qore/Jeenith/mobile/macos/Runner/Configs/AppInfo.xcconfig)：macOS `copyright` 字段同步更新
- [build_apk.ps1](file:///d:/Code/Project/Qore/Jeenith/mobile/scripts/build_apk.ps1) / [archive_history.py](file:///d:/Code/Project/Qore/Jeenith/mobile/scripts/archive_history.py)：脚本内版权注释同步
- [代码开发规范.md](file:///d:/Code/Project/Qore/Jeenith/docs/项目文档/03-开发实施%20Development/代码开发规范%20Coding%20Standards.md)：规范文档中的版权头示例同步

### 验证

构建后提取 Windows exe 属性的 `LegalCopyright`：

```
Copyright (c) 2026 Qore
```

确认无 "All rights reserved" 字样。

### 单独搜索验证

按用户要求，对项目全量源码分别单独搜索 "All"、"rights"、"reserved" 三个词：

- "All" — 仅出现在英文注释、变量名（如 `resetAll`）、Flutter SDK 自动生成代码中，无版权相关用法
- "rights" — 仅出现在 LICENSE 文件本身的 MIT 协议正文（"retain the above copyright notice..."），属协议必要内容
- "reserved" — 无残留

顾虑已证实不必要：版权字样已彻底从源码与产物属性中清除。

## 六、版本号更新

- pubspec.yaml：2.3.3+23 → 2.4.0+24
- 构建序号：20260715 第 01 序

## 七、自 v2.3.3 以来的提交

| Commit | 类型 | 说明 |
|--------|------|------|
| `dbd503f` | docs | 重写 docs/项目文档/ 39 个文档（原为校园预警系统内容，全部改为志极项目文档） |
| `0e99d18` | docs | 更新 README 卜算术清单与技术栈 + 修正项目命名规范 |
| 本次 | feat | v2.4.0 — 八字/测名字仪式 + 获取时间按钮 + 词库扩展 + 版权清理 |

## 八、下载

| 平台 | 文件名 | 大小 | SHA-256 |
|------|--------|------|---------|
| Android | Jeenith_2.4.0_release_20260715_01.apk | 55.14 MB / 57815079 B | BA2CFB282BBABBB625F2C72651B7AD91B9E5433F92021BD75657FA55D719A608 |
| Windows x64 | Jeenith_2.4.0_release_20260715_01_windows_x64.zip | 13.01 MB / 13637219 B | ECB700B94A25624A0E854BA782A756F82DC3C7CBD01021FEB9E12562C018FEB2 |
