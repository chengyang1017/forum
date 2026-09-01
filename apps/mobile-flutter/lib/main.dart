import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import 'app/di/app_dependencies.dart';
import 'app/l10n/localizations_delegate.dart';
import 'app/providers/app_language.dart';
import 'app/router/app_router.dart';
import 'app/router/app_routes.dart';
import 'core/services/deep_link_service.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart' as auth_cubit;
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/chat/presentation/providers/chat_provider.dart' as chat_prov;
import 'features/discover/presentation/providers/discover_provider.dart'
    as discover_prov;
import 'features/feed/presentation/providers/feed_provider.dart' as feed_prov;
import 'features/post/domain/repositories/post_repository.dart';
import 'features/post/presentation/providers/post_provider.dart' as post_prov;
import 'features/social/presentation/providers/friend_provider.dart'
    as friend_prov;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final dependencies = AppDependencies.create();

  DeepLinkService.instance.start(
    openPostRoute: (postId) async {
      await appRouter.push<void>(AppRoutes.postDetailLocation(postId: postId));
    },
  );

  runApp(MyApp(dependencies: dependencies));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  static const Locale chunomLocale = Locale.fromSubtags(
    languageCode: 'vi',
    scriptCode: 'Nom',
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PostRepository>.value(value: dependencies.postRepository),
        ChangeNotifierProvider(create: (_) => AppLanguage()),
        BlocProvider<auth_cubit.AuthCubit>(
          create: (_) => auth_cubit.AuthCubit()..loadUser(),
        ),
        ChangeNotifierProvider(create: (_) => chat_prov.ChatProvider()),
        ChangeNotifierProvider(create: (_) => friend_prov.FriendProvider()),
        ChangeNotifierProvider(create: (_) => discover_prov.DiscoverProvider()),
        ChangeNotifierProvider(
          create: (context) => feed_prov.FeedProvider(
            repository: context.read<PostRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => post_prov.PostProvider(
            repository: context.read<PostRepository>(),
          ),
        ),
      ],
      child: Consumer<AppLanguage>(
        builder: (context, appLanguage, child) {
          return BlocListener<auth_cubit.AuthCubit, AuthState>(
            listenWhen: (previous, current) {
              return previous.isInitialized != current.isInitialized ||
                  previous.user?.id != current.user?.id;
            },
            listener: (context, state) {
              appRouter.refresh();
            },
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: '论坛App',
              locale: appLanguage.locale,
              supportedLocales: const [
                Locale('zh'),
                Locale('en'),
                Locale('ja'),
                Locale('ko'),
                Locale('ms'),
                Locale('vi'),
                Locale('th'),
                Locale.fromSubtags(languageCode: 'vi', scriptCode: 'Hani'),
              ],
              localizationsDelegates: const [
                AppLocalizationsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                FlutterQuillLocalizations.delegate,
              ],
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
            ),
          );
        },
      ),
    );
  }
}
