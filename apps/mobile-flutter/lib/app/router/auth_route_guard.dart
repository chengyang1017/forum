import '../../features/auth/presentation/cubit/auth_state.dart';
import 'app_routes.dart';

String? authRouteRedirect({
  required AuthState authState,
  required String path,
}) {
  if (!authState.isInitialized) {
    return null;
  }

  final isAuthRoute =
      path == AppRoutes.login ||
      path == AppRoutes.register ||
      path == AppRoutes.forgotPassword;

  if (authState.user == null) {
    if (path == AppRoutes.root) {
      return AppRoutes.login;
    }

    if (!isAuthRoute) {
      return AppRoutes.login;
    }

    return null;
  }

  if (path == AppRoutes.root) {
    return AppRoutes.home;
  }

  return null;
}
