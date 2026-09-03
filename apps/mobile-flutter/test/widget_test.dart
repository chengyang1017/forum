import 'package:flutter_test/flutter_test.dart';

import 'package:glyphora_mobile/features/language/data/forum_languages.dart';

void main() {
  group('ForumLanguages', () {
    test('keeps Vietnamese script channels separate internally', () {
      final vietnameseChannels = ForumLanguages.channels
          .where((channel) => channel.languageCode == 'vi')
          .toList(growable: false);

      expect(vietnameseChannels, hasLength(2));
      expect(
        vietnameseChannels.map((channel) => channel.scriptCode),
        containsAll(<String>['Latn', 'Hnom']),
      );
    });

    test('groups Vietnamese under one language choice', () {
      final vietnameseGroup = ForumLanguages.channelGroups.firstWhere(
        (group) => group.languageCode == 'vi',
      );

      expect(vietnameseGroup.hasScriptChoices, isTrue);
      expect(vietnameseGroup.channels, hasLength(2));
      expect(vietnameseGroup.nameOf('zh'), '越南语');
      expect(vietnameseGroup.nameOf('vi-VN'), 'Tiếng Việt');
    });

    test('resolves the Hnom channel through the shared language core', () {
      final hnomChannel = ForumLanguages.channels.firstWhere(
        (channel) => channel.key == 'vi:Hnom',
      );

      expect(hnomChannel.contentLanguageCode, 'chunom');
      expect(hnomChannel.scriptNameOf('zh'), '喃字');
      expect(hnomChannel.scriptNameOf('vi-VN'), 'Chữ Nôm');
      expect(hnomChannel.nameOf('zh'), '越南语 · 喃字');
      expect(hnomChannel.nameOf('vi-VN'), 'Tiếng Việt · Chữ Nôm');
    });
  });
}
