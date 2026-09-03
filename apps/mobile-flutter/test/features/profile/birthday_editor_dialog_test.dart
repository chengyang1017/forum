import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:glyphora_mobile/app/l10n/localizations_delegate.dart';
import 'package:glyphora_mobile/features/profile/presentation/widgets/birthday_editor_dialog.dart';

void main() {
  testWidgets('keeps 2000-01-01 as a real birthday instead of a null sentinel', (
    tester,
  ) async {
    BirthdayEditorResult? result;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: const <Locale>[Locale('zh')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showBirthdayEditorDialog(
                  context: context,
                  birthday: DateTime(2000, 1, 1),
                  showAge: true,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('2000'), findsOneWidget);
    expect(find.text('Y'), findsNothing);
    expect(find.text('M'), findsNothing);
    expect(find.text('D'), findsNothing);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.birthday, DateTime(2000, 1, 1));
  });
}
