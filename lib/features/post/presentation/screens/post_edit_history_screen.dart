import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_quill/flutter_quill.dart'
    as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

import '../../data/services/post_service.dart';

class PostEditHistoryScreen
    extends StatelessWidget {
  final String postId;

  const PostEditHistoryScreen({
    super.key,
    required this.postId,
  });

  String _formatTime(
    Timestamp? timestamp,
  ) {
    if (timestamp == null) {
      return '时间未知';
    }

    final time =
        timestamp.toDate();

    final month =
        time.month
            .toString()
            .padLeft(2, '0');

    final day =
        time.day
            .toString()
            .padLeft(2, '0');

    final hour =
        time.hour
            .toString()
            .padLeft(2, '0');

    final minute =
        time.minute
            .toString()
            .padLeft(2, '0');

    return '${time.year}/'
        '$month/'
        '$day '
        '$hour:$minute';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final service =
        PostService();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('编辑历史'),
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream:
            service.watchEditHistory(
          postId,
        ),
        builder:
            (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '加载失败：'
                '${snapshot.error}',
              ),
            );
          }

          final docs =
              snapshot.data?.docs ??
                  [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                '暂无编辑历史',
              ),
            );
          }

          return ListView.separated(
            itemCount:
                docs.length,
            separatorBuilder:
                (_, __) =>
                    const Divider(
              height: 1,
            ),
            itemBuilder:
                (context, index) {
              final data =
                  docs[index]
                      .data();

              final timestamp =
                  data['editedAt']
                      as Timestamp?;

              final languageCode =
                  data['languageCode']
                          ?.toString() ??
                      '';

              final title =
                  data['title']
                          ?.toString() ??
                      '';

              return ListTile(
                leading:
                    const Icon(
                  Icons
                      .history_rounded,
                ),
                title: Text(
                  _formatTime(
                    timestamp,
                  ),
                ),
                subtitle: Column(
  crossAxisAlignment:
      CrossAxisAlignment.start,
  children: [
    if (title.isNotEmpty)
      Text(title),
    Text(
      languageCode.isEmpty
          ? '语言未知'
          : '语言：$languageCode',
    ),
  ],
),
                trailing:
                    const Icon(
                  Icons
                      .chevron_right,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          _PostHistoryDetailScreen(
                        data:
                            data,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PostHistoryDetailScreen
    extends StatefulWidget {
  final Map<String, dynamic>
      data;

  const _PostHistoryDetailScreen({
    required this.data,
  });

  @override
  State<_PostHistoryDetailScreen>
      createState() =>
          _PostHistoryDetailScreenState();
}

class _PostHistoryDetailScreenState
    extends State<
        _PostHistoryDetailScreen> {
  late final quill.QuillController
      _controller;

  @override
  void initState() {
    super.initState();

    final bodyDelta =
        (widget.data['bodyDelta']
                    as List<dynamic>?)
                ?.map((e) => e)
                .toList() ??
            const [];

    final content =
        widget.data['content']
                ?.toString() ??
            '';

    final document =
        bodyDelta.isNotEmpty
            ? quill.Document.fromJson(
                bodyDelta,
              )
            : quill.Document.fromJson(
                [
                  {
                    'insert':
                        '$content\n',
                  },
                ],
              );

    _controller =
        quill.QuillController(
      document: document,
      selection:
          const TextSelection
              .collapsed(
        offset: 0,
      ),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final title =
        widget.data['title']
                ?.toString() ??
            '';

    final images =
        (widget.data['imageUrls']
                    as List<dynamic>?)
                ?.map(
                  (e) =>
                      e.toString(),
                )
                .toList() ??
            const <String>[];

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('历史版本'),
      ),
      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,
          children: [
            if (title.isNotEmpty) ...[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (images.isNotEmpty)
              SizedBox(
                height: 180,
                child:
                    ListView.separated(
                  scrollDirection:
                      Axis.horizontal,
                  itemCount:
                      images.length,
                  separatorBuilder:
                      (_, __) =>
                          const SizedBox(
                    width: 8,
                  ),
                  itemBuilder:
                      (context, index) {
                    return ClipRRect(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                      child:
                          Image.network(
                        images[index],
                        width: 150,
                        height: 180,
                        fit:
                            BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),

            if (images.isNotEmpty)
              const SizedBox(
                height: 20,
              ),

            quill.QuillEditor.basic(
              controller:
                  _controller,
              config:
                  quill
                      .QuillEditorConfig(
                scrollable:
                    false,
                showCursor:
                    false,
                padding:
                    EdgeInsets.zero,
                embedBuilders:
                    FlutterQuillEmbeds
                        .editorBuilders(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}