import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/forum_categories.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../application/models/local_post_image.dart';
import '../../application/ports/post_media_repository.dart';
import '../../domain/models/post_model.dart';
import '../../domain/repositories/post_repository.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    required this.category,
    this.categoryId,
    this.categoryPath,
    required this.languageCode,
    required this.languageName,
    this.initialTitle,
    this.initialBodyDelta,
    this.sourceNoteId,
  });

  /// Root category kept for compatibility with legacy category queries.
  final String category;

  /// Currently selected category node.
  final String? categoryId;

  /// Full root-to-current category path.
  final List<String>? categoryPath;

  final String languageCode;
  final String languageName;

  /// Optional note content used when publishing a note as a post.
  final String? initialTitle;
  final List<dynamic>? initialBodyDelta;
  final String? sourceNoteId;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final title = TextEditingController();
  final _bodyController = quill.QuillController.basic();
  final _bodyFocusNode = FocusNode();
  final _bodyScrollController = ScrollController();
  final _imagePicker = ImagePicker();

  late final String _draftPostId;

  final List<File> images = <File>[];

  bool isUploading = false;
  bool _isUploadingInlineImage = false;
  double progress = 0;

  String get _selectedCategoryId => widget.categoryId ?? widget.category;

  PostRepository get _postRepository => Provider.of<PostRepository>(
    context,
    listen: false,
  );

  PostMediaRepository get _mediaRepository => Provider.of<PostMediaRepository>(
    context,
    listen: false,
  );

  List<String> get _resolvedCategoryPath {
    final suppliedPath = widget.categoryPath
        ?.map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (suppliedPath != null && suppliedPath.isNotEmpty) {
      return suppliedPath;
    }

    final derivedPath = ForumCategories.pathOf(_selectedCategoryId);

    if (derivedPath.isNotEmpty) {
      return derivedPath;
    }

    return <String>[widget.category];
  }

  @override
  void initState() {
    super.initState();

    _draftPostId =
        '${DateTime.now().microsecondsSinceEpoch}_'
        '${Random.secure().nextInt(1 << 32)}';

    final initialTitle = widget.initialTitle;
    if (initialTitle != null) {
      title.text = initialTitle;
    }

    final initialBodyDelta = widget.initialBodyDelta;
    if (initialBodyDelta != null && initialBodyDelta.isNotEmpty) {
      _bodyController.document = quill.Document.fromJson(
        List<dynamic>.from(initialBodyDelta),
      );
    }

    _bodyController.addListener(_onBodyChanged);
  }

  void _onBodyChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  String _getCategoryPathLabel(BuildContext context) {
    final uiLanguageCode = Localizations.localeOf(context).languageCode;

    return _resolvedCategoryPath
        .map((id) => ForumCategories.nameOf(id, uiLanguageCode))
        .join(' › ');
  }

  String _getFlag(String code) {
    return LanguageConfig.findByCode(code)?.flag ?? '🌐';
  }

  int _countInlineImages() {
    final operations = _bodyController.document.toDelta().toJson();

    return operations.where((operation) {
      final insert = operation['insert'];
      return insert is Map && insert.containsKey('image');
    }).length;
  }

  int get _totalImageCount => images.length + _countInlineImages();

  String _fileName(File file) {
    final normalized = file.path.replaceAll('\\', '/');
    final segments = normalized.split('/');

    return segments.isEmpty || segments.last.isEmpty ? 'image' : segments.last;
  }

  LocalPostImage _toLocalPostImage(File file) {
    return LocalPostImage(path: file.path, name: _fileName(file));
  }

  Future<void> pickImages() async {
    final remaining = 9 - _totalImageCount;

    if (remaining <= 0) {
      _showMessage('每篇帖子最多添加 9 张图片');
      return;
    }

    final picked = await _imagePicker.pickMultiImage();

    if (picked.isEmpty || !mounted) {
      return;
    }

    setState(() {
      images.addAll(picked.take(remaining).map((image) => File(image.path)));
    });
  }

  Future<void> _showImagePlacementOptions() async {
    if (_totalImageCount >= 9) {
      _showMessage('每篇帖子最多添加 9 张图片');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '图片放在哪里？',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('放在文章顶部'),
                subtitle: const Text('保持原来的图片展示方式'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  pickImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text('插入正文'),
                subtitle: const Text('插入到当前文字光标的位置'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickInlineImage();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickInlineImage() async {
    if (_isUploadingInlineImage || _totalImageCount >= 9) {
      return;
    }

    final selectedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (selectedImage == null || !mounted) {
      return;
    }

    final mediaRepository = _mediaRepository;

    setState(() {
      _isUploadingInlineImage = true;
    });

    try {
      final imageUrl = await mediaRepository.uploadInlineImage(
        _draftPostId,
        LocalPostImage(path: selectedImage.path, name: selectedImage.name),
      );

      if (!mounted) {
        return;
      }

      _insertImageEmbed(imageUrl);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('插入图片失败: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingInlineImage = false;
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
    _bodyFocusNode.requestFocus();
  }

  Future<List<dynamic>> _copyImportedInlineImagesToPost(
    List<dynamic> bodyDelta,
  ) async {
    if (widget.sourceNoteId == null) {
      return bodyDelta;
    }

    final mediaRepository = _mediaRepository;
    final result = <dynamic>[];
    final copiedUrls = <String, String>{};

    for (final rawOperation in bodyDelta) {
      if (rawOperation is! Map) {
        result.add(rawOperation);
        continue;
      }

      final operation = Map<String, dynamic>.from(rawOperation);
      final insert = operation['insert'];

      if (insert is Map && insert['image'] is String) {
        final oldUrl = insert['image'].toString();

        if (oldUrl.isNotEmpty) {
          try {
            final newUrl = copiedUrls[oldUrl] ??
                await mediaRepository.copyInlineImageToPost(
                  _draftPostId,
                  oldUrl,
                );

            copiedUrls[oldUrl] = newUrl;

            final newInsert = Map<String, dynamic>.from(insert);
            newInsert['image'] = newUrl;
            operation['insert'] = newInsert;
          } catch (error) {
            throw Exception('复制笔记正文图片失败：$error');
          }
        }
      }

      result.add(operation);
    }

    return result;
  }

  Future<List<String>> uploadImages(String postId) {
    final media = images.map(_toLocalPostImage).toList(growable: false);

    return _mediaRepository.uploadImages(
      postId,
      media,
      onProgress: (value) {
        if (!mounted) {
          return;
        }

        setState(() {
          progress = value.clamp(0.0, 1.0);
        });
      },
    );
  }

  Future<void> uploadPost() async {
    final user = BlocProvider.of<AuthCubit>(context).user;

    if (user == null) {
      return;
    }

    final postRepository = _postRepository;
    final plainContent = _bodyController.document.toPlainText().trim();
    List<dynamic> bodyDelta = List<dynamic>.from(
      _bodyController.document.toDelta().toJson(),
    );

    if (title.text.trim().isEmpty ||
        (plainContent.isEmpty && _countInlineImages() == 0)) {
      _showMessage('请填写标题和内容');
      return;
    }

    if (plainContent.length > 5000) {
      _showMessage('正文最多 5000 字');
      return;
    }

    setState(() {
      isUploading = true;
      progress = 0;
    });

    try {
      bodyDelta = await _copyImportedInlineImagesToPost(bodyDelta);

      if (widget.sourceNoteId != null) {
        _bodyController.document = quill.Document.fromJson(bodyDelta);
      }

      final postId = _draftPostId;
      final imageUrls = await uploadImages(postId);

      await postRepository.createPost(
        PostModel(
          id: postId,
          userId: user.id,
          title: title.text.trim(),
          content: plainContent,
          bodyDelta: bodyDelta,
          category: widget.category,
          categoryId: _selectedCategoryId,
          categoryPath: _resolvedCategoryPath,
          languageCode: widget.languageCode,
          primaryLanguageCode: widget.languageCode,
          availableLanguageCodes: <String>[widget.languageCode],
          imageUrls: imageUrls,
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('在${widget.languageName}频道发布成功'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      debugPrint('UPLOAD ERROR: $error');

      if (mounted) {
        _showMessage('上传失败: $error', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
          progress = 0;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  void _confirmRemoveImage(int index) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除图片'),
        content: const Text('确定要删除这张图片吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() => images.removeAt(index));
              Navigator.pop(dialogContext);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bodyController.removeListener(_onBodyChanged);
    title.dispose();
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发帖'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPublishingContext(),
            const SizedBox(height: 20),
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildEditor(),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_bodyController.document.toPlainText().trim().length}/5000',
                style: TextStyle(
                  color: _bodyController.document.toPlainText().trim().length > 4500
                      ? Colors.red
                      : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildImageSection(),
            if (images.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildImageGrid(),
            ],
            if (isUploading) ...[
              const SizedBox(height: 20),
              _buildUploadProgress(),
            ],
            const SizedBox(height: 24),
            _buildPublishButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishingContext() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getCategoryPathLabel(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: Colors.blue.shade300),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_getFlag(widget.languageCode)),
                const SizedBox(width: 4),
                Text(
                  widget.languageName,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade400),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: title,
      maxLength: 100,
      decoration: InputDecoration(
        labelText: '标题',
        hintText: '输入帖子标题...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        counterText: '',
        suffixText: '${title.text.length}/100',
        suffixStyle: TextStyle(
          color: title.text.length > 90 ? Colors.red : Colors.grey,
          fontSize: 12,
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildEditor() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 280,
            child: quill.QuillEditor(
              controller: _bodyController,
              focusNode: _bodyFocusNode,
              scrollController: _bodyScrollController,
              config: quill.QuillEditorConfig(
                placeholder: '输入帖子内容……',
                padding: const EdgeInsets.all(14),
                embedBuilders: FlutterQuillEmbeds.editorBuilders(),
              ),
            ),
          ),
          const Divider(height: 1),
          SizedBox(
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
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                '图片（可选）',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '$_totalImageCount/9',
                style: TextStyle(
                  color: _totalImageCount >= 9
                      ? Colors.red
                      : Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed:
                isUploading ||
                    _isUploadingInlineImage ||
                    _totalImageCount >= 9
                ? null
                : _showImagePlacementOptions,
            icon: _isUploadingInlineImage
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate, size: 20),
            label: Text(
              _isUploadingInlineImage
                  ? '正在插入图片...'
                  : _totalImageCount >= 9
                  ? '已达上限'
                  : '添加图片',
            ),
          ),
          if (_isUploadingInlineImage) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text(
              '正在上传并插入正文图片...',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (_, index) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(images[index], fit: BoxFit.cover),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _confirmRemoveImage(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '上传中 ${(progress * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPublishButton() {
    return ElevatedButton(
      onPressed: isUploading || _isUploadingInlineImage ? null : uploadPost,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isUploading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          else
            const Icon(Icons.send_rounded, size: 20),
          const SizedBox(width: 8),
          Text(
            isUploading ? '发布中...' : '发布帖子',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
