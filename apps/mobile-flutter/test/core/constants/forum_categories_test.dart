import 'package:flutter_test/flutter_test.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';
import 'package:glyphora_mobile/core/constants/forum_categories.dart';

void main() {
  group('ForumCategories', () {
    test('returns direct children', () {
      final programmingChildren = ForumCategories.childrenOf(
        'programming',
      ).map((category) => category.id).toSet();

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
      expect(ForumCategories.pathOf('flutter'), <String>[
        'programming',
        'mobile_development',
        'flutter',
      ]);
    });

    test('finds the root category', () {
      expect(ForumCategories.rootIdOf('cardiology'), 'medicine');
    });

    test('detects branches and leaves', () {
      expect(ForumCategories.hasChildren('programming'), isTrue);
      expect(ForumCategories.hasChildren('mobile_development'), isTrue);
      expect(ForumCategories.hasChildren('flutter'), isFalse);
    });

    test('returns every descendant', () {
      final descendants = ForumCategories.descendantsOf(
        'programming',
      ).map((category) => category.id).toSet();

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
      expect(ForumCategories.nameOf('internal_medicine', 'zh'), '内科');
      expect(
        ForumCategories.nameOf('internal_medicine', 'en'),
        'Internal Medicine',
      );
      expect(ForumCategories.nameOf('flutter', 'vi'), 'Flutter');
    });

    test('returns localized breadcrumb path', () {
      expect(ForumCategories.localizedPathOf('cardiology', 'zh'), <String>[
        '医学',
        '内科',
        '心血管内科',
      ]);
    });

    test('sources language-learning children from the language core', () {
      final vietnamese = LanguageConfig.findByCode('vi');
      expect(vietnamese, isNotNull);

      final categoryId = ForumCategories.languageLearningCategoryIdFor('vi');
      final category = ForumCategories.findById(categoryId);

      expect(category, isNotNull);
      expect(category!.parentId, ForumCategories.languageLearningCategoryId);
      expect(category.nameOf('zh'), vietnamese!.nameOf('zh'));
      expect(ForumCategories.languageCodeOf(categoryId), vietnamese.code);
    });

    test('keeps general language-learning posts at the root', () {
      expect(
        ForumCategories.pathOf(ForumCategories.languageLearningCategoryId),
        <String>[ForumCategories.languageLearningCategoryId],
      );
    });

    test('splits Vietnamese into writing-system subcategories', () {
      final vietnamese = LanguageConfig.findByCode('vi');
      expect(vietnamese, isNotNull);
      expect(vietnamese!.scriptCodes, containsAll(<String>['Latn', 'Hnom']));

      final vietnameseCategoryId =
          ForumCategories.languageLearningCategoryIdFor('vi');
      final children = ForumCategories.childrenOf(vietnameseCategoryId);
      final childIds = children.map((category) => category.id).toSet();
      final latinId = ForumCategories.languageLearningScriptCategoryIdFor(
        'vi',
        'Latn',
      );
      final nomId = ForumCategories.languageLearningScriptCategoryIdFor(
        'vi',
        'Hnom',
      );

      expect(childIds, containsAll(<String>{latinId, nomId}));
      expect(ForumCategories.hasChildren(vietnameseCategoryId), isTrue);
      expect(
        ForumCategories.isLanguageLearningLanguageCategory(
          vietnameseCategoryId,
        ),
        isTrue,
      );
      expect(ForumCategories.isLanguageLearningScriptCategory(latinId), isTrue);
      expect(ForumCategories.isLanguageLearningScriptCategory(nomId), isTrue);
      expect(ForumCategories.languageCodeOf(nomId), 'vi');
      expect(ForumCategories.scriptCodeOf(latinId), 'Latn');
      expect(ForumCategories.scriptCodeOf(nomId), 'Hnom');
      expect(
        ForumCategories.nameOf(latinId, 'zh'),
        vietnamese.scriptNameOf('Latn', 'zh'),
      );
      expect(
        ForumCategories.nameOf(nomId, 'zh'),
        vietnamese.scriptNameOf('Hnom', 'zh'),
      );
    });

    test('builds language-learning paths through writing systems', () {
      final vietnameseCategoryId =
          ForumCategories.languageLearningCategoryIdFor('vi');
      final nomId = ForumCategories.languageLearningScriptCategoryIdFor(
        'vi',
        'Hnom',
      );

      expect(ForumCategories.pathOf(vietnameseCategoryId), <String>[
        ForumCategories.languageLearningCategoryId,
        vietnameseCategoryId,
      ]);
      expect(ForumCategories.pathOf(nomId), <String>[
        ForumCategories.languageLearningCategoryId,
        vietnameseCategoryId,
        nomId,
      ]);
      expect(
        ForumCategories.rootIdOf(nomId),
        ForumCategories.languageLearningCategoryId,
      );
    });
  });
}
