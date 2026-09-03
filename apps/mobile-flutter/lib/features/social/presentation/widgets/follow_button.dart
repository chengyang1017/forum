import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../domain/repositories/follow_repository.dart';

/// Reusable one-way follow control.
///
/// This deliberately represents content following only. Friendship remains a
/// separate mutual relationship and can be shown beside this control.
class FollowButton extends StatefulWidget {
  const FollowButton({super.key, required this.userId, this.expanded = false});

  final String userId;
  final bool expanded;

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<FollowRepository>();

    return StreamBuilder<bool>(
      stream: repository.watchIsFollowing(widget.userId),
      initialData: false,
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;
        final button = FilledButton.tonalIcon(
          onPressed: _isBusy
              ? null
              : () => _toggleFollow(
                  repository: repository,
                  isFollowing: isFollowing,
                ),
          icon: _isBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isFollowing
                      ? Icons.person_rounded
                      : Icons.person_add_alt_1_rounded,
                  size: 18,
                ),
          label: Text(
            isFollowing
                ? AppLocalizations.of(context)!.get('following')
                : AppLocalizations.of(context)!.get('followAction'),
          ),
          style: FilledButton.styleFrom(
            minimumSize: widget.expanded ? const Size(0, 44) : null,
            visualDensity: widget.expanded
                ? VisualDensity.standard
                : VisualDensity.compact,
            padding: EdgeInsets.symmetric(
              horizontal: widget.expanded ? 16 : 12,
              vertical: widget.expanded ? 10 : 8,
            ),
          ),
        );

        if (!widget.expanded) {
          return button;
        }

        return SizedBox(width: double.infinity, child: button);
      },
    );
  }

  Future<void> _toggleFollow({
    required FollowRepository repository,
    required bool isFollowing,
  }) async {
    setState(() => _isBusy = true);

    try {
      if (isFollowing) {
        await repository.unfollow(widget.userId);
      } else {
        await repository.follow(widget.userId);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.get('followActionFailed'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }
}
