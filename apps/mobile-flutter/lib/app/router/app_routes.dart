abstract final class AppRoutes {
  static const root = '/';

  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  static const home = '/home';

  static const discover = '/discover';

  static const settings = '/settings';
  static const securitySettings = '/settings/security';
  static const changePassword = '/settings/change-password';

  static const allNotes = '/notes';
  static const noteEditor = '/notes/:noteId';
  static const bookmarkedPosts = '/bookmarks';

  static const friendRequests = '/friends/requests';

  static const userProfile = '/users/:uid';

  static const chat = '/chats/:chatId';

  static const feed = '/feed/:channelKey/:categoryId';
  static const createPost = '/posts/new/:channelKey/:categoryId';
  static const postDetail = '/posts/:postId';

  static String noteEditorLocation({required String noteId}) {
    return '/notes/${Uri.encodeComponent(noteId)}';
  }

  static String userProfileLocation({required String uid}) {
    return '/users/${Uri.encodeComponent(uid)}';
  }

  static String feedLocation({
    required String channelKey,
    required String categoryId,
  }) {
    return '/feed/'
        '${Uri.encodeComponent(channelKey)}/'
        '${Uri.encodeComponent(categoryId)}';
  }

  static String chatLocation({required String chatId}) {
    return '/chats/${Uri.encodeComponent(chatId)}';
  }

  static String createPostLocation({
    required String channelKey,
    required String categoryId,
  }) {
    return '/posts/new/'
        '${Uri.encodeComponent(channelKey)}/'
        '${Uri.encodeComponent(categoryId)}';
  }

  static String postDetailLocation({required String postId}) {
    return '/posts/${Uri.encodeComponent(postId)}';
  }
}
