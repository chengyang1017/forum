import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../notes/domain/repositories/note_repository.dart';
import '../../../post/domain/models/post_model.dart';
import '../../../post/domain/repositories/post_repository.dart';
import '../../data/services/ai_translation_service.dart';

enum TranslationMode { manual, ai }

class PostTranslationScreen extends StatefulWidget {
  final PostModel post;

  final String targetLanguageCode;
  final String targetLanguageName;

  final TranslationMode mode;

  const PostTranslationScreen({
    super.key,
    required this.post,
    required this.targetLanguageCode,
    required this.targetLanguageName,
    required this.mode,
  });

  @override
  State<PostTranslationScreen> createState() {
    return _PostTranslationScreenState();
  }
}

class _PostTranslationScreenState extends State<PostTranslationScreen> {
  final AiTranslationService _aiTranslationService = AiTranslationService();

  late final TextEditingController _titleController;

  late final TextEditingController _contentController;

  bool _isTranslating = false;

  bool _saving = false;

  bool _savingToNote = false;

  bool _isEditingAiTranslation = false;

  String _aiPreviewTitle = '';

  String _aiPreviewContent = '';

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();

    _contentController = TextEditingController();

    if (widget.mode == TranslationMode.ai) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _translateWithAi();
      });
    }
  }

  Future<void> _translateWithAi() async {
    if (_isTranslating) {
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      final result = await _aiTranslationService.translatePost(
        title: widget.post.title?.trim() ?? '',

        content: widget.post.content?.trim() ?? '',

        sourceLanguageCode:
            widget.post.languageCode ?? widget.post.primaryLanguageCode ?? '',

        targetLanguageCode: widget.targetLanguageCode,

        targetLanguageName: widget.targetLanguageName,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _aiPreviewTitle = result.title;

        _aiPreviewContent = result.content;

        _titleController.text = result.title;

        _contentController.text = result.content;

        _isEditingAiTranslation = false;

        _isTranslating = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isTranslating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.get('aiTranslationFailed'),
          ),
        ),
      );
    }
  }

  void _editAiTranslation() {
    setState(() {
      _isEditingAiTranslation = true;
    });
  }

  void _cancelAiEditing() {
    setState(() {
      _titleController.text = _aiPreviewTitle;

      _contentController.text = _aiPreviewContent;

      _isEditingAiTranslation = false;
    });
  }

  Future<void> _saveTranslationToNote() async {
    if (_savingToNote || _saving) {
      return;
    }

    final userId = BlocProvider.of<AuthCubit>(context).user?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.get('pleaseSignIn')),
        ),
      );

      return;
    }

    final finalTitle = _titleController.text.trim();

    final finalContent = _contentController.text.trim();

    if (finalTitle.isEmpty || finalContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.get('completeTranslationFirst'),
          ),
        ),
      );

      return;
    }

    setState(() {
      _savingToNote = true;
    });

    try {
      final noteRepository = context.read<NoteRepository>();

      await noteRepository.createNote(
        ownerId: userId,

        title: finalTitle,

        content: finalContent,

        bodyDelta: [
          {'insert': '$finalContent\n'},
        ],

        sourceType: 'translation',

        sourceId: widget.post.id,

        // 直接继承帖子分类
        category: widget.post.category,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.get('translationSavedToNotes'),
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.get('saveToNotesFailed')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingToNote = false;
        });
      }
    }
  }

  Future<void> _publishTranslation() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.get('completeTranslationFirst'),
          ),
        ),
      );

      return;
    }

    final postRepository = Provider.of<PostRepository>(context, listen: false);

    setState(() {
      _saving = true;
    });

    try {
      final finalTitle = _titleController.text.trim();

      final finalContent = _contentController.text.trim();

      final aiWasEdited =
          widget.mode == TranslationMode.ai &&
          (finalTitle != _aiPreviewTitle.trim() ||
              finalContent != _aiPreviewContent.trim());

      await postRepository.addLanguageVersion(
        postId: widget.post.id,

        languageCode: widget.targetLanguageCode,

        languageName: widget.targetLanguageName,

        title: finalTitle,

        content: finalContent,

        type: widget.mode == TranslationMode.manual
            ? 'manual'
            : aiWasEdited
            ? 'ai_assisted'
            : 'ai',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.getWithArgs(
              'languageVersionPublished',
              {'language': widget.targetLanguageName},
            ),
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.get('publishTranslationFailed'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _buildAiActions() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _savingToNote || _saving ? null : _saveTranslationToNote,

            icon: _savingToNote
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.note_add_outlined),

            label: Text(
              _savingToNote ? l10n.get('saving') : l10n.get('saveToNotes'),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: FilledButton.icon(
            onPressed: _saving || _savingToNote ? null : _publishTranslation,

            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.publish),

            label: Text(
              _saving ? l10n.get('publishing') : l10n.get('publishTranslation'),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();

    _contentController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAi = widget.mode == TranslationMode.ai;

    final showAiPreview =
        isAi &&
        !_isTranslating &&
        !_isEditingAiTranslation &&
        _aiPreviewContent.isNotEmpty;

    final showEditor = !isAi || _isEditingAiTranslation;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAi ? l10n.get('aiTranslation') : l10n.get('manualTranslation'),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          Text(
            l10n.getWithArgs('translateToLanguage', {
              'language': widget.targetLanguageName,
            }),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 20),

          if (_isTranslating) ...[
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    CircularProgressIndicator(),

                    SizedBox(height: 16),

                    Text(l10n.get('aiGeneratingTranslation')),
                  ],
                ),
              ),
            ),
          ],

          if (showAiPreview) ...[
            Text(
              l10n.get('aiTranslationPreview'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            if (_aiPreviewTitle.isNotEmpty) ...[
              Text(
                l10n.title,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),

              const SizedBox(height: 6),

              SelectableText(
                _aiPreviewTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),
            ],

            Text(
              l10n.get('bodyLabel'),
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),

            const SizedBox(height: 6),

            SelectableText(
              _aiPreviewContent,
              style: const TextStyle(fontSize: 16, height: 1.7),
            ),

            const SizedBox(height: 32),

            OutlinedButton.icon(
              onPressed: _editAiTranslation,

              icon: const Icon(Icons.edit_outlined),

              label: Text(l10n.get('editTranslation')),
            ),

            const SizedBox(height: 12),

            _buildAiActions(),
          ],

          if (showEditor) ...[
            Text(
              l10n.get('originalTitle'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            SelectableText(widget.post.title ?? ''),

            const SizedBox(height: 20),

            TextField(
              controller: _titleController,

              maxLength: 100,

              decoration: InputDecoration(
                labelText: isAi
                    ? l10n.get('editTranslationTitle')
                    : l10n.get('translationTitle'),

                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              l10n.get('originalText'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            SelectableText(widget.post.content ?? ''),

            const SizedBox(height: 20),

            TextField(
              controller: _contentController,

              minLines: 8,

              maxLines: null,

              maxLength: 5000,

              decoration: InputDecoration(
                labelText: isAi
                    ? l10n.get('editTranslationContent')
                    : l10n.get('translationContent'),

                alignLabelWithHint: true,

                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            if (isAi) ...[
              OutlinedButton(
                onPressed: _cancelAiEditing,

                child: Text(l10n.get('discardChanges')),
              ),

              const SizedBox(height: 12),

              _buildAiActions(),
            ] else
              FilledButton.icon(
                onPressed: _saving || _isTranslating
                    ? null
                    : _publishTranslation,

                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish),

                label: Text(
                  _saving
                      ? l10n.get('publishing')
                      : l10n.get('publishLanguageVersion'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
