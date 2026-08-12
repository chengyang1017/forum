import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_3/core/constants/forum_categories.dart';

void main() {
  group('ForumCategories', () {
    test('returns direct children', () {
      final programmingChildren = ForumCategories.childrenOf('programming')
          .map((category) => category.id)
          .toSet();

      expect(
        programmingChildren,
        containsAll(<String>{
          'mobile_development',
          'web_development',
          'backend_development',
          'database_development',
        }),
      );
    });

    test('builds a multi-level path', () {
      expect(
        ForumCategories.pathOf('flutter'),
        <String>[
          'programming',
          'mobile_development',
          'flutter',
        ],
      );
    });

    test('finds the root category', () {
      expect(
        ForumCategories.rootIdOf('cardiology'),
        'medicine',
      );
    });

    test('detects branches and leaves', () {
      expect(ForumCategories.hasChildren('programming'), isTrue);
      expect(ForumCategories.hasChildren('mobile_development'), isTrue);
      expect(ForumCategories.hasChildren('flutter'), isFalse);
    });

    test('returns every descendant', () {
      final descendants = ForumCategories.descendantsOf('programming')
          .map((category) => category.id)
          .toSet();

      expect(descendants, contains('mobile_development'));
      expect(descendants, contains('flutter'));
      expect(descendants, contains('react_native'));
    });

    test('detects ancestor relationships', () {
      expect(
        ForumCategories.isDescendantOf(
          categoryId: 'cardiology',
          ancestorId: 'medicine',
        ),
        isTrue,
      );

      expect(
        ForumCategories.isDescendantOf(
          categoryId: 'medicine',
          ancestorId: 'medicine',
        ),
        isFalse,
      );
    });

    test('returns localized names with fallback', () {
      expect(
        ForumCategories.nameOf('internal_medicine', 'zh'),
        '内科',
      );
      expect(
        ForumCategories.nameOf('internal_medicine', 'en'),
        'Internal Medicine',
      );
      expect(
        ForumCategories.nameOf('flutter', 'vi'),
        'Flutter',
      );
    });

    test('returns localized breadcrumb path', () {
      expect(
        ForumCategories.localizedPathOf('cardiology', 'zh'),
        <String>['医学', '内科', '心血管内科'],
      );
    });
  });
}
