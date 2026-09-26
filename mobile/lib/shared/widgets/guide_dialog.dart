// Copyright (c) 2026 Qore
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 使用方法弹窗。
///
/// 进入首页后首次弹出（由调用方用 SharedPreferences 控制只弹一次）。
/// 开启后 3 秒内「我知道了」按钮禁用并显示倒计时，3 秒后可关闭。
///
/// v2.3.1：升级入场动画（Phase 5）——背景 BackdropFilter 模糊渐入 +
/// 卡片从中心 scale 0.85→1.0 + easeOutBack 弹回（280ms）。
/// v2.4.4：全面主题感知（AppClr 浅色适配）。
class GuideDialog extends StatefulWidget {
  final int countdownSec;
  const GuideDialog({super.key, this.countdownSec = 3});

  @override
  State<GuideDialog> createState() => _GuideDialogState();
}

class _GuideDialogState extends State<GuideDialog>
    with SingleTickerProviderStateMixin {
  late int _count = widget.countdownSec;
  Timer? _t;
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _count--);
      if (_count <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    final ready = _count <= 0;
    // 入场曲线：easeOutBack（带回弹）
    final enterCurve = CurvedAnimation(
      parent: _enter,
      curve: Curves.easeOutBack,
    );
    return PopScope(
      canPop: ready, // 3 秒内禁止系统返回键关闭
      child: AnimatedBuilder(
        animation: _enter,
        builder: (context, _) {
          // 背景模糊与暗化（同步渐入）
          final blurT = Curves.easeOutCubic.transform(_enter.value);
          return BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5 * blurT,
              sigmaY: 5 * blurT,
            ),
            child: Container(
              color: AppColors.shadow.withValues(alpha: 0.4 * blurT),
              child: Center(
                child: Transform.scale(
                  scale: 0.85 + 0.15 * enterCurve.value,
                  child: Opacity(
                    opacity: _enter.value.clamp(0.0, 1.0),
                    child: AlertDialog(
                      backgroundColor: c.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.panel),
                        side: BorderSide(color: c.goldBorder),
                      ),
                      title: Row(
                        children: [
                          Icon(Icons.menu_book,
                              color: c.goldBright, size: 20),
                          const SizedBox(width: 8),
                          Text('使用方法',
                              style: TextStyle(
                                  color: c.goldBright,
                                  fontSize: AppFontSize.title,
                                  fontWeight: AppFontWeight.bold,
                                  letterSpacing: AppLetterSpacing.label)),
                        ],
                      ),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _GuideItem(
                              num: '1',
                              title: '单一卜算术起卦',
                              body: '第一次问大致的问题，第二次问细致的问题。',
                            ),
                            const SizedBox(height: 12),
                            _GuideItem(
                              num: '2',
                              title: '多卜算术组合使用',
                              body: '先用一种卜算术起卦问大致的问题，再用另外一种起卦问细节上的问题。',
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '3. 可以将卦象的完整截图和问题一并发送给 AI，也可以自己查资料。',
                              style: TextStyle(
                                  color: c.textBody,
                                  fontSize: AppFontSize.bodySmall,
                                  height: AppLineHeight.reading),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '4. 点击起卦按钮前，心里默念问题，集中注意力，注意力达到顶点的一刹那起卦。',
                              style: TextStyle(
                                  color: c.textBody,
                                  fontSize: AppFontSize.bodySmall,
                                  height: AppLineHeight.reading),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: ready
                              ? () => Navigator.of(context).pop()
                              : null,
                          child: Text(
                            ready ? '我知道了' : '$_count s 后可关闭',
                            style: TextStyle(
                              color: ready ? c.gold : c.textHint,
                              fontWeight:
                                  ready ? AppFontWeight.bold : AppFontWeight.regular,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  final String num;
  final String title;
  final String body;
  const _GuideItem({required this.num, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$num. $title',
            style: TextStyle(
                color: c.goldBright,
                fontSize: AppFontSize.body,
                fontWeight: AppFontWeight.bold)),
        const SizedBox(height: 2),
        Text(body,
            style: TextStyle(color: c.textBody, fontSize: AppFontSize.bodySmall, height: AppLineHeight.reading)),
      ],
    );
  }
}
