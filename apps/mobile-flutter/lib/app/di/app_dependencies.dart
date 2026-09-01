import '../../features/post/application/ports/post_media_repository.dart';
import '../../features/post/data/repositories/firebase_post_media_repository.dart';
import '../../features/post/data/repositories/post_repository_impl.dart';
import '../../features/post/domain/repositories/post_repository.dart';
import '../../features/profile/application/ports/profile_media_repository.dart';
import '../../features/profile/data/repositories/firebase_profile_media_repository.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';

/// Application-level dependency container.
///
/// Object construction belongs here so feature code depends on abstractions,
/// not concrete services. Add new long-lived dependencies here as other
/// features are migrated to constructor injection.
final class AppDependencies {
  AppDependencies({
    required this.postRepository,
    required this.postMediaRepository,
    required this.profileRepository,
    required this.profileMediaRepository,
  });

  factory AppDependencies.create() {
    return AppDependencies(
      postRepository: PostRepositoryImpl(),
      postMediaRepository: FirebasePostMediaRepository(),
      profileRepository: ProfileRepositoryImpl(),
      profileMediaRepository: FirebaseProfileMediaRepository(),
    );
  }

  final PostRepository postRepository;
  final PostMediaRepository postMediaRepository;
  final ProfileRepository profileRepository;
  final ProfileMediaRepository profileMediaRepository;
}
