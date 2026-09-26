# AGENTS.md — 志极 Jeenith

> 与 CLAUDE.md 同步。身份信息以 `D:\Code\.Rules\OrganizationAndUser.md` 为准。

## 项目

- 中文名/英文名：志极 / Jeenith
- 组织：Qore（叩心）· 包名 `com.qore.jeenith`
- 类型：Flutter 移动 App（Android + Windows 桌面）
- 定位：卜算合集（小六壬/周易/梅花/掷筊/紫微/奇门/抽签/测字/大六壬/风水罗盘）+ 使用手册，可扩展框架
- 当前版本：3.2.0+54（release，2026-09-26）
- 位置：`D:\Code\Project\Qore\Jeenith`

## 结构

`mobile/`（Flutter）+ `backend/`（占位）+ `design/`（占位）+ `docs/` + `tools/`（占位）+ `builds/`（归档）。mobile/lib：app.dart + core/ + data/ + features/ + providers/ + router/ + shared/。features/ 当前：home / xiaoliuren / zhouyi / meihua / jiaobei / ziwei / qimen / taiyi / daliuren / liuyao / chouqian / cezi / chenggu / luopan / bazi / name_test / manual / settings / history。

## 构建

```bash
cd mobile
flutter pub get && flutter analyze
pwsh -File scripts/build_apk.ps1 -Status release
```

## 技术栈速览

Flutter 3.x（Dart 3.11+）· Riverpod · go_router · lunar（寿星天文历）· flutter_svg · shared_preferences · sensors_plus（陀螺仪/磁场，风水罗盘）· share_plus（结果分享）· path_provider（历史导出）· dart:math Random.secure + 触摸轨迹 + random.org（真随机引擎）。

## 规则

- 先看再改
- 身份信息不硬编码（以 OrganizationAndUser.md 为准）
- 加新卜算术 = 新建 features/xxx/ + 实现 DivinationTech + registry 注册
- 微交互动画统一封装在 core/theme/animations.dart，所有动效可通过设置页全局开关（AppConfig.animationsEnabled）
- 视觉规范统一从 mobile/lib/core/theme/app_theme.dart 与 design_tokens.dart 调用；页面不得直接写颜色、字体/字重/字号、行高/字距、数值圆角或按钮样式，新增视觉值先补语义令牌/组件工厂并更新 design_system_guard_test.dart
- CustomPainter 实现必须显式 dispose TextPainter，防止 native handle 泄漏
- 构建归档规范见 docs/FLUTTER_APK_BUILD_PIPELINE.md
