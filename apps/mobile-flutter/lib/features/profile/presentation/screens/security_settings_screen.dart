import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/utils/auth_failure_message.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isSendingResetEmail = false;

  Future<void> _sendPasswordResetEmail() async {
    final email = context.read<AuthCubit>().user?.email?.trim();

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.get('noUsableEmail')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSendingResetEmail = true;
    });

    try {
      await context.read<AuthCubit>().sendPasswordResetEmail(email);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.get('resetEmailSent')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authFailureMessage(
              error,
              AppLocalizations.of(context)!,
              fallbackKey: 'authResetEmailFailed',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingResetEmail = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final email = context.select<AuthCubit, String?>(
      (cubit) => cubit.user?.email,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('accountSecurity')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.get('passwordRecoveryPrivacyDescription'),
                    style: const TextStyle(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.get('passwordRecovery'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            email == null || email.isEmpty ? l10n.get('noUsableEmail') : email,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isSendingResetEmail ? null : _sendPasswordResetEmail,
            icon: _isSendingResetEmail
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.mark_email_unread_outlined),
            label: Text(
              _isSendingResetEmail
                  ? l10n.get('sending')
                  : l10n.get('sendResetEmail'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.get('passwordResetTechnicalNote'),
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
