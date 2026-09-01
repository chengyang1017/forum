import '../../features/auth/data/repositories/firebase_auth_repository.dart';
import '../../features/auth/data/repositories/shared_preferences_account_history_repository.dart';
import '../../features/auth/data/services/user_api.dart';
import '../../features/auth/domain/repositories/account_history_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/user_backend_repository.dart';
import '../../features/chat/application/ports/chat_media_repository.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/data/repositories/firebase_chat_media_repository.dart';
import '../../features/chat/data/repositories/firebase_live_draft_repository.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/repositories/live_draft_repository.dart';
import '../../features/discover/data/repositories/firestore_discover_repository.dart';
import '../../features/discover/domain/repositories/discover_repository.dart';
import '../../features/notes/application/ports/note_media_repository.dart';
import '../../features/notes/data/repositories/firebase_note_media_repository.dart';
import '../../features/notes/data/repositories/firebase_note_repository.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
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
    required this.authRepository,
    required this.accountHistoryRepository,
    required this.userBackendRepository,
    required this.chatRepository,
    required this.chatMediaRepository,
    required this.liveDraftRepository,
    required this.discoverRepository,
    required this.noteRepository,
    required this.noteMediaRepository,
    required this.postRepository,
    required this.postMediaRepository,
    required this.profileRepository,
    required this.profileMediaRepository,
    required this.friendRepository,
  });

  factory AppDependencies.create() {
    final userBackendRepository = UserApi();

    return AppDependencies(
      authRepository: FirebaseAuthRepository(),
      accountHistoryRepository: SharedPreferencesAccountHistoryRepository(),
      userBackendRepository: userBackendRepository,
      chatRepository: ChatRepositoryImpl(),
      chatMediaRepository: FirebaseChatMediaRepository(),
      liveDraftRepository: FirebaseLiveDraftRepository(),
      discoverRepository: FirestoreDiscoverRepository(),
      noteRepository: FirebaseNoteRepository(),
      noteMediaRepository: FirebaseNoteMediaRepository(),
      postRepository: PostRepositoryImpl(),
      postMediaRepository: FirebasePostMediaRepository(),
      profileRepository: ProfileRepositoryImpl(
        userRepository: userBackendRepository,
      ),
      profileMediaRepository: FirebaseProfileMediaRepository(),
      friendRepository: FirestoreFriendRepository(),
    );
  }

  final AuthRepository authRepository;
  final AccountHistoryRepository accountHistoryRepository;
  final UserBackendRepository userBackendRepository;
  final ChatRepository chatRepository;
  final ChatMediaRepository chatMediaRepository;
  final LiveDraftRepository liveDraftRepository;
  final DiscoverRepository discoverRepository;
  final NoteRepository noteRepository;
  final NoteMediaRepository noteMediaRepository;
  final PostRepository postRepository;
  final PostMediaRepository postMediaRepository;
  final ProfileRepository profileRepository;
  final ProfileMediaRepository profileMediaRepository;
  final FriendRepository friendRepository;
}
