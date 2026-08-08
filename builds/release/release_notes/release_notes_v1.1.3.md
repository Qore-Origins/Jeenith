## 本次内容

### 桌面端窗口尺寸修复
- 修复 `screen_retriever` 逻辑像素误除 dpr 导致窗口过小（1080p 下窗口仅 299×651，正确应为 477×1040）
- 窗口最小尺寸调整，让目标宽度生效，避免 `minimumSize` 反向拉宽窗口
- `main.cpp` 初始尺寸 460×900 → 540×1040，减少启动闪现
- 首页卡片紧凑化，防御性修复窄窗口下 Column overflow

### 全面代码质量审计与安全性修复
- **Android 签名安全**：新增 `key.properties` 读取机制，release 构建不再误用 debug 签名
- **真随机覆盖**：梅花易数 `_onRandom` 改用 `divineRandom()` 走真随机引擎，替换此前的时间戳模运算伪随机
- **HistoryStore 并发安全**：新增串行化锁，`add`/`updateNote`/`remove` 不再有 `load→modify→save` 竞态；新增 `generateId()` 统一 ID 生成
- **ConfigNotifier 空安全**：修复加载期 `state = AsyncData(state.valueOrNull!.copyWith(...))` 崩溃
- **输入校验**：小六壬 `int.parse` 攻防（超长数字串崩溃）、紫微/奇门日期月份上界校验、小六壬动画 Interval clamp

### 性能优化
- **Starfield 星空背景**：新增 `WidgetsBindingObserver` 生命周期监听，窗口不可见时暂停动画；动画时长 14s → 30s 降低帧率
- **CustomPainter 内存泄漏**：3 处 `TextPainter` 补 `dispose()`（小六壬圆盘、卦象、仪式页）

### 死代码清理与可维护性
- 删除 `DivinationTech.usesTrueRandom` 死代码（2 处声明，0 消费）
- 删除 `PlatformInfo.hasTouch` 死代码
- `DivinationRegistry` 新增重复 ID 断言校验
- `random.org` 响应格式严格校验（6 行数字，拒绝从 HTML 误提取）

### 用户体验
- 历史记录页新增「清空全部」入口（AppBar 侧边按钮 + 确认弹窗）
- 历史记录页已记录 ID 统一迁移使用 `HistoryStore.generateId()`

### 其他
- 版本 1.1.2+6 → 1.1.3+7

## 下载

| 平台 | 文件 | 大小 | SHA-256 |
|------|------|------|---------|
| Android | Jeenith_1.1.3_fix_20260712_01.apk | 51.23 MB / 53723746 B | 2BB9DF3623088A34ADC1F855F34E8F4C44DA31BBD91F5034F927C42D8D8A37D7 |
| Windows x64 | Jeenith_1.1.3_fix_20260712_01_windows_x64.zip | 12.74 MB / 13354337 B | F1048AED292E8B90F6E7908ED95ADB34DB50A3E43954F395CFE5E15418842CD1 |