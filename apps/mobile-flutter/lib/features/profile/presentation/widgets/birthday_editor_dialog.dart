import 'package:flutter/material.dart';

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
  bool tempShowAge = showAge;
  int tempYear = birthday?.year ?? 2000;
  int tempMonth = birthday?.month ?? 1;
  int tempDay = birthday?.day ?? 1;

  return showDialog<BirthdayEditorResult>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '设置生日',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择你的出生日期',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPicker(
                  tempYear == 2000 ? 'Y' : '$tempYear',
                  80,
                  (i) => DateTime.now().year - i,
                  (v) => setDialogState(() => tempYear = v),
                ),
                const SizedBox(width: 2),
                const Text(
                  '年',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(width: 4),
                _buildPicker(
                  tempMonth == 1 ? 'M' : '$tempMonth',
                  12,
                  (i) => i + 1,
                  (v) => setDialogState(() => tempMonth = v),
                ),
                const SizedBox(width: 2),
                const Text(
                  '月',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(width: 4),
                _buildPicker(
                  tempDay == 1 ? 'D' : '$tempDay',
                  31,
                  (i) => i + 1,
                  (v) => setDialogState(() => tempDay = v),
                ),
                const SizedBox(width: 2),
                const Text(
                  '日',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            if (birthday != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton(
                  onPressed: () => setDialogState(() {
                    tempYear = 2000;
                    tempMonth = 1;
                    tempDay = 1;
                  }),
                  child: const Text(
                    '清除生日',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.blue,
              title: const Text('公开年龄', style: TextStyle(fontSize: 14)),
              subtitle: const Text('关闭后仅自己可见', style: TextStyle(fontSize: 12)),
              value: tempShowAge,
              onChanged: (v) => setDialogState(() => tempShowAge = v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.black87)),
          ),
          TextButton(
            onPressed: () {
              final date = DateTime(tempYear, tempMonth, tempDay);
              Navigator.pop(
                context,
                BirthdayEditorResult(
                  birthday: _isDefaultBirthday(date) ? null : date,
                  showAge: tempShowAge,
                ),
              );
            },
            child: const Text(
              '保存',
              style: TextStyle(fontWeight: FontWeight.bold),
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
          Text(
            currentValue,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
        ],
      ),
    ),
  );
}

bool _isDefaultBirthday(DateTime? date) {
  return date == null ||
      (date.year == 2000 && date.month == 1 && date.day == 1);
}
