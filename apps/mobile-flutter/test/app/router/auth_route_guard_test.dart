import 'package:flutter_test/flutter_test.dart';
import 'package:glyphora_mobile/app/router/app_routes.dart';
import 'package:glyphora_mobile/app/router/auth_route_guard.dart';
import 'package:glyphora_mobile/features/auth/domain/models/user_model.dart';
import 'package:glyphora_mobile/features/auth/presentation/cubit/auth_state.dart';

void main() {
  const user = UserModel(id: 'user-1', username: 'alice');

  group('authRouteRedirect', () {
    test('does not redirect before auth initialization finishes', () {
      final state = AuthState(isInitialized: false);

      final redirect = authRouteRedirect(
        authState: state,
        path: AppRoutes.home,
      );

      expect(redirect, isNull);
    });

    test('redirects unauthenticated root to login', () {
      final state = AuthState(isInitialized: true);

      final redirect = authRouteRedirect(
        authState: state,
        path: AppRoutes.root,
      );

      expect(redirect, AppRoutes.login);
    });

    test('redirects unauthenticated protected route to login', () {
      final state = AuthState(isInitialized: true);

      final redirect = authRouteRedirect(
        authState: state,
        path: AppRoutes.settings,
      );

      expect(redirect, AppRoutes.login);
    });

    test('allows unauthenticated login route', () {
      final state = AuthState(isInitialized: true);

      final redirect = authRouteRedirect(
        authState: state,
        path: AppRoutes.login,
      );

      expect(redirect, isNull);
    });

    test('redirects authenticated root to home', () {
      final state = AuthState(user: user, isInitialized: true);

      final redirect = authRouteRedirect(
        authState: state,
        path: AppRoutes.root,
      );

      expect(redirect, AppRoutes.home);
    });

    test('allows authenticated protected route', () {
      final state = AuthState(user: user, isInitialized: true);

      final redirect = authRouteRedirect(
        authState: state,
        path: AppRoutes.settings,
      );

      expect(redirect, isNull);
    });
  });
}
