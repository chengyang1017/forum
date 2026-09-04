import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../social/presentation/widgets/follow_stats.dart';
import '../cubit/profile_state.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileState profile;
  final String email;
  final int postCount;
  final int totalLikes;
  final AppLocalizations l10n;
  final VoidCallback onAvatarTap;
  final VoidCallback onNicknameTap;
  final VoidCallback onUsernameTap;
  final VoidCallback onBirthdayTap;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.email,
    required this.postCount,
    required this.totalLikes,
    required this.l10n,
    required this.onAvatarTap,
    required this.onNicknameTap,
    required this.onUsernameTap,
    required this.onBirthdayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nickname = profile.nickname;
    final username = profile.username;
    final birthday = profile.birthday;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildAvatar(theme),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onNicknameTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    nickname.isNotEmpty ? nickname : l10n.setNickname,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: nickname.isNotEmpty
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.grey.shade400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.edit_note_rounded,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onUsernameTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '@$username',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit, size: 12, color: Colors.grey.shade400),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onBirthdayTap,
            child: _isDefaultBirthday(birthday)
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cake_outlined,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.setBirthday,
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                      Icon(Icons.edit, size: 14, color: Colors.grey[400]),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cake, size: 16, color: Colors.pink[300]),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.ageYears('${_calculateAge(birthday!)}'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (!profile.showAge)
                        Icon(Icons.lock, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Icon(Icons.edit, size: 14, color: Colors.grey[400]),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          FollowStats(
            userId: profile.userProfile.id,
            postCount: postCount,
            totalLikes: totalLikes,
            postsLabel: l10n.posts,
            likesLabel: l10n.likesCount,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    final avatarUrl = profile.avatarUrl;
    final displayName = profile.displayName;

    return GestureDetector(
      onTap: onAvatarTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.surface, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: Colors.blue.shade50,
              backgroundImage: avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: profile.uploadingAvatar
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : avatarUrl.isEmpty
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  bool _isDefaultBirthday(DateTime? date) {
    return date == null ||
        (date.year == 2000 && date.month == 1 && date.day == 1);
  }
}
