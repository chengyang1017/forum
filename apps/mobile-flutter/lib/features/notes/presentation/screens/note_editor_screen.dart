import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart' as auth_cubit;
import '../../domain/models/note_model.dart';
import '../../data/services/note_service.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';

import '../../../language/data/forum_languages.dart';
import '../../../../app/l10n/app_localizations.dart';
import '../../../post/presentation/screens/create_post_screen.dart';

class NoteEditorScreen extends StatefulWidget {
  final String noteId;

  const NoteEditorScreen({super.key, required this.noteId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _bodyController = quill.QuillController.basic();
  final _editorFocusNode = FocusNode();
  final _editorScrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _noteService = NoteService();

  static const List<String> _publishCategoryIds = [
    'language_learning',
    'programming',
    'ai',
    'technology',
    'gaming',
    'music',
    'movies',
    'campus',
    'startup',
    'friends',
    'travel',
    'chat',
    'love',
    'food',
  ];

  StreamSubscription<NoteModel?>? _noteSubscription;
  Timer? _saveTimer;

  String? _currentUserId;
  String? _ownerId;

  String? _category;
  String? _languageCode;

  List<String> _sharedUserIds = [];
  bool _isUpdatingMembers = false;

  bool _initialized = false;
  bool _allowOthersEdit = false;
  bool _isLoaded = false;
  bool _isDeleted = false;
  bool _isUploadingImage = false;
  bool _titleDirty = false;
  bool _bodyDirty = false;
  bool _applyingRemoteBody = false;
  bool _isSaving = false;

  int _titleRevision = 0;
  int _bodyRevision = 0;

  bool get _isOwner {
    return _currentUserId != null && _currentUserId == _ownerId;
  }

  bool get _canEdit {
    return _isOwner || _allowOthersEdit;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) {
      return;
    }

    _initialized = true;
    _currentUserId = context.read<auth_cubit.AuthCubit>().user?.id;

    if (_currentUserId == null) {
      _isLoaded = true;
      return;
    }

    _bodyController.addListener(_onBodyChanged);
    _listenToNote();
  }

  void _listenToNote() {
    _noteSubscription = _noteService
        .watchNote(widget.noteId)
        .listen(_applyRemoteNote, onError: _handleNoteError);
  }

  void _applyRemoteNote(NoteModel? note) {
    if (!mounted) {
      return;
    }

    if (note == null) {
      setState(() {
        _isDeleted = true;
        _isLoaded = true;
      });
      return;
    }

    if (!_titleDirty) {
      _replaceTitle(note.title);
    }

    if (!_bodyDirty) {
      _replaceBodyFromRemote(
        bodyDelta: note.bodyDelta,
        fallbackContent: note.content,
      );
    }

    final canEdit = note.ownerId == _currentUserId || note.allowOthersEdit;

    _bodyController.readOnly = !canEdit;

    setState(() {
      _ownerId = note.ownerId;

      _category = note.category;
      _languageCode = note.languageCode;

      _sharedUserIds = List<String>.from(note.sharedUserIds);

      _allowOthersEdit = note.allowOthersEdit;

      _isDeleted = false;
      _isLoaded = true;
    });
  }

  void _replaceTitle(String title) {
    if (_titleController.text == title) {
      return;
    }

    final oldOffset = _titleController.selection.baseOffset;
    final safeOffset = min(max(oldOffset, 0), title.length);

    _titleController.value = TextEditingValue(
      text: title,
      selection: TextSelection.collapsed(offset: safeOffset),
    );
  }

  void _replaceBodyFromRemote({
    required List<dynamic> bodyDelta,
    required String fallbackContent,
  }) {
    try {
      final normalizedDelta = bodyDelta.isEmpty
          ? <dynamic>[
              <String, dynamic>{
                'insert': fallbackContent.isEmpty
                    ? '\n'
                    : fallbackContent.endsWith('\n')
                    ? fallbackContent
                    : '$fallbackContent\n',
              },
            ]
          : bodyDelta;

      /*
     * 内容完全相同就不要重新设置 document。
     *
     * 这是解决输入法跳动最关键的一步。
     */
      final currentDeltaJson = jsonEncode(
        _bodyController.document.toDelta().toJson(),
      );

      final remoteDeltaJson = jsonEncode(normalizedDelta);

      if (currentDeltaJson == remoteDeltaJson) {
        return;
      }

      final document = quill.Document.fromJson(normalizedDelta);

      final oldOffset = _bodyController.selection.baseOffset;

      _applyingRemoteBody = true;

      _bodyController.document = document;

      final maximumOffset = max(0, document.length - 1);

      final safeOffset = min(max(oldOffset, 0), maximumOffset);

      _bodyController.updateSelection(
        TextSelection.collapsed(offset: safeOffset),
        quill.ChangeSource.local,
      );
    } catch (error) {
      debugPrint('读取富文本失败：$error');

      final content = fallbackContent.isEmpty
          ? '\n'
          : fallbackContent.endsWith('\n')
          ? fallbackContent
          : '$fallbackContent\n';

      final currentPlainText = _bodyController.document.toPlainText();

      if (currentPlainText == content) {
        return;
      }

      _applyingRemoteBody = true;

      _bodyController.document = quill.Document.fromJson([
        <String, dynamic>{'insert': content},
      ]);
    } finally {
      _applyingRemoteBody = false;
    }
  }

  void _handleNoteError(Object error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoaded = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('加载笔记失败：$error'), backgroundColor: Colors.red),
    );
  }

  void _onTitleChanged(String value) {
    if (!_canEdit) {
      return;
    }

    _titleDirty = true;
    _titleRevision++;

    _scheduleSave();
  }

  void _onBodyChanged() {
    if (_applyingRemoteBody || !_canEdit) {
      return;
    }

    _bodyDirty = true;
    _bodyRevision++;

    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 350), _saveNow);
  }

  Future<void> _saveNow() async {
    final userId = _currentUserId;

    if (userId == null || !_canEdit || !_isLoaded || _isDeleted) {
      return;
    }

    /*
   * 防止上一次保存还没结束，
   * 下一次保存又同时开始。
   */
    if (_isSaving) {
      return;
    }

    final saveTitle = _titleDirty;
    final saveBody = _bodyDirty;

    if (!saveTitle && !saveBody) {
      return;
    }

    /*
   * 记录本次保存开始时的版本。
   *
   * 保存过程中用户可能继续输入，
   * 只有版本没有变化，才能把 dirty 清除。
   */
    final savingTitleRevision = _titleRevision;

    final savingBodyRevision = _bodyRevision;

    final title = saveTitle ? _titleController.text : null;

    final bodyDelta = saveBody
        ? _bodyController.document.toDelta().toJson()
        : null;

    final content = saveBody
        ? _bodyController.document.toPlainText().trim()
        : null;

    _isSaving = true;

    try {
      await _noteService.updateNote(
        noteId: widget.noteId,
        userId: userId,
        title: title,
        content: content,
        bodyDelta: bodyDelta,
      );

      /*
     * 保存期间没有继续修改，
     * 才表示当前内容已保存。
     */
      if (saveTitle && _titleRevision == savingTitleRevision) {
        _titleDirty = false;
      }

      if (saveBody && _bodyRevision == savingBodyRevision) {
        _bodyDirty = false;
      }
    } catch (error) {
      /*
     * 这里不需要重新把 dirty 改成 true，
     * 因为保存开始前没有提前清除 dirty。
     */
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$error'), backgroundColor: Colors.red),
      );
    } finally {
      _isSaving = false;

      /*
     * 保存期间又产生了新输入，
     * 再保存最新版本。
     */
      if (mounted && (_titleDirty || _bodyDirty)) {
        _scheduleSave();
      }
    }
  }

  Future<void> _changeEditPermission(bool value) async {
    final userId = _currentUserId;

    if (userId == null || !_isOwner) {
      return;
    }

    final oldValue = _allowOthersEdit;

    setState(() {
      _allowOthersEdit = value;
      _bodyController.readOnly = !(_isOwner || value);
    });

    try {
      await _noteService.updateEditPermission(
        noteId: widget.noteId,
        ownerId: userId,
        allowOthersEdit: value,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _allowOthersEdit = oldValue;
        _bodyController.readOnly = !(_isOwner || oldValue);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('权限设置失败：$error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _manageSharedUsers() async {
    final currentUserId = _currentUserId;

    if (currentUserId == null || !_isOwner || _isUpdatingMembers) {
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(200)
          .get();

      final users = snapshot.docs
          .where((document) => document.id != currentUserId)
          .map(_NoteSharedUser.fromDocument)
          .toList();

      users.sort((first, second) {
        return first.name.compareTo(second.name);
      });

      if (!mounted) {
        return;
      }

      final result = await showModalBottomSheet<Set<String>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) {
          return _SharedMembersPicker(
            users: users,
            selectedUserIds: _sharedUserIds.toSet(),
          );
        },
      );

      if (result == null || !mounted) {
        return;
      }

      setState(() {
        _isUpdatingMembers = true;
      });

      await _noteService.updateSharedUsers(
        noteId: widget.noteId,
        ownerId: currentUserId,
        sharedUserIds: result.toList(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新共享成员失败：$error'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingMembers = false;
        });
      }
    }
  }

  void _onImageButtonPressed() {
    if (!_canEdit) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('创建者没有开放编辑权限')));
      return;
    }

    _insertImageAtCursor();
  }

  Future<void> _insertImageAtCursor() async {
    final userId = _currentUserId;

    if (userId == null || !_canEdit || _isUploadingImage) {
      return;
    }

    if (_countInlineImages() >= 9) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('每条笔记最多插入 9 张图片')));
      return;
    }

    final selectedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (selectedImage == null) {
      return;
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final uploadedImage = await _noteService.uploadInlineImage(
        noteId: widget.noteId,
        userId: userId,
        file: File(selectedImage.path),
      );

      _insertImageEmbed(uploadedImage.imageUrl);
      _bodyDirty = true;
      await _saveNow();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('插入图片失败：$error'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _insertImageEmbed(String imageUrl) {
    final documentLength = _bodyController.document.length;
    final maximumPosition = max(0, documentLength - 1);
    final selection = _bodyController.selection;
    final rawPosition = selection.isValid
        ? selection.baseOffset
        : maximumPosition;
    final insertPosition = rawPosition.clamp(0, maximumPosition).toInt();

    _bodyController.replaceText(
      insertPosition,
      0,
      quill.BlockEmbed.image(imageUrl),
      TextSelection.collapsed(offset: insertPosition + 1),
    );

    _bodyController.replaceText(
      insertPosition + 1,
      0,
      '\n',
      TextSelection.collapsed(offset: insertPosition + 2),
    );

    _bodyController.updateSelection(
      TextSelection.collapsed(offset: insertPosition + 2),
      quill.ChangeSource.local,
    );

    _editorFocusNode.requestFocus();
  }

  int _countInlineImages() {
    final operations = _bodyController.document.toDelta().toJson();

    return operations.where((operation) {
      final insert = operation['insert'];

      return insert is Map && insert.containsKey('image');
    }).length;
  }

  Future<String?> _selectPublishCategory() async {
    final l10n = AppLocalizations.of(context)!;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '选择帖子分类',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: _publishCategoryIds.length,
                    itemBuilder: (context, index) {
                      final category = _publishCategoryIds[index];

                      final categoryName = index < l10n.categoryNames.length
                          ? l10n.categoryNames[index]
                          : category;

                      return ListTile(
                        leading: const Icon(Icons.topic_outlined),
                        title: Text(categoryName),
                        subtitle: Text(category),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(sheetContext, category);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _categoryName(String? category) {
    if (category == null || category.trim().isEmpty) {
      return '未选择';
    }

    final categoryId = category.trim();
    final index = _publishCategoryIds.indexOf(categoryId);

    if (index == -1) {
      return categoryId;
    }

    final l10n = AppLocalizations.of(context)!;

    if (index >= l10n.categoryNames.length) {
      return categoryId;
    }

    return l10n.categoryNames[index];
  }

  Future<void> _changeCategory() async {
    final userId = _currentUserId;

    if (userId == null || !_isOwner) {
      return;
    }

    final category = await _selectPublishCategory();

    if (category == null || !mounted) {
      return;
    }

    final oldCategory = _category;

    setState(() {
      _category = category;
    });

    try {
      await _noteService.updateNote(
        noteId: widget.noteId,
        userId: userId,
        category: category,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _category = oldCategory;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('修改分类失败：$error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<LanguageConfig?> _selectPublishLanguage() async {
    final languages = ForumLanguages.supportedLanguages;

    final uiLanguageCode = Localizations.localeOf(context).languageCode;

    return showModalBottomSheet<LanguageConfig>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '选择主语言',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      final language = languages[index];

                      return ListTile(
                        leading: Text(
                          language.flag,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(language.nameOf(uiLanguageCode)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(sheetContext, language);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _publishAsPost() async {
    // 只有笔记创建者可以发布
    if (!_isOwner) {
      return;
    }

    final userId = _currentUserId;

    if (userId == null) {
      return;
    }

    FocusScope.of(context).unfocus();

    // 先保存当前正在编辑的标题和正文
    await _saveNow();

    if (!mounted) {
      return;
    }

    // =========================
    // 分类
    // =========================

    String? category = _category?.trim();

    // 笔记没有分类，发布时才要求选择
    if (category == null || category.isEmpty) {
      final selectedCategory = await _selectPublishCategory();

      if (selectedCategory == null || !mounted) {
        return;
      }

      category = selectedCategory;

      // 顺便保存到笔记
      await _noteService.updateNote(
        noteId: widget.noteId,
        userId: userId,
        category: selectedCategory,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _category = selectedCategory;
      });
    }

    // =========================
    // 语言
    // =========================

    String? languageCode = _languageCode?.trim();

    LanguageConfig? selectedLanguage;

    // 笔记没有语言，发布时才要求选择
    if (languageCode == null || languageCode.isEmpty) {
      selectedLanguage = await _selectPublishLanguage();

      if (selectedLanguage == null || !mounted) {
        return;
      }

      languageCode = selectedLanguage.code;

      // 顺便保存到笔记
      await _noteService.updateNote(
        noteId: widget.noteId,
        userId: userId,
        languageCode: selectedLanguage.code,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _languageCode = selectedLanguage!.code;
      });
    }

    // =========================
    // 到这里发布所需字段一定存在
    // =========================

    if (category.isEmpty || languageCode.isEmpty) {
      return;
    }

    final String publishCategory = category;

    final String publishLanguageCode = languageCode;

    // =========================
    // 获取语言显示名称
    // =========================

    final uiLanguageCode = Localizations.localeOf(context).languageCode;

    String languageName = publishLanguageCode;

    // 如果刚才选择了语言，直接使用
    if (selectedLanguage != null) {
      languageName = selectedLanguage.nameOf(uiLanguageCode);
    } else {
      // 如果笔记本来就已经有语言，
      // 根据 languageCode 找对应语言名称
      for (final language in ForumLanguages.supportedLanguages) {
        if (language.code == publishLanguageCode) {
          languageName = language.nameOf(uiLanguageCode);

          break;
        }
      }
    }

    // =========================
    // 笔记正文
    // =========================

    final bodyDelta = _bodyController.document.toDelta().toJson();

    // =========================
    // 进入发帖页
    // =========================

    final published = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          category: publishCategory,

          languageCode: publishLanguageCode,

          languageName: languageName,

          initialTitle: _titleController.text.trim(),

          initialBodyDelta: bodyDelta,

          sourceNoteId: widget.noteId,
        ),
      ),
    );

    if (published == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('笔记已发布为帖子'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteNote() async {
    if (!_isOwner) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除共享笔记？'),
          content: const Text('删除后，这条笔记会从双方的笔记列表中消失。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _noteService.deleteNote(widget.noteId);

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$error'), backgroundColor: Colors.red),
      );
    }
  }

  void _showNoteSettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isOwner)
                    ListTile(
                      leading: const Icon(Icons.publish_outlined),
                      title: const Text('发布为帖子'),
                      subtitle: const Text('使用笔记分类，选择主语言后进入发帖页'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(sheetContext);

                        _publishAsPost();
                      },
                    ),
                  if (_isOwner)
                    ListTile(
                      leading: const Icon(Icons.topic_outlined),
                      title: const Text('帖子分类'),
                      subtitle: Text(_categoryName(_category)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(sheetContext);

                        _changeCategory();
                      },
                    ),
                  if (_isOwner)
                    ListTile(
                      leading: const Icon(Icons.group_outlined),
                      title: const Text('共享成员'),
                      subtitle: Text(
                        _sharedUserIds.isEmpty
                            ? '当前仅自己可见'
                            : '已共享给 '
                                  '${_sharedUserIds.length} 人',
                      ),
                      trailing: _isUpdatingMembers
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _isUpdatingMembers
                          ? null
                          : () {
                              Navigator.pop(sheetContext);

                              _manageSharedUsers();
                            },
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.group_outlined),
                      title: const Text('共享成员'),
                      subtitle: Text('共 ${_sharedUserIds.length + 1} 人'),
                    ),

                  if (_isOwner)
                    SwitchListTile(
                      title: const Text('允许共享成员编辑'),
                      subtitle: Text(
                        _allowOthersEdit ? '共享成员可以修改文字和图片' : '共享成员只能查看这条笔记',
                      ),
                      value: _allowOthersEdit,
                      onChanged: (value) async {
                        setSheetState(() {
                          _allowOthersEdit = value;
                        });

                        await _changeEditPermission(value);
                      },
                    )
                  else
                    ListTile(
                      leading: Icon(
                        _canEdit ? Icons.edit_outlined : Icons.lock_outline,
                      ),
                      title: Text(_canEdit ? '你可以编辑这条笔记' : '这条笔记只能查看'),
                    ),

                  if (_isOwner)
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      title: const Text(
                        '删除笔记',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);

                        _deleteNote();
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    unawaited(_saveNow());

    _noteSubscription?.cancel();
    _bodyController.removeListener(_onBodyChanged);
    _titleController.dispose();
    _bodyController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('共享笔记')),
        body: const Center(child: Text('请先登录')),
      );
    }

    if (_isDeleted) {
      return Scaffold(
        appBar: AppBar(title: const Text('共享笔记')),
        body: const Center(child: Text('这条笔记已被删除')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(child: _buildEditor()),
      bottomNavigationBar: _canEdit
          ? SafeArea(
              top: false,
              child: Material(
                elevation: 8,
                color: Theme.of(context).colorScheme.surface,
                child: _buildToolbar(),
              ),
            )
          : null,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('共享笔记'),
      actions: [
        IconButton(
          tooltip: '插入图片',
          onPressed: _isUploadingImage ? null : _onImageButtonPressed,
          icon: _isUploadingImage
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.add_photo_alternate_outlined,
                  color: _canEdit ? null : Colors.grey,
                ),
        ),
        IconButton(
          tooltip: '笔记设置',
          onPressed: _showNoteSettings,
          icon: const Icon(Icons.more_vert),
        ),
      ],
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: TextField(
            controller: _titleController,
            readOnly: !_canEdit,
            onChanged: _onTitleChanged,
            maxLines: 1,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: '笔记标题',
              border: InputBorder.none,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: quill.QuillEditor(
            controller: _bodyController,
            focusNode: _editorFocusNode,
            scrollController: _editorScrollController,
            config: quill.QuillEditorConfig(
              placeholder: '输入笔记内容……',
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
              embedBuilders: FlutterQuillEmbeds.editorBuilders(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return SizedBox(
      height: 48,
      child: quill.QuillSimpleToolbar(
        controller: _bodyController,
        config: const quill.QuillSimpleToolbarConfig(
          multiRowsDisplay: false,
          showFontFamily: false,
          showFontSize: false,
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showStrikeThrough: false,
          showColorButton: false,
          showBackgroundColorButton: false,
          showClearFormat: true,
          showAlignmentButtons: false,
          showHeaderStyle: true,
          showListNumbers: true,
          showListBullets: true,
          showListCheck: true,
          showCodeBlock: false,
          showQuote: true,
          showIndent: false,
          showLink: false,
          showUndo: true,
          showRedo: true,
          showSearchButton: false,
          showSubscript: false,
          showSuperscript: false,
        ),
      ),
    );
  }
}

class _SharedMembersPicker extends StatefulWidget {
  final List<_NoteSharedUser> users;
  final Set<String> selectedUserIds;

  const _SharedMembersPicker({
    required this.users,
    required this.selectedUserIds,
  });

  @override
  State<_SharedMembersPicker> createState() => _SharedMembersPickerState();
}

class _SharedMembersPickerState extends State<_SharedMembersPicker> {
  final _searchController = TextEditingController();

  late final Set<String> _selectedUserIds;

  String _keyword = '';

  @override
  void initState() {
    super.initState();

    _selectedUserIds = Set<String>.from(widget.selectedUserIds);
  }

  List<_NoteSharedUser> get _visibleUsers {
    final keyword = _keyword.trim().toLowerCase();

    if (keyword.isEmpty) {
      return widget.users;
    }

    return widget.users.where((user) {
      return user.name.toLowerCase().contains(keyword) ||
          user.username.toLowerCase().contains(keyword);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = _visibleUsers;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.78,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '共享成员',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedUserIds);
                    },
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _keyword = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: '搜索昵称或用户名',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: users.isEmpty
                  ? const Center(child: Text('没有找到用户'))
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];

                        final selected = _selectedUserIds.contains(user.id);

                        return CheckboxListTile(
                          value: selected,
                          secondary: CircleAvatar(
                            backgroundImage:
                                user.avatarUrl != null &&
                                    user.avatarUrl!.isNotEmpty
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child:
                                user.avatarUrl == null ||
                                    user.avatarUrl!.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(user.name),
                          subtitle: user.username.isEmpty
                              ? null
                              : Text('@${user.username}'),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedUserIds.add(user.id);
                              } else {
                                _selectedUserIds.remove(user.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteSharedUser {
  final String id;
  final String name;
  final String username;
  final String? avatarUrl;

  const _NoteSharedUser({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
  });

  factory _NoteSharedUser.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    final nickname = data['nickname']?.toString().trim();

    final displayName = data['displayName']?.toString().trim();

    final username = data['username']?.toString().trim() ?? '';

    final email = data['email']?.toString().trim();

    final name = nickname != null && nickname.isNotEmpty
        ? nickname
        : displayName != null && displayName.isNotEmpty
        ? displayName
        : username.isNotEmpty
        ? username
        : email != null && email.isNotEmpty
        ? email
        : '用户';

    final avatarUrl =
        data['avatarUrl']?.toString().trim() ??
        data['avatar']?.toString().trim() ??
        data['photoUrl']?.toString().trim();

    return _NoteSharedUser(
      id: document.id,
      name: name,
      username: username,
      avatarUrl: avatarUrl,
    );
  }
}
