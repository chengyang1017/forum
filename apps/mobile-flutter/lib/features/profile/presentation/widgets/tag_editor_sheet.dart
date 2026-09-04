import 'package:flutter/material.dart';
import 'package:glyphora_mobile/app/l10n/app_localizations.dart';

Future<List<String>?> showTagEditorSheet({
  required BuildContext context,
  required List<String> selectedTags,
  required List<String> presetTags,
}) async {
  final selected = List<String>.from(selectedTags);
  final customController = TextEditingController();

  try {
    return await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AnimatedPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          duration: const Duration(milliseconds: 150),
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.editTagsTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, selected),
                      child: Text(
                        context.l10n.done,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (selected.isNotEmpty) ...[
                  Text(
                    context.l10n.selectedTagsCount('${selected.length}'),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selected
                        .map(
                          (tag) => Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(fontSize: 13),
                            ),
                            backgroundColor: Colors.blue.shade50,
                            labelStyle: TextStyle(color: Colors.blue.shade800),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            deleteIcon: Icon(
                              Icons.cancel,
                              size: 16,
                              color: Colors.blue.shade400,
                            ),
                            onDeleted: () =>
                                setModalState(() => selected.remove(tag)),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customController,
                        decoration: InputDecoration(
                          hintText: context.l10n.customTagHint,
                          fillColor: Colors.grey.shade50,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        onSubmitted: (v) {
                          _addTag(v.trim(), selected, setModalState, ctx);
                          customController.clear();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        _addTag(
                          customController.text.trim(),
                          selected,
                          setModalState,
                          ctx,
                        );
                        customController.clear();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(context.l10n.add),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  context.l10n.recommendTags,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: presetTags.map((tag) {
                        final isSelected = selected.contains(tag);
                        return GestureDetector(
                          onTap: () {
                            if (isSelected) {
                              setModalState(() => selected.remove(tag));
                            } else if (selected.length < 10) {
                              setModalState(() => selected.add(tag));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blueAccent
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected
                                    ? Colors.blue.shade800
                                    : Colors.grey.shade700,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  } finally {
    customController.dispose();
  }
}

void _addTag(
  String tag,
  List<String> selected,
  StateSetter setModalState,
  BuildContext ctx,
) {
  if (tag.isEmpty) return;

  if (selected.contains(tag)) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(ctx.l10n.tagExists),
        duration: Duration(seconds: 1),
      ),
    );
    return;
  }

  if (selected.length >= 10) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(ctx.l10n.tagMax), duration: Duration(seconds: 1)),
    );
    return;
  }

  setModalState(() => selected.add(tag));
}
