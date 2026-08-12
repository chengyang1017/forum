// lib/utils/post_updater.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostUpdater {
  static const String _updateKey = 'old_posts_updated_to_chinese';

  /// 检查是否已经更新过
  static Future<bool> hasUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_updateKey) ?? false;
  }

  /// 一次性更新所有旧帖子为中文，之后不再执行
  static Future<void> updateOldPostsOnce() async {
    // 检查是否已经更新过
    if (await hasUpdated()) {
      print('旧帖子已经更新过，跳过');
      return;
    }

    try {
      print('开始更新旧帖子...');
      final firestore = FirebaseFirestore.instance;

      // 查询所有没有 languageCode 的帖子
      final snapshot = await firestore.collection('posts').get();

      int updatedCount = 0;
      var batch = firestore.batch();
      int batchCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();

        if (!data.containsKey('languageCode')) {
          batch.update(doc.reference, {
            'languageCode': 'zh',
            'languageName': '中文',
          });
          updatedCount++;
          batchCount++;

          // 每 500 条提交一次
          if (batchCount >= 500) {
            await batch.commit();
            batch = firestore.batch();
            batchCount = 0;
            print('已更新 $updatedCount 条...');
          }
        }
      }

      // 提交剩余
      if (batchCount > 0) {
        await batch.commit();
      }

      // 标记已完成更新
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_updateKey, true);

      print('旧帖子更新完成！共更新 $updatedCount 条');
    } catch (e) {
      print('更新旧帖子失败: $e');
      // 失败不标记，下次启动会重试
    }
  }
}
