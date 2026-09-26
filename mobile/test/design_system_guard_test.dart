import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UI source uses the centralized visual tokens', () {
    final violations = <String>[];
    final sourceFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in sourceFiles) {
      final path = file.path.replaceAll('\\', '/');
      if (path.endsWith('/core/theme/app_theme.dart') ||
          path.endsWith('/core/theme/design_tokens.dart')) {
        continue;
      }

      final source = file.readAsStringSync();
      _report(
        violations,
        path,
        source,
        RegExp(r'\b(?:const\s+)?Color\s*\(\s*0x[0-9a-fA-F]+'),
        'use an AppColors or AppClr token instead of a color literal',
      );
      _report(
        violations,
        path,
        source,
        RegExp(r'\bColor\.from(?:ARGB|RGBO)\s*\('),
        'define color construction in the central palette',
      );
      _report(
        violations,
        path,
        source,
        RegExp(r'(?:^|[^A-Za-z])Colors\.[A-Za-z_]'),
        'use an AppColors or AppClr semantic color token',
      );
      _report(
        violations,
        path,
        source,
        RegExp(r'fontSize\s*:\s*\d+(?:\.\d+)?\b'),
        'use a named AppFontSize token',
      );
      _report(
        violations,
        path,
        source,
        RegExp(r'letterSpacing\s*:\s*\d+(?:\.\d+)?\b'),
        'use a named AppLetterSpacing token or its shared responsive helper',
      );
      _report(
        violations,
        path,
        source,
        RegExp(r'height\s*:\s*\d+\.\d+\b'),
        'use a named AppLineHeight token for text line height',
      );
      _report(
        violations,
        path,
        source,
        RegExp(r"""fontFamily\s*:\s*['"]"""),
        'use an AppFonts token',
      );
      _report(
        violations,
        path,
        source,
        RegExp(r'(?:^|[^A-Za-z])FontWeight\.[A-Za-z_]'),
        'use an AppFontWeight token',
      );
      _report(
        violations,
        path,
        source,
        RegExp(r'(?:^|[^A-Za-z])FontStyle\.[A-Za-z_]'),
        'use an AppFontStyle token',
      );
      _report(
        violations,
        path,
        source,
        RegExp(r'(?:BorderRadius|Radius)\.circular\(\s*\d'),
        'use a named AppRadius token',
      );
      _report(
        violations,
        path,
        source,
        RegExp(r'(?:Filled|Outlined|Text)Button\.styleFrom\s*\('),
        'use AppButtonStyles or the app-wide button theme',
      );
      _report(
        violations,
        path,
        source,
        RegExp(r'(?:^|[^A-Za-z])ButtonStyle\s*\('),
        'use the shared button style factory',
      );
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}

void _report(
  List<String> violations,
  String path,
  String source,
  RegExp pattern,
  String guidance,
) {
  for (final match in pattern.allMatches(source)) {
    final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
    violations.add('$path:$line ${match.group(0)} — $guidance');
  }
}
