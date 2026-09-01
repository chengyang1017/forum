import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:provider/provider.dart';

import '../../domain/models/post_edit_history_entry.dart';
import '../../domain/repositories/post_repository.dart';

class PostEditHistoryScreen extends StatefulWidget {
  final String postId;

  const PostEditHistoryScreen({super.key, required this.postId});

  @override
  State<PostEditHistoryScreen> createState() => _PostEditHistoryScreenState();
}

class _PostEditHistoryScreenState extends State<PostEditHistoryScreen> {
  late PostRepository _repository;
  late Future<List<PostEditHistoryEntry>> _historyFuture;
  bool _dependenciesReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_dependenciesReady) {
      return;
    }

    _repository = context.read<PostRepository>();
    _historyFuture = _repository.getEditHistory(widget.postId);
    _dependenciesReady = true;
  }

  Future<void> _reload() async {
    final future = _repository.getEditHistory(widget.postId);

    setState(() {
      _historyFuture = future;
    });

    await future;
  }

  String _formatTime(DateTime? time) {
    if (time == null) {
      return '时间未知';
    }

    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '${time.year}/$month/$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('编辑历史')),
      body: FutureBuilder<List<PostEditHistoryEntry>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }

          final history = snapshot.data ?? const <PostEditHistoryEntry>[];

          if (history.isEmpty) {
            return const Center(child: Text('暂无编辑历史'));
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = history[index];

                return ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: Text(_formatTime(entry.editedAt)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.title.isNotEmpty) Text(entry.title),
                      Text(
                        entry.languageCode.isEmpty
                            ? '语言未知'
                            : '语言：${entry.languageCode}',
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _PostHistoryDetailScreen(entry: entry),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PostHistoryDetailScreen extends StatefulWidget {
  final PostEditHistoryEntry entry;

  const _PostHistoryDetailScreen({required this.entry});

  @override
  State<_PostHistoryDetailScreen> createState() =>
      _PostHistoryDetailScreenState();
}

class _PostHistoryDetailScreenState extends State<_PostHistoryDetailScreen> {
  late final quill.QuillController _controller;

  @override
  void initState() {
    super.initState();

    final document = widget.entry.bodyDelta.isNotEmpty
        ? quill.Document.fromJson(widget.entry.bodyDelta)
        : quill.Document.fromJson([
            {'insert': '${widget.entry.content}\n'},
          ]);

    _controller = quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return Scaffold(
      appBar: AppBar(title: const Text('历史版本')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (entry.title.isNotEmpty) ...[
              Text(
                entry.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (entry.imageUrls.isNotEmpty)
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: entry.imageUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        entry.imageUrls[index],
                        width: 150,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            if (entry.imageUrls.isNotEmpty) const SizedBox(height: 20),
            quill.QuillEditor.basic(
              controller: _controller,
              config: quill.QuillEditorConfig(
                scrollable: false,
                showCursor: false,
                padding: EdgeInsets.zero,
                embedBuilders: FlutterQuillEmbeds.editorBuilders(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
