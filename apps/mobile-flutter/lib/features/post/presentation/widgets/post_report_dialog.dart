import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';

class PostReportDraft {
  final String reason;
  final String? details;

  const PostReportDraft({required this.reason, required this.details});
}

class _ReportReasonOption {
  final String value;
  final String localizationKey;
  final IconData icon;

  const _ReportReasonOption({
    required this.value,
    required this.localizationKey,
    required this.icon,
  });
}

const _reportReasons = <_ReportReasonOption>[
  _ReportReasonOption(
    value: 'spam',
    localizationKey: 'reportReasonSpam',
    icon: Icons.mark_email_unread_outlined,
  ),
  _ReportReasonOption(
    value: 'harassment',
    localizationKey: 'reportReasonHarassment',
    icon: Icons.person_off_outlined,
  ),
  _ReportReasonOption(
    value: 'hate',
    localizationKey: 'reportReasonHate',
    icon: Icons.warning_amber_rounded,
  ),
  _ReportReasonOption(
    value: 'sexual',
    localizationKey: 'reportReasonSexual',
    icon: Icons.visibility_off_outlined,
  ),
  _ReportReasonOption(
    value: 'violence',
    localizationKey: 'reportReasonViolence',
    icon: Icons.dangerous_outlined,
  ),
  _ReportReasonOption(
    value: 'misinformation',
    localizationKey: 'reportReasonMisinformation',
    icon: Icons.fact_check_outlined,
  ),
  _ReportReasonOption(
    value: 'copyright',
    localizationKey: 'reportReasonCopyright',
    icon: Icons.copyright_rounded,
  ),
  _ReportReasonOption(
    value: 'other',
    localizationKey: 'reportReasonOther',
    icon: Icons.more_horiz_rounded,
  ),
];

Future<PostReportDraft?> showPostReportDialog(BuildContext context) {
  return showDialog<PostReportDraft>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PostReportDialog(),
  );
}

class _PostReportDialog extends StatefulWidget {
  const _PostReportDialog();

  @override
  State<_PostReportDialog> createState() => _PostReportDialogState();
}

class _PostReportDialogState extends State<_PostReportDialog> {
  final TextEditingController _detailsController = TextEditingController();

  String? _reason;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reason;

    if (reason == null) {
      return;
    }

    final details = _detailsController.text.trim();

    Navigator.of(context).pop(
      PostReportDraft(
        reason: reason,
        details: details.isEmpty ? null : details,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.flag_outlined, size: 22),
          const SizedBox(width: 10),
          Text(l10n.get('reportPost')),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.get('chooseReportReason'),
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 10),
              ..._reportReasons.map((option) {
                final selected = _reason == option.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _reason = option.value;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? colors.primary
                              : colors.outlineVariant,
                        ),
                        color: selected
                            ? colors.primaryContainer.withValues(alpha: 0.35)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            option.icon,
                            size: 20,
                            color: selected
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.get(option.localizationKey),
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (selected)
                            Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: colors.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              TextField(
                controller: _detailsController,
                maxLines: 4,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: l10n.get('reportDetailsLabel'),
                  hintText: l10n.get('reportDetailsHint'),
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              Text(
                l10n.get('reportReviewNotice'),
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _reason == null ? null : _submit,
          child: Text(l10n.get('submitReport')),
        ),
      ],
    );
  }
}
