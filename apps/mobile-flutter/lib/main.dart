import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

// ========== 国际化 ==========
import 'app/l10n/localizations_delegate.dart';

// ========== Provider（全局） ==========
import 'app/providers/app_language.dart';

// ========== Provider（功能模块） ==========
import 'features/auth/presentation/providers/auth_provider.dart' as auth_prov;
import 'features/chat/presentation/providers/chat_provider.dart' as chat_prov;
import 'features/social/presentation/providers/friend_provider.dart'
    as friend_prov;
import 'features/feed/presentation/providers/feed_provider.dart' as feed_prov;
import 'features/discover/presentation/providers/discover_provider.dart'
    as discover_prov;
import 'features/post/presentation/providers/post_provider.dart' as post_prov;

import 'app/router/app_router.dart';
import 'app/router/app_routes.dart';
import 'core/services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  DeepLinkService.instance.start(
    openPostRoute: (postId) async {
      await appRouter.push<void>(AppRoutes.postDetailLocation(postId: postId));
    },
  );

  runApp(const MyApp());
}

// ============================================================
// 根 Widget
// ============================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Locale chunomLocale = Locale.fromSubtags(
    languageCode: 'vi',
    scriptCode: 'Nom',
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ----- 全局状态 -----
        ChangeNotifierProvider(create: (_) => AppLanguage()),

        // ----- 功能模块 Provider -----
        ChangeNotifierProvider(
          create: (_) => auth_prov.AuthProvider()..loadUser(),
        ),
        ChangeNotifierProvider(create: (_) => chat_prov.ChatProvider()),
        ChangeNotifierProvider(create: (_) => friend_prov.FriendProvider()),
        ChangeNotifierProvider(create: (_) => discover_prov.DiscoverProvider()),
        ChangeNotifierProvider(create: (_) => feed_prov.FeedProvider()),
        ChangeNotifierProvider(create: (_) => post_prov.PostProvider()),
      ],
      child: Consumer<AppLanguage>(
        builder: (context, appLanguage, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: '论坛App',

            // 当前语言
            locale: appLanguage.locale,

            // 支持语言
            supportedLocales: const [
              Locale('zh'),
              Locale('en'),
              Locale('ja'),
              Locale('ko'),
              Locale('ms'),
              Locale('vi'),
              Locale('th'),

              // 喃字
              Locale.fromSubtags(languageCode: 'vi', scriptCode: 'Hani'),
            ],

            // 本地化 delegate
            localizationsDelegates: const [
              AppLocalizationsDelegate(),

              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,

              // Flutter Quill 本地化
              FlutterQuillLocalizations.delegate,
            ],

            // 优先匹配 scriptCode
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale == null) {
                return const Locale('zh');
              }

              for (final supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode &&
                    supportedLocale.scriptCode == locale.scriptCode) {
                  return supportedLocale;
                }
              }

              for (final supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode &&
                    supportedLocale.scriptCode == null) {
                  return supportedLocale;
                }
              }

              return const Locale('zh');
            },

            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.blue,
              fontFamily: 'NomNaTong',
            ),

            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
