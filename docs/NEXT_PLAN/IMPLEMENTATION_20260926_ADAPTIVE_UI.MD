# Jeenith 自适应视觉系统实施计划

> **执行方式**：在 `codex/ai-adaptive-ui` 隔离分支内逐项实施；此阶段只负责共享视觉基础、桌面导航与首页布局。AI 流程另按已批准方案分阶段落地。

**目标**：以一套低饱和浅色/深色设计令牌，配合分别面向 Windows 桌面和 Android 移动端的导航与首页组合，替换目前全局星空、黑金装饰和手机比例桌面窗口造成的陈旧观感。

**架构**：保留 `AppClr` 现有语义色属性，避免同时重写 15 种术数页面；集中调整语义色值与 Material 主题。新增共享断点定义，让主壳、首页和桌面窗口各自使用合适的尺寸规则。移动端继续使用底部主导航，桌面端改用常驻侧栏与宽屏工作区。

**技术栈**：Flutter 3.x、Dart 3.11、Material 3、现有 Riverpod 与 go_router；不新增依赖。

---

## 文件职责

- `mobile/lib/core/layout/app_breakpoints.dart`：桌面壳和首页列数使用的共享断点。
- `mobile/lib/core/theme/app_theme.dart`：深浅主题语义色、字体和 Material 组件默认样式；保留 `AppClr` 对外属性。
- `mobile/lib/app.dart`：应用根背景与全局装饰层。
- `mobile/lib/main.dart`：Windows 初始窗口按可用屏幕尺寸计算宽高，不再使用手机纵横比。
- `mobile/lib/shared/widgets/app_desktop_navigation.dart`：桌面常驻侧栏与全局路由入口。
- `mobile/lib/shared/widgets/main_shell.dart`：移动底部导航；桌面模式下不重复绘制导航。
- `mobile/lib/features/home/home_page.dart`：窄屏单列引导、宽屏品牌/快捷入口区和自适应术数卡片网格。

## Task 1：集中响应式断点

**Files:**
- Create: `mobile/lib/core/layout/app_breakpoints.dart`
- Modify: `mobile/lib/app.dart`
- Create: `mobile/lib/shared/widgets/app_desktop_navigation.dart`
- Modify: `mobile/lib/shared/widgets/main_shell.dart`
- Modify: `mobile/lib/features/home/home_page.dart`

- [x] **Step 1: 定义断点与网格列数**

创建不可变常量类，公开 `desktopNavigation = 960`、`homeThreeColumns = 900`、`homeFourColumns = 1220` 与 `contentMaxWidth = 1320`。公开 `isDesktopNavigation(double width)` 和 `homeColumns(double width)` 两个纯函数；`homeColumns` 在宽度至少 1220 时返回 4，至少 900 时返回 3，其余返回 2。

- [x] **Step 2: 让根框架、主壳与首页使用同一断点定义**

根框架与首页以 `LayoutBuilder` 的可用宽度判断，不读取物理屏幕像素。根框架负责是否展示桌面侧栏；侧栏扣除自身宽度后，主壳用 `MediaQuery.sizeOf(context).width` 判断应用窗口是否仍处于桌面模式；术数网格按内容区宽度切换 2/3/4 列。

## Task 2：建立浅色与深色语义主题

**Files:**
- Modify: `mobile/lib/core/theme/app_theme.dart`
- Modify: `mobile/lib/app.dart`

- [x] **Step 1: 保留现有 API 并更新语义色值**

保持 `AppColors`、`AppColorsLight`、`AppClr` 的类名、字段名及 `AppClr.of(context)` 用法不变。背景/表面/文字/强调色按下表更新；五行色与断语等级色维持原有语义，不用点缀色覆盖它们。

| 角色 | 深色 | 浅色 |
|------|------|------|
| 页面 | `#171C19` | `#F0EEE5` |
| 面板 | `#1D241F` | `#FAF9F4` |
| 卡片 | `#252C26` | `#FFFEFA` |
| 主文字 | `#E8E5DA` | `#282923` |
| 正文 | `#C3C4B8` | `#55574F` |
| 次级文字 | `#9DA598` | `#70736A` |
| 玉色强调 | `#9CAA8E` | `#5E7465` |
| 铜色强调 | `#A88D64` | `#96784F` |

- [x] **Step 2: 暴露玉色语义并调整全局字体与 Material 表面**

在 `AppColors`、`AppColorsLight` 与 `AppClr` 中新增 `jade` 语义色，现有 `gold` 字段映射到表内的温铜色。取消 `ThemeData.fontFamily` 对所有文本强制使用思源宋体；保持 `AppFonts.serif` 供品牌和术数标题显式使用。设置适配深浅主题的页面底色、`ColorScheme`、卡片表面、输入边框、焦点态和选中态。现有图表与五行颜色属性继续可用。

- [x] **Step 3: 移除根级星空底图**

在 `JeenithApp` 的 `MaterialApp.router` 外层使用纯色页面底层，不再全局绘制 `Starfield`。不删除 `starfield.dart`，以免影响仍显式使用该装饰的页面。

## Task 3：按屏幕空间设置 Windows 窗口

**Files:**
- Modify: `mobile/lib/main.dart`

- [x] **Step 1: 删除手机比例约束**

移除 `_kPhoneAspect` 与按屏幕高度推算 9:19.6 宽度的逻辑。以 `Display.visibleSize` 为逻辑像素基准，在可用屏幕范围内计算初始宽高，目标比例约 1.45:1；宽度不超过 1440、高度不超过 960，四周保留至少 24 逻辑像素边距。最小窗口尺寸不得超过当前显示器可容纳的尺寸。

- [x] **Step 2: 检查平台边界**

Android 启动路径不调用 `windowManager`；Windows 继续调用现有 `ensureInitialized`、`waitUntilReadyToShow` 和 `show`。

## Task 4：添加全路由桌面侧栏并精简移动导航

**Files:**
- Modify: `mobile/lib/app.dart`
- Create: `mobile/lib/shared/widgets/app_desktop_navigation.dart`
- Modify: `mobile/lib/shared/widgets/main_shell.dart`

- [x] **Step 1: 保留三个 go_router 分支与状态**

维持 `StatefulNavigationShell.goBranch` 和当前索引重选时回到初始页的行为，分支顺序仍为卜算、解卦、档案。

- [x] **Step 2: 用 MaterialApp 根布局承载桌面侧栏**

在 `MaterialApp.router.builder` 内以根级 `LayoutBuilder` 判断应用窗口宽度。桌面模式使用 `Row(侧栏, Expanded(当前路由))`，因此技术页、历史、手册和设置等顶层路由切换时侧栏仍在。侧栏通过已存在的 `GoRouter` 导航到 `/`、`/jiekua`、`/profiles`、`/history`、`/manual` 和 `/settings`，不改路由层级。

- [x] **Step 3: 狭屏保留触控底栏**

宽度低于 960 时展示带安全区的底部导航，图标、标签、选中状态完整可见；解卦入口改为与其它入口同尺寸的语义按钮，不再持续呼吸发光或凸起遮挡内容。桌面窗口中不重复绘制底栏。

- [x] **Step 4: 设计侧栏层级与选中态**

侧栏宽 224 逻辑像素，显示产品名、三个主分支以及历史、手册和设置入口。选中态同时区分图标、文字和表面，并提供键盘焦点反馈。路由属于某主分支时标记该分支；其它页面不虚构主分支选中状态。

## Task 5：首页分别组织移动端与桌面端信息

**Files:**
- Modify: `mobile/lib/features/home/home_page.dart`

- [x] **Step 1: 保留现有术数注册表和入场状态**

卡片继续来自 `visibleTechsProvider`；保留已有 `_onTapTech` 仪式路由和退出动画，不在首页硬编码术数列表。

- [x] **Step 2: 建立桌面首页组合**

宽屏采用左侧品牌与说明、右侧快捷操作的横向头部；内容居中并受 `contentMaxWidth` 限制；术数卡片按 3 或 4 列显示，桌面卡片改为横向可读比例。

- [x] **Step 3: 保持移动端单列引导与两列术数卡片**

窄屏保留纵向品牌区、使用说明折叠卡片与 2 列触控卡片；设置/历史/手册入口可触达，不把桌面侧栏压缩到移动端。

- [x] **Step 4: 检查两种主题的完整页面状态**

分别在浅色与深色检查首页、桌面侧栏、卡片、正文、输入控件和五行图表；若新语义色让重要信息对比不足，只调整对应语义色，不以全局高饱和光效补救。

## 验收

- `cd mobile; flutter analyze` 无新增分析错误。
- `cd mobile; flutter test` 现有测试全部通过。
- Windows 初始窗口呈桌面横向比例，缩窄后侧栏/底栏切换稳定；Android 始终使用移动端底栏。
- 浅色与深色主题共享相同结构，主要页面文字、焦点和选中态均能辨识。
- 术数注册、路由、主题切换和动效总开关未退化。
