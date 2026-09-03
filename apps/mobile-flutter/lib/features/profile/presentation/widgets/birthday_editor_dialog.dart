import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';

class BirthdayEditorResult {
  final DateTime? birthday;
  final bool showAge;

  const BirthdayEditorResult({required this.birthday, required this.showAge});
}

Future<BirthdayEditorResult?> showBirthdayEditorDialog({
  required BuildContext context,
  required DateTime? birthday,
  required bool showAge,
}) async {
  final l10n = AppLocalizations.of(context)!;
  bool tempShowAge = showAge;
  bool hasDate = birthday != null;
  int tempYear = birthday?.year ?? 2000;
  int tempMonth = birthday?.month ?? 1;
  int tempDay = birthday?.day ?? 1;

  void normalizeDay() {
    final maxDay = DateUtils.getDaysInMonth(tempYear, tempMonth);
    if (tempDay > maxDay) {
      tempDay = maxDay;
    }
  }

  return showDialog<BirthdayEditorResult>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.setBirthday,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.selectBirthDate,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPicker(
                  hasDate ? '$tempYear' : 'Y',
                  80,
                  (i) => DateTime.now().year - i,
                  (v) => setDialogState(() {
                    tempYear = v;
                    hasDate = true;
                    normalizeDay();
                  }),
                ),
                const SizedBox(width: 2),
                Text(l10n.year, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                _buildPicker(
                  hasDate ? '$tempMonth' : 'M',
                  12,
                  (i) => i + 1,
                  (v) => setDialogState(() {
                    tempMonth = v;
                    hasDate = true;
                    normalizeDay();
                  }),
                ),
                const SizedBox(width: 2),
                Text(l10n.month, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                _buildPicker(
                  hasDate ? '$tempDay' : 'D',
                  DateUtils.getDaysInMonth(tempYear, tempMonth),
                  (i) => i + 1,
                  (v) => setDialogState(() {
                    tempDay = v;
                    hasDate = true;
                  }),
                ),
                const SizedBox(width: 2),
                Text(l10n.day, style: const TextStyle(fontSize: 14)),
              ],
            ),
            if (birthday != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton(
                  onPressed: () => setDialogState(() {
                    hasDate = false;
                  }),
                  child: Text(
                    l10n.clearBirthday,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.blue,
              title: Text(l10n.showAge, style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                l10n.showAgeDesc,
                style: const TextStyle(fontSize: 12),
              ),
              value: tempShowAge,
              onChanged: (v) => setDialogState(() => tempShowAge = v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              normalizeDay();
              final date = DateTime(tempYear, tempMonth, tempDay);
              Navigator.pop(
                context,
                BirthdayEditorResult(
                  birthday: hasDate ? date : null,
                  showAge: tempShowAge,
                ),
              );
            },
            child: Text(
              l10n.save,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildPicker(
  String currentValue,
  int count,
  int Function(int) valueBuilder,
  Function(int) onChanged,
) {
  return PopupMenuButton<int>(
    offset: const Offset(0, 40),
    itemBuilder: (context) => List.generate(count, (i) {
      final val = valueBuilder(i);
      return PopupMenuItem(
        value: val,
        child: Text('$val', style: const TextStyle(fontSize: 14)),
      );
    }),
    onSelected: onChanged,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(currentValue, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
        ],
      ),
    ),
  );
}
