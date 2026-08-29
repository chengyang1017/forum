import 'package:flutter/material.dart';

class PostReportDraft {
  final String reason;
  final String? details;

  const PostReportDraft({required this.reason, required this.details});
}

class _ReportReasonOption {
  final String value;
  final String label;
  final IconData icon;

  const _ReportReasonOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

const _reportReasons = <_ReportReasonOption>[
  _ReportReasonOption(
    value: 'spam',
    label: '垃圾信息或广告',
    icon: Icons.mark_email_unread_outlined,
  ),
  _ReportReasonOption(
    value: 'harassment',
    label: '骚扰或欺凌',
    icon: Icons.person_off_outlined,
  ),
  _ReportReasonOption(
    value: 'hate',
    label: '仇恨言论',
    icon: Icons.warning_amber_rounded,
  ),
  _ReportReasonOption(
    value: 'sexual',
    label: '色情或性内容',
    icon: Icons.visibility_off_outlined,
  ),
  _ReportReasonOption(
    value: 'violence',
    label: '暴力或危险内容',
    icon: Icons.dangerous_outlined,
  ),
  _ReportReasonOption(
    value: 'misinformation',
    label: '虚假或误导信息',
    icon: Icons.fact_check_outlined,
  ),
  _ReportReasonOption(
    value: 'copyright',
    label: '侵犯版权',
    icon: Icons.copyright_rounded,
  ),
  _ReportReasonOption(
    value: 'other',
    label: '其他',
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

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.flag_outlined, size: 22),
          SizedBox(width: 10),
          Text('举报帖子'),
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
                '请选择举报原因',
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
                              option.label,
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
                decoration: const InputDecoration(
                  labelText: '补充说明（可选）',
                  hintText: '可以补充说明具体情况',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              Text(
                '举报提交后会进入管理员审核队列。',
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
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _reason == null ? null : _submit,
          child: const Text('提交举报'),
        ),
      ],
    );
  }
}
