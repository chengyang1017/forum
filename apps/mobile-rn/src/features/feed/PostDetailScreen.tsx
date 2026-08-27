import type {NativeStackScreenProps} from '@react-navigation/native-stack';
import {useEffect, useState} from 'react';
import {Image, ScrollView, StyleSheet, Text, View} from 'react-native';

import type {Post} from '../../models/Post';
import type {FeedStackParamList} from '../../navigation/types';
import {postRepository} from '../../repositories/PostRepository';
import {ScreenState} from '../../shared/components/ScreenState';

type Props = NativeStackScreenProps<FeedStackParamList, 'PostDetail'>;

function formatDate(date: Date | null): string {
  if (!date) return '时间未提供';
  try {
    return new Intl.DateTimeFormat('zh-CN', {dateStyle: 'medium', timeStyle: 'short'}).format(date);
  } catch {
    return date.toLocaleString();
  }
}

export function PostDetailScreen({route}: Props) {
  const [post, setPost] = useState<Post | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    postRepository.getPost(route.params.postId)
      .then(value => {
        if (active) setPost(value);
      })
      .catch(error => {
        if (active) setErrorMessage(error instanceof Error ? error.message : '读取帖子失败');
      });
    return () => {
      active = false;
    };
  }, [route.params.postId]);

  if (errorMessage) {
    return <ScreenState kind="error" message={errorMessage} title="无法打开帖子" />;
  }
  if (!post) {
    return <ScreenState kind="loading" title="正在读取帖子…" />;
  }

  const author = post.nickname?.trim() || (post.username ? `@${post.username}` : '匿名用户');

  return (
    <ScrollView contentContainerStyle={styles.content} style={styles.page}>
      <Text style={styles.title}>{post.title.trim() || '无标题'}</Text>
      <View style={styles.authorRow}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{author.slice(0, 1).toUpperCase()}</Text>
        </View>
        <View style={styles.authorText}>
          <Text style={styles.author}>{author}</Text>
          <Text style={styles.time}>{formatDate(post.createdAt)}</Text>
        </View>
        {post.languageCode ? (
          <View style={styles.languageBadge}><Text style={styles.languageText}>{post.languageCode}</Text></View>
        ) : null}
      </View>

      <Text style={styles.body}>{post.content || '（没有文字内容）'}</Text>

      {post.imageUrls.map((url, index) => (
        <Image key={`${url}-${index}`} resizeMode="cover" source={{uri: url}} style={styles.image} />
      ))}

      <View style={styles.stats}>
        <View><Text style={styles.statNumber}>{post.likeCount}</Text><Text style={styles.statLabel}>点赞</Text></View>
        <View style={styles.statDivider} />
        <View><Text style={styles.statNumber}>{post.commentCount}</Text><Text style={styles.statLabel}>评论</Text></View>
      </View>
      <View style={styles.pendingBox}>
        <Text style={styles.pendingText}>点赞和评论写入将在后续阶段实现</Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: {flex: 1, backgroundColor: '#FFFFFF'},
  content: {padding: 18, paddingBottom: 42},
  title: {color: '#121212', fontSize: 26, fontWeight: '800', lineHeight: 35},
  authorRow: {flexDirection: 'row', alignItems: 'center', marginTop: 18, paddingBottom: 16, borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: '#E2E8F0'},
  avatar: {width: 42, height: 42, alignItems: 'center', justifyContent: 'center', borderRadius: 21, backgroundColor: '#E3F2FD'},
  avatarText: {color: '#1976D2', fontSize: 16, fontWeight: '800'},
  authorText: {flex: 1, marginLeft: 10},
  author: {color: '#2196F3', fontSize: 15, fontWeight: '700'},
  time: {marginTop: 3, color: '#94A3B8', fontSize: 12},
  languageBadge: {paddingHorizontal: 9, paddingVertical: 5, borderRadius: 6, backgroundColor: '#E3F2FD'},
  languageText: {color: '#1976D2', fontSize: 12, fontWeight: '700'},
  body: {marginTop: 20, color: '#334155', fontSize: 17, lineHeight: 29},
  image: {width: '100%', aspectRatio: 1.3, marginTop: 14, borderRadius: 12, backgroundColor: '#F1F5F9'},
  stats: {flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 34, marginTop: 24, paddingVertical: 16, borderTopWidth: StyleSheet.hairlineWidth, borderBottomWidth: StyleSheet.hairlineWidth, borderColor: '#E2E8F0'},
  statNumber: {color: '#1E293B', fontSize: 18, fontWeight: '800', textAlign: 'center'},
  statLabel: {marginTop: 2, color: '#64748B', fontSize: 12},
  statDivider: {width: 1, height: 30, backgroundColor: '#E2E8F0'},
  pendingBox: {marginTop: 18, padding: 13, borderRadius: 10, backgroundColor: '#F8FAFC'},
  pendingText: {color: '#94A3B8', fontSize: 12, textAlign: 'center'},
});
