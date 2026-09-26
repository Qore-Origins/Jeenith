---
title: 桌面标题栏 Tooltip 找不到 Overlay
severity: low
status: resolved
created: 2026-09-26 16:46:34
tags: [Flutter, Windows, desktop, Tooltip, Overlay]
---

## 问题描述

Windows 自定义标题栏的最小化、最大化和关闭控件显示红黄 `No Overlay` 异常提示。

## 复现步骤

1. 启动 Windows 桌面版。
2. 将鼠标悬停在自定义标题栏窗口控件上。

## 根本原因

标题栏由 `MaterialApp.router.builder` 放在 Navigator 路由内容之外。窗口控件使用 `IconButton.tooltip`，Tooltip 在构建提示层时需要找到 Overlay；该标题栏所在子树没有路由 Overlay，因此触发 `debugCheckHasOverlay`。

## 解决方案

移除标题栏控件上的 Tooltip，改用 `Semantics(label: ..., button: true)` 提供无障碍名称，并用 `Material`、`InkWell` 实现点击和悬停反馈。需要视觉提示时，将 Tooltip 放入 Overlay 下方的路由内容中。

## 验证方式

- `flutter analyze --no-pub`：通过，无静态分析问题。
- 用户重启最新版后确认：顶部红黄 `No Overlay` 提示已消失。

## 环境信息

- Windows 桌面端，Flutter 项目 `D:\Code\Project\Qore\Jeenith\mobile`
- 发生位置：自定义桌面标题栏，位于 Navigator Overlay 外层
