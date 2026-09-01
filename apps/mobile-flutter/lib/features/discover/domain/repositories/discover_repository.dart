import '../models/discover_user.dart';

/// Read boundary for the Discover user list.
///
/// Firestore snapshots and document maps stay in the data layer. Chat creation
/// and friendship mutations use their own feature repositories instead of
/// being duplicated inside Discover.
abstract interface class DiscoverRepository {
  Stream<List<DiscoverUser>> watchAllUsers(String currentUserId);
}
