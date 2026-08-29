import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/profile/presentation/screens/security_settings_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/discover/presentation/screens/discover_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/home/presentation/screens/main_navigation_screen.dart';
import '../../core/constants/forum_categories.dart';
import '../../features/language/data/forum_languages.dart';
import '../../features/post/domain/models/post_model.dart';
import '../../features/notes/presentation/screens/all_notes_screen.dart';
import '../../features/notes/presentation/screens/note_editor_screen.dart';
import '../../features/post/presentation/screens/bookmarked_posts_screen.dart';
import '../../features/post/presentation/screens/create_post_screen.dart';
import '../../features/post/presentation/screens/post_detail_screen.dart';
import '../../features/profile/presentation/screens/user_profile_screen.dart';
import '../../features/social/presentation/screens/friend_requests_screen.dart';
import 'app_routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.securitySettings,
      builder: (context, state) => const SecuritySettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.changePassword,
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.allNotes,
      builder: (context, state) => const AllNotesScreen(),
    ),
    GoRoute(
      path: AppRoutes.noteEditor,
      builder: (context, state) {
        final noteId = state.pathParameters['noteId']!;

        return NoteEditorScreen(noteId: noteId);
      },
    ),
    GoRoute(
      path: AppRoutes.bookmarkedPosts,
      builder: (context, state) => const BookmarkedPostsScreen(),
    ),
    GoRoute(
      path: AppRoutes.discover,
      builder: (context, state) => const DiscoverScreen(),
    ),
    GoRoute(
      path: AppRoutes.friendRequests,
      builder: (context, state) => const FriendRequestsScreen(),
    ),
    GoRoute(
      path: AppRoutes.userProfile,
      builder: (context, state) {
        final uid = state.pathParameters['uid']!;

        return UserProfileScreen(uid: uid);
      },
    ),
    GoRoute(
      path: AppRoutes.chat,
      builder: (context, state) {
        final chatId = state.pathParameters['chatId']!;
        final extra = state.extra;

        return ChatRouteScreen(
          chatId: chatId,
          initialOtherUserName: extra is String ? extra : null,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.createPost,
      redirect: (context, state) {
        final channelKey = state.pathParameters['channelKey'];
        final categoryId = state.pathParameters['categoryId'];

        if (channelKey == null ||
            categoryId == null ||
            ForumLanguages.findChannelByKey(channelKey) == null ||
            ForumCategories.findById(categoryId) == null) {
          return AppRoutes.home;
        }

        return null;
      },
      builder: (context, state) {
        final channelKey = state.pathParameters['channelKey']!;
        final categoryId = state.pathParameters['categoryId']!;

        final channel = ForumLanguages.findChannelByKey(channelKey)!;
        final categoryPath = ForumCategories.pathOf(categoryId);
        final rootCategoryId = ForumCategories.rootIdOf(categoryId);

        final uiLanguageCode = Localizations.localeOf(context).languageCode;

        return CreatePostScreen(
          category: rootCategoryId,
          categoryId: categoryId,
          categoryPath: categoryPath,
          languageCode: channel.contentLanguageCode,
          languageName: channel.nameOf(uiLanguageCode),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.postDetail,
      builder: (context, state) {
        final postId = state.pathParameters['postId']!;
        final extra = state.extra;

        return PostDetailRouteScreen(
          postId: postId,
          initialPost: extra is PostModel ? extra : null,
        );
      },
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
