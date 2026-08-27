import {Image, Pressable, StyleSheet, Text, View} from 'react-native';

import type {Post} from '../../models/Post';

const languageNames: Record<string, string> = {
  zh: '中文频道',
  en: '英文频道',
  vi: '越南文频道',
  ms: '马来文频道',
  th: '泰文频道',
  id: '印尼文频道',
  ko: '韩文频道',
  ru: '俄文频道',
  jv: '爪哇文频道',
  kk: '哈萨克文频道',
  chunom: '喃字频道',
};

function formatCreatedAt(date: Date | null): string {
  if (date === null) return '时间未提供';
  const difference = Date.now() - date.getTime();
  if (difference < 0) return '刚刚';
  const minutes = Math.floor(difference / 60_000);
  if (minutes < 1) return '刚刚';
  if (minutes < 60) return `${minutes} 分钟前`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} 小时前`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days} 天前`;
  return `${date.getMonth() + 1}月${date.getDate()}日`;
}

function ImageGrid({images}: {images: string[]}) {
  const visibleImages = images.slice(0, 3);

  return (
    <View style={styles.imageRow}>
      {visibleImages.map((url, index) => {
        const remaining = images.length - 3;
        return (
          <View key={`${url}-${index}`} style={styles.imageCell}>
            <Image resizeMode="cover" source={{uri: url}} style={styles.image} />
            {index === 2 && remaining > 0 ? (
              <View style={styles.imageOverlay}>
                <Text style={styles.imageOverlayText}>+{remaining}</Text>
              </View>
            ) : null}
          </View>
        );
      })}
    </View>
  );
}

export function PostCard({post, onPress}: {post: Post; onPress?: () => void}) {
  const nickname = post.nickname?.trim();
  const username = post.username?.trim();
  const author = nickname || (username ? `@${username}` : '匿名用户');
  const avatarLetter = (nickname || username || '匿').slice(0, 1).toUpperCase();
  const language = post.languageCode
    ? languageNames[post.languageCode] ?? post.languageCode
    : null;

  return (
    <Pressable
      accessibilityRole={onPress ? 'button' : undefined}
      onPress={onPress}
      style={({pressed}) => [styles.card, pressed && onPress ? styles.pressed : null]}>
      <View style={styles.titleRow}>
        <Text numberOfLines={2} style={styles.title}>
          {post.title.trim() || '无标题'}
        </Text>
        {language ? (
          <View style={styles.languageBadge}>
            <Text style={styles.languageText}>{language}</Text>
          </View>
        ) : null}
      </View>

      {post.content.trim() ? (
        <Text numberOfLines={post.imageUrls.length ? 3 : 4} style={styles.content}>
          {post.content.trim()}
        </Text>
      ) : null}

      {post.imageUrls.length ? <ImageGrid images={post.imageUrls} /> : null}

      <View style={styles.metadataRow}>
        <View style={styles.authorRow}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>{avatarLetter}</Text>
          </View>
          <Text numberOfLines={1} style={styles.author}>{author}</Text>
        </View>
        <Text style={styles.time}>{formatCreatedAt(post.createdAt)}</Text>
      </View>

      <View style={styles.engagementRow}>
        <View style={styles.engagementItem}>
          <Text style={styles.engagementIcon}>♡</Text>
          <Text style={styles.engagementText}>{post.likeCount}</Text>
        </View>
        <View style={styles.engagementItem}>
          <Text style={styles.engagementIcon}>▢</Text>
          <Text style={styles.engagementText}>{post.commentCount}</Text>
        </View>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {marginHorizontal: 12, marginTop: 12, paddingHorizontal: 16, paddingTop: 16, paddingBottom: 12, borderWidth: 1, borderColor: '#EEF0F3', borderRadius: 14, backgroundColor: '#FFFFFF'},
  titleRow: {flexDirection: 'row', alignItems: 'flex-start', gap: 8},
  title: {flex: 1, color: '#121212', fontSize: 18, fontWeight: '700', lineHeight: 24},
  languageBadge: {paddingHorizontal: 7, paddingVertical: 3, borderWidth: StyleSheet.hairlineWidth, borderColor: '#90CAF9', borderRadius: 5, backgroundColor: '#E3F2FD'},
  languageText: {color: '#1976D2', fontSize: 11, fontWeight: '700'},
  content: {marginTop: 9, color: '#555555', fontSize: 15, lineHeight: 23},
  imageRow: {flexDirection: 'row', gap: 7, marginTop: 11},
  imageCell: {flex: 1, aspectRatio: 1, overflow: 'hidden', borderRadius: 8, backgroundColor: '#F2F3F5'},
  image: {width: '100%', height: '100%'},
  imageOverlay: {position: 'absolute', inset: 0, alignItems: 'center', justifyContent: 'center', backgroundColor: 'rgba(0,0,0,0.45)'},
  imageOverlayText: {color: '#FFFFFF', fontSize: 20, fontWeight: '800'},
  metadataRow: {flexDirection: 'row', alignItems: 'center', marginTop: 14},
  authorRow: {flex: 1, flexDirection: 'row', alignItems: 'center'},
  avatar: {width: 18, height: 18, alignItems: 'center', justifyContent: 'center', borderRadius: 9, backgroundColor: '#E3F2FD'},
  avatarText: {color: '#2196F3', fontSize: 9, fontWeight: '800'},
  author: {flexShrink: 1, marginLeft: 6, color: '#2196F3', fontSize: 14, fontWeight: '600'},
  time: {marginLeft: 8, color: '#999999', fontSize: 13},
  engagementRow: {flexDirection: 'row', gap: 22, marginTop: 11, paddingTop: 10, borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: '#EEF0F3'},
  engagementItem: {flexDirection: 'row', alignItems: 'center', gap: 5},
  engagementIcon: {color: '#64748B', fontSize: 19},
  engagementText: {color: '#64748B', fontSize: 13, fontWeight: '600'},
  pressed: {opacity: 0.82},
});
