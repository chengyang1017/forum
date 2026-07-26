import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

// ========== 屏幕 ==========
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/main_navigation_screen.dart';

// ========== 国际化 ==========
import 'config/l10n/app_localizations.dart';
import 'config/l10n/localizations_delegate.dart';

// ========== Provider（全局） ==========
import 'shared/providers/app_language.dart';

// ========== Provider（功能模块） ==========
import 'features/auth/providers/auth_provider.dart'
    as authProv;
import 'features/chat/providers/chat_provider.dart'
    as chatProv;
import 'features/social/providers/friend_provider.dart'
    as friendProv;
import 'features/feed/providers/feed_provider.dart'
    as feedProv;
import 'features/discover/providers/discover_provider.dart'
    as discoverProv;
import 'features/feed/providers/post_provider.dart'
    as postProv;

import 'shared/services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  DeepLinkService.instance.start();

  runApp(const MyApp());
}

// ============================================================
// 根 Widget
// ============================================================

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  static const Locale chunomLocale =
      Locale.fromSubtags(
    languageCode: 'vi',
    scriptCode: 'Nom',
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ----- 全局状态 -----
        ChangeNotifierProvider(
          create: (_) => AppLanguage(),
        ),

        // ----- 功能模块 Provider -----
        ChangeNotifierProvider(
          create: (_) =>
              authProv.AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              chatProv.ChatProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              friendProv.FriendProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              discoverProv.DiscoverProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              feedProv.FeedProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              postProv.PostProvider(),
        ),
      ],
      child: Consumer<AppLanguage>(
        builder: (
          context,
          appLanguage,
          child,
        ) {
          return MaterialApp(
            navigatorKey: rootNavigatorKey,
            debugShowCheckedModeBanner:
                false,
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
              Locale.fromSubtags(
                languageCode: 'vi',
                scriptCode: 'Hani',
              ),
            ],

            // 本地化 delegate
            localizationsDelegates: const [
              AppLocalizationsDelegate(),

              GlobalMaterialLocalizations
                  .delegate,
              GlobalWidgetsLocalizations
                  .delegate,
              GlobalCupertinoLocalizations
                  .delegate,

              // Flutter Quill 本地化
              FlutterQuillLocalizations
                  .delegate,
            ],

            // 优先匹配 scriptCode
            localeResolutionCallback: (
              locale,
              supportedLocales,
            ) {
              if (locale == null) {
                return const Locale('zh');
              }

              for (final supportedLocale
                  in supportedLocales) {
                if (supportedLocale
                            .languageCode ==
                        locale.languageCode &&
                    supportedLocale
                            .scriptCode ==
                        locale.scriptCode) {
                  return supportedLocale;
                }
              }

              for (final supportedLocale
                  in supportedLocales) {
                if (supportedLocale
                            .languageCode ==
                        locale.languageCode &&
                    supportedLocale
                            .scriptCode ==
                        null) {
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

            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance
                  .authStateChanges(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasData) {
                  WidgetsBinding.instance
                      .addPostFrameCallback(
                    (_) {
                      context
                          .read<
                              authProv
                              .AuthProvider>()
                          .loadUser();
                    },
                  );

                  return const MainNavigationScreen();
                }

                return const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}