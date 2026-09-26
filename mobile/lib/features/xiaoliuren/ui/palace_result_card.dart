// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/divination/divination_result.dart';

/// 落宫结果卡（序号 + 宫名 + 五行六神 + 吉凶徽章 + 诗诀 + 含义 + 七维断辞）。
class PalaceResultCard extends StatelessWidget {
  final ResultCardData data;
  const PalaceResultCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.panelCompact),
        border: Border.all(color: c.goldBorder),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: c.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Text('第${data.order}宫',
                  style: TextStyle(
                      color: c.gold,
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Text(data.title,
                style: TextStyle(
                    color: data.accentColor,
                    fontSize: AppFontSize.metric,
                    fontWeight: AppFontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(data.subtitle ?? '',
                    style: TextStyle(
                        color: c.textMeta, fontSize: AppFontSize.caption),
                    overflow: TextOverflow.ellipsis)),
            if (data.badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(
                      color: data.badgeColor ?? c.gold, width: 0.8),
                ),
                child: Text(data.badge!,
                    style: TextStyle(
                        color: data.accentColor,
                        fontSize: AppFontSize.label,
                        fontWeight: AppFontWeight.bold)),
              ),
          ]),
          if (data.poem != null) ...[
            const SizedBox(height: 6),
            Text('「 ${data.poem} 」',
                style: TextStyle(
                    color: c.goldBright,
                    fontSize: AppFontSize.bodySmall,
                    fontStyle: AppFontStyle.italic)),
          ],
          if (data.meaning != null) ...[
            const SizedBox(height: 4),
            Text(data.meaning!,
                style:
                    TextStyle(color: c.textBody, fontSize: AppFontSize.label, height: AppLineHeight.body)),
          ],
          if (data.details != null && data.details!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: data.details!
                  .map((d) => _chip(d.label, d.content, c))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, String content, AppClr c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text('$label：$content',
          style: TextStyle(color: c.textMeta, fontSize: AppFontSize.caption)),
    );
  }
}
