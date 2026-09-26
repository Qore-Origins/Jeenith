---
title: 历史详情进入 AI 解读时弹窗控制器提前释放
severity: medium
status: resolved
created: 2026-09-26 16:46:33
tags: [Flutter, Windows, history, AI, Navigator, lifecycle]
---

## 问题描述

从历史记录打开详情并点击“进入 AI 解读”时，出现 `TextEditingController was used after being disposed`，随后还可能触发根 Navigator、Overlay、LayoutBuilder 与 ProxyAnimation 断言，AI 页面无法正常打开。

## 复现步骤

1. 打开“历史记录”。
2. 打开任意历史条目。
3. 点击“进入 AI 解读”。

## 根本原因

详情弹窗通过 `Navigator.pop` 关闭后，弹窗退出动画和 Overlay 清理仍在进行。原流程在弹窗刚开始退出时就释放备注输入框的 `TextEditingController`，并立即切换 GoRouter 页面。弹窗退出帧仍访问已释放控制器，同时根路由开始切换，导致 controller、Navigator 与 route animation 错误连续发生。

## 解决方案

- 在详情弹窗 builder 中保存 `ModalRoute`。
- 关闭弹窗后等待 `ModalRoute.completed`，确认退出动画和 Overlay entry 清理完成。
- 然后释放备注控制器；如需进入 AI，再将选中的历史条目传给 AI 路由。
- 删除或保存备注后，也在转场完成后刷新历史列表。

```dart
ModalRoute<dynamic>? detailRoute;
await showDialog<void>(
  context: context,
  builder: (dialogContext) {
    detailRoute = ModalRoute.of<dynamic>(dialogContext);
    return dialog;
  },
);
await detailRoute?.completed;
noteController.dispose();
if (!mounted) return;
// 此处再执行刷新或路由切换。
```

## 验证方式

- `flutter analyze --no-pub`：通过，无静态分析问题。
- 用户交互复测：从历史详情进入 AI 解读不再报错。

## 环境信息

- Windows 桌面端，Flutter 项目 `D:\Code\Project\Qore\Jeenith\mobile`
- 发生位置：历史记录详情弹窗到 `/jiekua` 的路由切换
