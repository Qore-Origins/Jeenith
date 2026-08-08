## 本次内容

### Windows 桌面端适配
- 新增 PlatformInfo 设备检测，按 mobile/desktop/web 切换交互与布局
- 触摸轨迹改鼠标轨迹：TouchTracker 增 onPointerHover，修复桌面端轨迹采集为空
- 周易 / 小六壬桌面端弃用 DraggableScrollableSheet（鼠标拖拽不灵），改 Column 上下分栏，修复 _PinHeaderDelegate 区「向上滑不动 / 可滑动距离过小」

### Android 真机修复
- AndroidManifest 补 INTERNET 权限：release 包此前访问 random.org 全部失败（debug/profile manifest 自带权限仅服务开发工具，release 只合并 main）
- online_entropy_source 校验 HTTP 状态码，超时 3s → 6s

### 其他
- xiaoliuren_tech.dart import 路径修正
- 版本 1.1.0+4 → 1.1.2+6

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_1.1.2_fix_20260712_01.apk | 50.97 MB / 53445038 B | 24D681E9045DFEC3CF753A81AA6E5E29A60061EEE05404BB5F63CCE4EFB35FB8 |
| Windows x64 | Jeenith_1.1.2_fix_20260712_01_windows_x64.zip | 12.61 MB / 13226117 B | B37D90090C7409EF07388EAA50FCC11E206F6E3F5A1EDAE570E30E9E5FD6334C |
