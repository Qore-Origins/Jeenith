// Copyright (c) 2026 Qore
import 'dart:convert';

import 'package:http/http.dart' as http;

/// 一条对话消息（role: system / user / assistant）。
class GlmMessage {
  final String role;
  final String content;
  const GlmMessage(this.role, this.content);

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// GLM-4-Flash 大模型客户端（v3.0.0 解卦；v3.1.0 加多轮对话）。
///
/// 智谱 AI openai 兼容接口，免费模型 `glm-4-flash`。key 由用户在设置页填入。
class GlmClient {
  static const _endpoint =
      'https://open.bigmodel.cn/api/paas/v4/chat/completions';

  /// 默认系统提示：区分 app 计算结果、模型推断与方法建议。
  static const defaultSystemPrompt =
      '你是 Jeenith 中的传统术数与问题梳理助理，使用中文回答，表达清楚、克制。'
      '应用只会提供当前用户问题以及用户在本次发送前明确勾选的本地上下文。'
      '没有提供应用计算结果时，不得声称已经起卦、排盘或得到任何计算结果；可以提出澄清问题，或在用户提供应用术数目录时从目录中推荐最多三种方法，说明理由、所需输入和局限，并请用户自行选择后回到应用计算。'
      '提供计算结果时，把其中明确写出的计算事实与模型解释分开；解释要说明依据和不确定性，不把推断包装成事实。'
      '只可引用用户本次实际提供的原文或资料；未提供来源时明确说明没有附带来源，不得编造古籍、篇章、原文或出处。'
      '可以用 Markdown 标题和列表帮助阅读；给出可执行但不过度确定的思考建议，不替用户作重大人生或财务决定。';

  /// 多轮对话：[messages] 为 user/assistant 历史对话（不含 system，内部自动前置系统提示）。
  static Future<String> chat({
    required List<GlmMessage> messages,
    required String apiKey,
    String? systemPrompt,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('未配置 GLM API key，请在设置页填写');
    }
    final all = <Map<String, dynamic>>[
      GlmMessage('system', systemPrompt ?? defaultSystemPrompt).toJson(),
      ...messages.map((m) => m.toJson()),
    ];

    final resp = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'glm-4-flash',
            'messages': all,
            'stream': false,
            'temperature': 0.7,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (resp.statusCode != 200) {
      throw Exception(
          'GLM 请求失败（${resp.statusCode}），请检查网络或 API 配置后重试');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('GLM 返回为空');
    }
    final msg = (choices[0] as Map<String, dynamic>)['message'];
    return msg['content'] as String;
  }

  /// 流式对话（SSE）：逐段 yield 内容片段，用于打字机式实时输出（v3.1.4）。
  ///
  /// 用 [http.Client.send] 拿到 [StreamedResponse]，按行解析 `data: {...}`，
  /// 提取 `choices[0].delta.content` 增量。遇 `[DONE]` 结束。
  static Stream<String> chatStream({
    required List<GlmMessage> messages,
    required String apiKey,
    String? systemPrompt,
  }) async* {
    if (apiKey.trim().isEmpty) {
      throw Exception('未配置 GLM API key，请在设置页填写');
    }
    final all = <Map<String, dynamic>>[
      GlmMessage('system', systemPrompt ?? defaultSystemPrompt).toJson(),
      ...messages.map((m) => m.toJson()),
    ];
    final req = http.Request('POST', Uri.parse(_endpoint))
      ..headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      })
      ..body = jsonEncode({
        'model': 'glm-4-flash',
        'messages': all,
        'stream': true,
        'temperature': 0.7,
      });
    final client = http.Client();
    try {
      final resp = await client.send(req);
      if (resp.statusCode != 200) {
        await resp.stream.drain<void>();
        throw Exception(
            'GLM 请求失败（${resp.statusCode}），请检查网络或 API 配置后重试');
      }
      await for (final line in resp.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!line.startsWith('data:')) continue;
        final data = line.substring(5).trim();
        if (data.isEmpty || data == '[DONE]') continue;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List?;
          if (choices == null || choices.isEmpty) continue;
          final delta = (choices[0] as Map)['delta'] as Map?;
          final content = delta?['content'];
          if (content is String && content.isNotEmpty) yield content;
        } catch (_) {
          // 跳过无法解析的行
        }
      }
    } finally {
      client.close();
    }
  }

  /// 单次解读（便捷，内部走 [chat]）。保留向后兼容。
  static Future<String> interpret({
    required String question,
    required String hexuanText,
    required String apiKey,
  }) =>
      chat(
        apiKey: apiKey,
        messages: [
          GlmMessage('user', '我想问：$question\n\n卦象 / 卜算结果：\n$hexuanText')
        ],
      );
}
