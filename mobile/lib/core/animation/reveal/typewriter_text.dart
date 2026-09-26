// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';

/// 打字机文本动画组件。
///
/// 逐字显示文本，每字间隔 [speed]（默认 35ms）。
/// 用于结果揭示动画中的断辞、签诗等。
///
/// 用法：
/// ```dart
/// TypewriterText(
///   '大安：万物初始，安定祥和。',
///   style: TextStyle(color: AppColors.goldBright, fontSize: AppFontSize.bodyLarge),
///   speed: Duration(milliseconds: 35),
/// )
/// ```
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration speed;
  final TextAlign textAlign;
  final bool autoStart;
  final VoidCallback? onComplete;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.speed = const Duration(milliseconds: 35),
    this.textAlign = TextAlign.left,
    this.autoStart = true,
    this.onComplete,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<int> _charCount;
  late final Animation<double> _blink;

  @override
  void initState() {
    super.initState();
    final totalMs = widget.text.length * widget.speed.inMilliseconds;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs.clamp(200, 4000)),
    );
    _charCount = StepTween(
      begin: 0,
      end: widget.text.length,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _blink = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    if (widget.autoStart) {
      _ctrl.forward().then((_) => widget.onComplete?.call());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _charCount,
      builder: (context, _) {
        final n = _charCount.value;
        final shown = widget.text.substring(0, n);
        final isTyping = n < widget.text.length;
        return RichText(
          textAlign: widget.textAlign,
          text: TextSpan(
            text: shown,
            style: widget.style,
            children: [
              if (isTyping)
                WidgetSpan(
                  child: Opacity(
                    opacity: (_blink.value * 2) % 1,
                    child: Text('▎', style: widget.style),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 段落错峰淡入上浮组件。
///
/// 子组件按顺序错峰淡入上浮，每段间隔 [stagger]ms。
/// 用于结果揭示动画中的多段落断辞。
class StaggeredReveal extends StatefulWidget {
  final List<Widget> children;
  final Duration stagger;
  final Duration itemDuration;
  final double slideDistance;

  const StaggeredReveal({
    super.key,
    required this.children,
    this.stagger = const Duration(milliseconds: 200),
    this.itemDuration = const Duration(milliseconds: 500),
    this.slideDistance = 16,
  });

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    final totalMs = (widget.children.length - 1) * widget.stagger.inMilliseconds +
        widget.itemDuration.inMilliseconds;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < widget.children.length; i++) ...[
              _buildItem(i),
              if (i < widget.children.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  Widget _buildItem(int index) {
    final begin = index * widget.stagger.inMilliseconds /
        _ctrl.duration!.inMilliseconds;
    final end = (begin + widget.itemDuration.inMilliseconds /
        _ctrl.duration!.inMilliseconds).clamp(0.0, 1.0);
    final interval = Interval(begin, end, curve: Curves.easeOutCubic);
    final t = interval.transform(_ctrl.value);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, widget.slideDistance * (1 - t)),
        child: widget.children[index],
      ),
    );
  }
}
