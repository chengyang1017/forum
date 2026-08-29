import 'package:flutter_test/flutter_test.dart';

import 'package:glyphora_mobile/features/language/data/forum_languages.dart';

void main() {
  group('ForumLanguages', () {
    test('creates separate Vietnamese script channels', () {
      final vietnameseChannels = ForumLanguages.channels
          .where((channel) => channel.languageCode == 'vi')
          .toList(growable: false);

      expect(vietnameseChannels, hasLength(2));
      expect(
        vietnameseChannels.map((channel) => channel.scriptCode),
        containsAll(<String>['Latn', 'Hnom']),
      );
    });

    test('resolves the Hnom channel through the shared language core', () {
      final hnomChannel = ForumLanguages.channels.firstWhere(
        (channel) => channel.key == 'vi:Hnom',
      );

      expect(hnomChannel.contentLanguageCode, 'chunom');
      expect(hnomChannel.nameOf('zh'), '越南语-喃字');
      expect(hnomChannel.nameOf('vi-VN'), 'Tiếng Việt-Chữ Nôm');
    });
  });
}
