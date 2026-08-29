import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/deep_link_service.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/home/presentation/screens/main_navigation_screen.dart';
import '../../features/language/data/forum_languages.dart';
import 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  routes: [
    GoRoute(
      path: AppRoutes.root,
      redirect: (context, state) {
        final isLoggedIn = FirebaseAuth.instance.currentUser != null;

        return isLoggedIn ? AppRoutes.home : AppRoutes.login;
      },
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: AppRoutes.feed,
      redirect: (context, state) {
        final channelKey = state.pathParameters['channelKey'];

        if (channelKey == null ||
            ForumLanguages.findChannelByKey(channelKey) == null) {
          return AppRoutes.home;
        }

        return null;
      },
      builder: (context, state) {
        final channelKey = state.pathParameters['channelKey']!;
        final categoryId = state.pathParameters['categoryId']!;

        final channel = ForumLanguages.findChannelByKey(channelKey)!;

        final uiLanguageCode = Localizations.localeOf(context).languageCode;

        return FeedScreen(
          channelKey: channel.key,
          categoryId: categoryId,
          languageCode: channel.contentLanguageCode,
          languageName: channel.nameOf(uiLanguageCode),
        );
      },
    ),
  ],
);
