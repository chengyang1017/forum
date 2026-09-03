import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cleaned presentation screens do not hardcode Chinese UI strings', () {
    const paths = <String>[
      'lib/features/translation/presentation/screens/post_translation_screen.dart',
      'lib/features/profile/presentation/screens/user_profile_screen.dart',
      'lib/features/notes/presentation/screens/all_notes_screen.dart',
      'lib/features/notes/presentation/screens/note_editor_screen.dart',
    ];
    final chineseLiteral = RegExp(
      r'''['"][^'"\n]*[\u3400-\u9fff][^'"\n]*['"]''',
    );
    final violations = <String>[];

    for (final path in paths) {
      final lines = File(path).readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (line.contains('debugPrint')) {
          continue;
        }
        if (chineseLiteral.hasMatch(line)) {
          violations.add('$path:${index + 1}: ${line.trim()}');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
