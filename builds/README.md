# builds 目录结构规范（release / packages 分离）

> 从 v3.1.4 起实施。原因：项目开始发布 GitHub Packages（Android AAR / Windows 包），
> 构建产物不能再只放在扁平目录——release（正式分发版）与 packages（包管理器分发版）必须分离。

## 结构

```
builds/
├── release/                    # 正式分发产物（人工/渠道分发：APK、zip）
│   ├── android/                #   APK：Jeenith_{版本}_{状态}_{日期}_{序号}.apk
│   ├── windows/                #   zip：Jeenith_{版本}_{状态}_{日期}_{序号}_windows_x64.zip
│   ├── release_notes/          #   release_notes_v{版本}.md（GitHub Release notes 正文）
│   ├── build_history.json      #   构建记录（含 sha256 / 源路径 / 产物路径）
│   └── release_history.json    #   发布记录（tag / assets / notesFile / published）
└── packages/                   # 包管理器分发产物（GitHub Packages 等，包跨端→按生态划分）
    ├── npm/                    #   .tgz（跨端：JS/TS 共享代码，不分平台）
    ├── maven/                  #   .aar/.jar + pom（Android 组件坐标）
    ├── nuget/                  #   .nupkg（.NET/Windows 组件）
    └── release_notes/          #   包版本说明
```

## 约定

- **release/**：人工或渠道下载的正式产物，命名遵循 `{程序名}_{版本}_{状态}_{构建日期}_{构建序号}`，入库记录于 build_history.json / release_history.json（**路径一律写 release/ 前缀**）
- **packages/**：推送 GitHub Packages 的产物（npm tgz / maven aar / nuget nupkg），由 CI 或发布脚本生成；**包是跨端的，按包生态划分而非平台**；每个包版本对应 packages/release_notes/ 下说明
- 产物（apk/zip/tgz/aar/nupkg）**不入库**（见 .gitignore）；入库的只有记录 json、release_notes、README
- 历史记录更新：build 完成后更新 build_history.json；发布后更新 release_history.json（status → published + 回填 url）

## 命名对照

| 分发 | 平台/生态 | 产物 |
|------|-----------|------|
| release | Android | `Jeenith_{ver}_{status}_{date}_{seq}.apk` |
| release | Windows | `Jeenith_{ver}_{status}_{date}_{seq}_windows_x64.zip` |
| packages | npm（跨端） | `jeenith-{ver}.tgz` |
| packages | Maven（Android 组件） | `com.heysnowe.jeenith:{ver}`（AAR） |
| packages | NuGet（.NET） | `Jeenith.{ver}`（.nupkg） |
