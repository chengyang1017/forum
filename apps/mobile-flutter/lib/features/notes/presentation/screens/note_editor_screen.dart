import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/constants/forum_categories.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart' as auth_cubit;
import '../../../discover/domain/models/discover_user.dart';
import '../../../discover/domain/repositories/discover_repository.dart';
import '../../../language/data/forum_languages.dart';
import '../../../post/presentation/screens/create_post_screen.dart';
import '../../application/models/local_note_image.dart';
import '../../application/ports/note_media_repository.dart';
import '../../domain/models/note_model.dart';
import '../../domain/repositories/note_repository.dart';

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

  late final NoteRepository _noteRepository;
  late final NoteMediaRepository _noteMediaRepository;
  late final DiscoverRepository _discoverRepository;

  List<String> get _publishCategoryIds => ForumCategories.roots
      .map((category) => category.id)
      .toList(growable: false);

  StreamSubscription<NoteModel?>? _noteSubscription;
  Timer? _saveTimer;

  String? _currentUserId;
  String? _ownerId;
  String? _category;
  String? _languageCode;

  List<String> _sharedUserIds = [];
  bool _isUpdatingMembers = false;

  bool _initialized = false;
  bool _isParticipant = false;
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
    return _isOwner || (_isParticipant && _allowOthersEdit);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) {
      return;
    }

    _initialized = true;
    _noteRepository = context.read<NoteRepository>();
    _noteMediaRepository = context.read<NoteMediaRepository>();
    _discoverRepository = context.read<DiscoverRepository>();
    _currentUserId = context.read<auth_cubit.AuthCubit>().user?.id;

    if (_currentUserId == null) {
      _isLoaded = true;
      return;
    }

    _bodyController.addListener(_onBodyChanged);
    _listenToNote();
  }

  void _listenToNote() {
    _noteSubscription = _noteRepository
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

    final currentUserId = _currentUserId;
    final isParticipant =
        currentUserId != null && note.participantIds.contains(currentUserId);
    final canEdit = currentUserId != null && note.canEdit(currentUserId);

    _bodyController.readOnly = !canEdit;

    setState(() {
      _ownerId = note.ownerId;
      _category = note.category;
      _languageCode = note.languageCode;
      _sharedUserIds = List<String>.from(note.sharedUserIds);
      _isParticipant = isParticipant;
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
      SnackBar(
        content: Text('${context.l10n.notesLoadFailed}: $error'),
        backgroundColor: Colors.red,
      ),
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

    if (_isSaving) {
      return;
    }

    final saveTitle = _titleDirty;
    final saveBody = _bodyDirty;

    if (!saveTitle && !saveBody) {
      return;
    }

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
      await _noteRepository.updateNote(
        noteId: widget.noteId,
        userId: userId,
        title: title,
        content: content,
        bodyDelta: bodyDelta,
      );

      if (saveTitle && _titleRevision == savingTitleRevision) {
        _titleDirty = false;
      }

      if (saveBody && _bodyRevision == savingBodyRevision) {
        _bodyDirty = false;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.updateFailed}: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isSaving = false;

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
      _bodyController.readOnly = !(_isOwner || (_isParticipant && value));
    });

    try {
      await _noteRepository.updateEditPermission(
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
        _bodyController.readOnly = !(_isOwner || (_isParticipant && oldValue));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.updateFailed}: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _manageSharedUsers() async {
    final currentUserId = _currentUserId;

    if (currentUserId == null || !_isOwner || _isUpdatingMembers) {
      return;
    }

    try {
      final discoverUsers = await _discoverRepository
          .watchAllUsers(currentUserId)
          .first;
      final users = discoverUsers
          .where((user) => user.id != currentUserId)
          .map(
            (user) => _NoteSharedUser.fromDiscoverUser(
              user,
              fallbackName: context.l10n.user,
            ),
          )
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

      await _noteRepository.updateSharedUsers(
        noteId: widget.noteId,
        ownerId: currentUserId,
        sharedUserIds: result.toList(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.updateFailed}: $error'),
          backgroundColor: Colors.red,
        ),
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
      ).showSnackBar(SnackBar(content: Text(context.l10n.editingNotAllowed)));
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
      ).showSnackBar(SnackBar(content: Text(context.l10n.noteImageLimit)));
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
      final imageUrl = await _noteMediaRepository.uploadInlineImage(
        noteId: widget.noteId,
        userId: userId,
        image: LocalNoteImage(
          path: selectedImage.path,
          name: selectedImage.name,
        ),
      );

      _insertImageEmbed(imageUrl);
      _bodyDirty = true;
      await _saveNow();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.updateFailed}: $error'),
          backgroundColor: Colors.red,
        ),
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
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.l10n.selectPostCategory,
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
                      final categoryName = l10n.categoryName(
                        category,
                        fallback: ForumCategories.nameOf(
                          category,
                          Localizations.localeOf(context).languageCode,
                        ),
                      );

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
      return context.l10n.notSelected;
    }

    final categoryId = category.trim();
    final l10n = AppLocalizations.of(context)!;
    return l10n.categoryName(
      categoryId,
      fallback: ForumCategories.nameOf(
        categoryId,
        Localizations.localeOf(context).languageCode,
      ),
    );
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
      await _noteRepository.updateNote(
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
        SnackBar(
          content: Text('${context.l10n.updateFailed}: $error'),
          backgroundColor: Colors.red,
        ),
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
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.l10n.choosePrimaryLanguage,
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
    if (!_isOwner) {
      return;
    }

    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    FocusScope.of(context).unfocus();
    await _saveNow();

    if (!mounted) {
      return;
    }

    String? category = _category?.trim();

    if (category == null || category.isEmpty) {
      final selectedCategory = await _selectPublishCategory();

      if (selectedCategory == null || !mounted) {
        return;
      }

      category = selectedCategory;

      await _noteRepository.updateNote(
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

    String? languageCode = _languageCode?.trim();
    LanguageConfig? selectedLanguage;

    if (languageCode == null || languageCode.isEmpty) {
      selectedLanguage = await _selectPublishLanguage();

      if (selectedLanguage == null || !mounted) {
        return;
      }

      languageCode = selectedLanguage.code;

      await _noteRepository.updateNote(
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

    if (category.isEmpty || languageCode.isEmpty) {
      return;
    }

    final publishCategory = category;
    final publishLanguageCode = languageCode;
    final uiLanguageCode = Localizations.localeOf(context).languageCode;
    String languageName = publishLanguageCode;

    if (selectedLanguage != null) {
      languageName = selectedLanguage.nameOf(uiLanguageCode);
    } else {
      for (final language in ForumLanguages.supportedLanguages) {
        if (language.code == publishLanguageCode) {
          languageName = language.nameOf(uiLanguageCode);
          break;
        }
      }
    }

    final bodyDelta = _bodyController.document.toDelta().toJson();

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
        SnackBar(
          content: Text(context.l10n.notePublishedAsPost),
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
          title: Text(context.l10n.deleteSharedNote),
          content: Text(context.l10n.deleteSharedNoteDescription),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(context.l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _noteRepository.deleteNote(widget.noteId);

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.updateFailed}: $error'),
          backgroundColor: Colors.red,
        ),
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
                      title: Text(context.l10n.publishAsPost),
                      subtitle: Text(context.l10n.publishAsPostDescription),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _publishAsPost();
                      },
                    ),
                  if (_isOwner)
                    ListTile(
                      leading: const Icon(Icons.topic_outlined),
                      title: Text(context.l10n.postCategory),
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
                      title: Text(context.l10n.sharedMembers),
                      subtitle: Text(
                        _sharedUserIds.isEmpty
                            ? context.l10n.privateNote
                            : context.l10n.sharedWithCount(
                                '${_sharedUserIds.length}',
                              ),
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
                      title: Text(context.l10n.sharedMembers),
                      subtitle: Text(
                        context.l10n.membersCount(
                          '${_sharedUserIds.length + 1}',
                        ),
                      ),
                    ),
                  if (_isOwner)
                    SwitchListTile(
                      title: Text(context.l10n.allowSharedMembersEdit),
                      subtitle: Text(
                        _allowOthersEdit
                            ? context.l10n.sharedMembersCanEdit
                            : context.l10n.sharedMembersViewOnly,
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
                      title: Text(
                        _canEdit
                            ? context.l10n.canEditThisNote
                            : context.l10n.readOnlyNote,
                      ),
                    ),
                  if (_isOwner)
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      title: Text(
                        context.l10n.deleteNote,
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
        appBar: AppBar(title: Text(context.l10n.sharedNote)),
        body: Center(child: Text(context.l10n.pleaseSignIn)),
      );
    }

    if (_isDeleted) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.sharedNote)),
        body: Center(child: Text(context.l10n.noteDeleted)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
      title: Text(context.l10n.sharedNote),
      actions: [
        IconButton(
          tooltip: context.l10n.insertImage,
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
          tooltip: context.l10n.noteSettings,
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
            decoration: InputDecoration(
              hintText: context.l10n.noteTitle,
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
              placeholder: context.l10n.noteContentHint,
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
                  Expanded(
                    child: Text(
                      context.l10n.sharedMembers,
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
                    child: Text(context.l10n.done),
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
                  hintText: context.l10n.searchNicknameOrUsername,
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
                  ? Center(child: Text(context.l10n.noUsersFound))
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

  factory _NoteSharedUser.fromDiscoverUser(
    DiscoverUser user, {
    required String fallbackName,
  }) {
    final name = user.displayName.trim();
    final avatarUrl = user.avatarUrl.trim();

    return _NoteSharedUser(
      id: user.id,
      name: name.isEmpty ? fallbackName : name,
      username: user.username.trim(),
      avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
    );
  }
}
