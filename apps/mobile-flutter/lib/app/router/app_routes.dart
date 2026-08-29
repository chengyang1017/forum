abstract final class AppRoutes {
  static const root = '/';

  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  static const home = '/home';

  static const friendRequests = '/friends/requests';

  static const feed = '/feed/:channelKey/:categoryId';
  static const createPost = '/posts/new/:channelKey/:categoryId';
  static const postDetail = '/posts/:postId';

  static String feedLocation({
    required String channelKey,
    required String categoryId,
  }) {
    return '/feed/'
        '${Uri.encodeComponent(channelKey)}/'
        '${Uri.encodeComponent(categoryId)}';
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
