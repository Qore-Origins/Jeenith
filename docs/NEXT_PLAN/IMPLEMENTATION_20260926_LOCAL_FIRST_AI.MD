# Jeenith 本地优先 AI 助理实施计划

> **执行方式**：在 `codex/ai-adaptive-ui` 隔离分支内逐项实施；本计划只处理问题入口、每次请求的上下文授权和本地案例记忆。术数来源库及完整备份仍是产品待办，不能由模型虚构填补。

**目标**：让用户无需先有卦象即可向 AI 描述问题，同时让每一次模型请求都清楚展示问题与可选本地上下文；解卦会话和用户笔记留在设备上。

**架构**：用纯 Dart 请求构造器把用户问题与用户勾选的资料组合，显式授权组件展示即将发送的精确内容；网络层只接收构造好的消息，不自行读取档案或历史。现有 GLM 接口继续使用。历史会话通过兼容旧 JSON 的本地模型保存。

**技术栈**：Flutter、Riverpod、现有 `ProfileStore`/`HistoryStore`/`JiekuaStore`、现有 GLM HTTP 客户端；不新增依赖。

---

## 文件职责

- `mobile/lib/core/ai/ai_request_context.dart`：逐次授权选择与纯 Dart 请求消息构造。
- `mobile/lib/shared/widgets/ai_context_consent.dart`：移动端底部面板、桌面端对话框；列出将随请求发送的内容。
- `mobile/lib/core/ai/jiekua_store.dart`：给既有本地会话增加可选笔记字段，并读取旧数据。
- `mobile/lib/core/ai/glm_client.dart`：调整系统指令，阻止模型伪称已计算卦象或虚构来源。
- `mobile/lib/features/jiekua/ui/jiekua_page.dart`：问题优先入口、结果关联、笔记、逐次授权和本地会话。
- `mobile/lib/router/app_router.dart`：让历史记录页可将明确选中的 `HistoryEntry` 交给 AI 页。
- `mobile/lib/features/history/history_page.dart`：结果详情增加直接进入 AI 解读的操作。
- `mobile/test/ai_request_context_test.dart`：验证未勾选的个人上下文不会进入模型消息。

## Task 1：定义逐次授权请求构造器

**Files:**
- Create: `mobile/lib/core/ai/ai_request_context.dart`
- Create: `mobile/test/ai_request_context_test.dart`

- [x] **Step 1: 写出未选上下文隔离测试**

构造问题、结果、历史对话、笔记、档案和术数目录，选择保持默认空值；断言返回消息只含当前问题，序列化消息中不存在任何未授权文本。

- [x] **Step 2: 写出已选内容进入对应上下文的测试**

分别勾选结果、对话、笔记、档案和术数目录，断言仅这些内容被加入消息；当前问题始终是最后一条 user 消息，历史 assistant 消息保持原 role 和顺序。

- [x] **Step 3: 实现不可变选择与构造器**

新增 `AiRequestSelection`，字段为 `includeResult`、`includeConversation`、`includeCaseNote`、`includeTechniqueCatalog` 和 `profileIds`；所有布尔值默认 `false`，集合默认空。新增 `AiRequestContextBuilder.buildMessages(...)`，只读取已选字段。历史对话仅在勾选时按原角色逐条追加在前；已勾选的结果、笔记、档案与目录清楚标注并合并到最终 user 消息，当前问题始终位于该消息末尾。

- [x] **Step 4: 运行请求上下文测试**

运行 `flutter test --no-pub test/ai_request_context_test.dart`；默认选择下必须没有结果、对话、笔记、档案或目录内容。

## Task 2：实现每次发送前的授权预览

**Files:**
- Create: `mobile/lib/shared/widgets/ai_context_consent.dart`
- Modify: `mobile/lib/core/layout/app_breakpoints.dart`

- [x] **Step 1: 建立显式选择组件**

新增 `showAiContextConsent(...)`，输入当前问题、可选计算结果、历史消息、案例笔记、档案列表和内置术数目录，返回 `AiRequestSelection?`。所有可选上下文默认未勾选；问题内容固定显示但不能隐藏。

- [x] **Step 2: 按端侧展示授权界面**

应用窗口宽度低于 `desktopNavigation` 时显示可滚动的底部面板；桌面宽度显示最大宽度 620 逻辑像素的对话框。档案列表逐条展示姓名、出生信息、性别和备注；选中即表示本次发送这些字段。计算结果、笔记、历史对话和术数目录各自独立勾选。

- [x] **Step 3: 提供准确预览与取消路径**

展示用户当前问题全文；每个勾选项可展开查看将发送的全文。取消、关闭或返回均返回 `null`；只有点击「发送所选内容」才返回选择对象。界面说明授权只针对本次请求。

## Task 3：把会话笔记纳入本地记忆

**Files:**
- Modify: `mobile/lib/core/ai/jiekua_store.dart`
- Modify: `mobile/lib/features/jiekua/ui/jiekua_page.dart`

- [x] **Step 1: 兼容扩展会话模型**

给 `JiekuaSession` 新增 `notes` 字符串，默认空；`toJson` 写入 `notes`，`fromJson` 用 `j['notes'] as String? ?? ''` 读取旧记录。`copyWith` 可更新 notes，原有字段与序列化结构保持兼容。

- [x] **Step 2: 增加本地案例笔记编辑**

会话页提供「本地笔记」操作，允许创建会话后编辑并立即写入 `JiekuaStore`。笔记不自动加入请求；必须在逐次授权面板勾选后才可发送。

## Task 4：开放问题优先 AI 流程并安全组装消息

**Files:**
- Modify: `mobile/lib/core/ai/glm_client.dart`
- Modify: `mobile/lib/features/jiekua/ui/jiekua_page.dart`

- [x] **Step 1: 支持没有术数结果的新问题**

移除「没有选择历史结果就禁止发送」的条件。无结果时创建本地通用会话，允许用户先澄清问题或请求方法建议；提供明确入口回到卜算页，由用户自行确认并计算。若选择已有结果，则保持当前结果显示。

- [x] **Step 2: 每次调用前先取得用户授权**

`_send` 在添加气泡、清空输入或打开网络请求之前调用授权面板。面板返回 `null` 时立即返回，输入和会话状态保持不变。确认后，调用 `AiRequestContextBuilder.buildMessages`；GLM 客户端不得直接读任何 store、档案或隐式对话缓存。

- [x] **Step 3: 明确模型边界与错误信息**

更新系统提示：无结果时只能澄清或建议目录内方法，不得声称已起卦；有结果时区分计算事实与模型推断；没有实际提供的原文时不得伪造古籍名、篇目、引文或出处。HTTP 错误只展示状态码与通用重试说明，不把服务端响应正文显示在界面。

- [x] **Step 4: 保存本地会话并处理失败状态**

确认授权后再记录 user 消息。成功响应和流式完成后将问题、回答、关联结果与笔记保存在 `JiekuaStore`。失败时去除空 assistant 占位、保留本地 user 问题并显示可重试的错误；失败不自动重发请求。

## Task 5：从历史结果直接进入 AI

**Files:**
- Modify: `mobile/lib/router/app_router.dart`
- Modify: `mobile/lib/features/history/history_page.dart`
- Modify: `mobile/lib/features/jiekua/ui/jiekua_page.dart`

- [x] **Step 1: 将明确选中的结果传到 AI 页面**

`/jiekua` 接收可选的 `HistoryEntry` route extra；未传 extra 时照常打开新问题流程。AI 页面将其设为本地待关联结果，但仍要求用户在本次授权面板显式勾选后才发送。

- [x] **Step 2: 在历史详情提供 AI 解读入口**

历史详情增加「进入 AI 解读」操作；点击后关闭详情并把当前 `HistoryEntry` 传入 `/jiekua`。不在 UI 中自动发送，也不改变直接恢复卦象的按钮。

## 验收

- `flutter analyze --no-pub` 无新增分析错误。
- `flutter test --no-pub` 全部测试通过。
- 新建空会话可直接提问；选择历史结果后可进入解读。
- 每次请求均先显示当前问题和上下文勾选项；默认不发送任何可选本地资料；取消授权时无网络请求、输入不丢失。
- 选中的结果、档案、笔记、历史对话和目录预览与实际消息一致；未选内容不出现在构造后的模型消息中。
- API key、个人档案、历史和笔记继续留在本地；只有本次明确勾选的内容进入模型请求。

## 验证记录

- `flutter analyze --no-pub`：通过，无分析问题。
- `flutter test --no-pub`：通过，33 项测试全部通过；包含默认不发送未选资料和旧会话笔记字段兼容测试。
- `flutter build windows --debug --no-pub`：通过。
- `flutter build apk --debug --no-pub`：未通过。用户级 Gradle 初始化脚本向 Flutter included build 注入仓库，与 Flutter SDK 的 `FAIL_ON_PROJECT_REPOS` 冲突；项目 Gradle 配置与基线一致。该环境问题已记入 `D:\Code\.Rules\ERROR`，未改动全局 Gradle 配置。
