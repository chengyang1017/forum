import 'package:flutter_test/flutter_test.dart';

import 'package:glyphora_mobile/features/auth/domain/models/user_model.dart';
import 'package:glyphora_mobile/features/post/domain/models/post_model.dart';
import 'package:glyphora_mobile/features/post/domain/repositories/post_repository.dart';
import 'package:glyphora_mobile/features/profile/application/ports/profile_media_repository.dart';
import 'package:glyphora_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:glyphora_mobile/features/profile/presentation/cubit/profile_cubit.dart';

void main() {
  group('ProfileCubit', () {
    late _FakePostRepository postRepository;
    late _FakeProfileRepository profileRepository;
    late _FakeProfileMediaRepository mediaRepository;
    late ProfileCubit cubit;

    setUp(() {
      postRepository = _FakePostRepository();
      profileRepository = _FakeProfileRepository();
      mediaRepository = _FakeProfileMediaRepository();
      cubit = ProfileCubit(
        postRepository: postRepository,
        profileRepository: profileRepository,
        mediaRepository: mediaRepository,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('loadProfile stores profile and finishes loading', () async {
      const profile = UserModel(
        id: 'user-1',
        username: 'alice',
        nickname: 'Alice',
      );
      profileRepository.profile = profile;

      await cubit.loadProfile('user-1');

      expect(cubit.state.userProfile, same(profile));
      expect(cubit.state.loadingProfile, isFalse);
      expect(profileRepository.lastProfileUserId, 'user-1');
    });

    test('loadProfile keeps previous profile when repository fails', () async {
      const profile = UserModel(id: 'user-1', username: 'alice');
      profileRepository.profile = profile;
      await cubit.loadProfile('user-1');

      profileRepository.getProfileError = StateError('load failed');
      await cubit.loadProfile('user-1');

      expect(cubit.state.userProfile, same(profile));
      expect(cubit.state.loadingProfile, isFalse);
    });

    test('watchUserPosts delegates to PostRepository', () async {
      final posts = [PostModel(id: 'post-1')];
      postRepository.posts = posts;

      final result = await cubit.watchUserPosts('user-1').first;

      expect(result, same(posts));
      expect(postRepository.lastUserId, 'user-1');
    });

    test('totalLikesOf sums post like counts', () {
      final posts = [
        PostModel(id: 'post-1', likeCount: 2),
        PostModel(id: 'post-2', likeCount: 5),
        PostModel(id: 'post-3', likeCount: 1),
      ];

      expect(cubit.totalLikesOf(posts), 8);
    });

    test('updateNickname uses repository-confirmed profile', () async {
      const initial = UserModel(
        id: 'user-1',
        username: 'alice',
        nickname: 'Old',
      );
      const confirmed = UserModel(
        id: 'user-1',
        username: 'alice',
        nickname: 'Server Name',
      );
      profileRepository.profile = initial;
      await cubit.loadProfile('user-1');
      profileRepository.nicknameResult = confirmed;

      await cubit.updateNickname('user-1', 'Optimistic Name');

      expect(profileRepository.lastNickname, 'Optimistic Name');
      expect(cubit.state.userProfile, same(confirmed));
    });

    test(
      'updateNickname rolls back and rethrows when persistence fails',
      () async {
        const initial = UserModel(
          id: 'user-1',
          username: 'alice',
          nickname: 'Old',
        );
        profileRepository.profile = initial;
        await cubit.loadProfile('user-1');
        profileRepository.nicknameError = StateError('save failed');

        await expectLater(
          cubit.updateNickname('user-1', 'New'),
          throwsA(isA<StateError>()),
        );

        expect(cubit.state.userProfile, same(initial));
      },
    );
  });
}

final class _FakePostRepository implements PostRepository {
  List<PostModel> posts = const <PostModel>[];
  String? lastUserId;

  @override
  Stream<List<PostModel>> watchUserPosts(String userId) {
    lastUserId = userId;
    return Stream.value(posts);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeProfileRepository implements ProfileRepository {
  UserModel? profile;
  UserModel? nicknameResult;
  Object? getProfileError;
  Object? nicknameError;
  String? lastProfileUserId;
  String? lastNickname;

  @override
  Future<UserModel?> getProfile(String userId) async {
    lastProfileUserId = userId;
    final error = getProfileError;
    if (error != null) throw error;
    return profile;
  }

  @override
  Future<UserModel> updateNickname({
    required String userId,
    required String nickname,
  }) async {
    lastNickname = nickname;
    final error = nicknameError;
    if (error != null) throw error;
    return nicknameResult ?? profile!.copyWith(nickname: nickname);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeProfileMediaRepository implements ProfileMediaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
