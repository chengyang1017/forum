import '../../features/chat/application/ports/chat_media_repository.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/data/repositories/firebase_chat_media_repository.dart';
import '../../features/chat/data/repositories/firebase_live_draft_repository.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/repositories/live_draft_repository.dart';
import '../../features/post/application/ports/post_media_repository.dart';
import '../../features/post/data/repositories/firebase_post_media_repository.dart';
import '../../features/post/data/repositories/post_repository_impl.dart';
import '../../features/post/domain/repositories/post_repository.dart';
import '../../features/profile/application/ports/profile_media_repository.dart';
import '../../features/profile/data/repositories/firebase_profile_media_repository.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/social/data/repositories/firestore_friend_repository.dart';
import '../../features/social/domain/repositories/friend_repository.dart';

/// Application-level dependency container.
///
/// Object construction belongs here so feature code depends on abstractions,
/// not concrete services. Add new long-lived dependencies here as other
/// features are migrated to constructor injection.
final class AppDependencies {
  AppDependencies({
    required this.chatRepository,
    required this.chatMediaRepository,
    required this.liveDraftRepository,
    required this.postRepository,
    required this.postMediaRepository,
    required this.profileRepository,
    required this.profileMediaRepository,
    required this.friendRepository,
  });

  factory AppDependencies.create() {
    return AppDependencies(
      chatRepository: ChatRepositoryImpl(),
      chatMediaRepository: FirebaseChatMediaRepository(),
      liveDraftRepository: FirebaseLiveDraftRepository(),
      postRepository: PostRepositoryImpl(),
      postMediaRepository: FirebasePostMediaRepository(),
      profileRepository: ProfileRepositoryImpl(),
      profileMediaRepository: FirebaseProfileMediaRepository(),
      friendRepository: FirestoreFriendRepository(),
    );
  }

  final ChatRepository chatRepository;
  final ChatMediaRepository chatMediaRepository;
  final LiveDraftRepository liveDraftRepository;
  final PostRepository postRepository;
  final PostMediaRepository postMediaRepository;
  final ProfileRepository profileRepository;
  final ProfileMediaRepository profileMediaRepository;
  final FriendRepository friendRepository;
}
