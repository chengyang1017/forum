import {useEffect, useState} from 'react';
import type {BottomTabNavigationProp} from '@react-navigation/bottom-tabs';
import type {NativeStackScreenProps} from '@react-navigation/native-stack';
import {FlatList, Pressable, SafeAreaView, StyleSheet, Text, View} from 'react-native';

import type {Post} from '../../models/Post';
import type {FeedStackParamList, RootTabParamList} from '../../navigation/types';
import {postRepository} from '../../repositories/PostRepository';
import {ScreenState} from '../../shared/components/ScreenState';
import {useAuth} from '../auth/AuthContext';
import {PostCard} from './PostCard';

type Props = NativeStackScreenProps<FeedStackParamList, 'FeedHome'>;

export function FeedScreen({navigation}: Props) {
  const {profile} = useAuth();
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    const unsubscribe = postRepository.watchPosts(
      nextPosts => {
        setPosts(nextPosts);
        setErrorMessage(null);
        setLoading(false);
      },
      error => {
        setErrorMessage(error.message);
        setLoading(false);
      },
    );
    return unsubscribe;
  }, []);

  const openProfile = () => {
    navigation
      .getParent<BottomTabNavigationProp<RootTabParamList>>()
      ?.navigate('ProfileTab');
  };

  return (
    <SafeAreaView style={styles.page}>
      <View style={styles.appBar}>
        <View style={styles.brandGroup}>
          <View style={styles.brandIcon}><Text style={styles.brandGlyph}>文</Text></View>
          <View>
            <Text style={styles.brand}>万文社</Text>
            <Text style={styles.channel}>全部帖子 · 实时动态</Text>
          </View>
        </View>
        <View style={styles.actions}>
          <Pressable accessibilityLabel="发现用户，尚未开放" disabled style={styles.iconButton}>
            <Text style={styles.actionIcon}>⌕</Text>
          </Pressable>
          <Pressable accessibilityLabel="发布帖子" onPress={() => navigation.navigate('CreatePost')} style={styles.iconButton}>
            <Text style={styles.addIcon}>＋</Text>
          </Pressable>
          <Pressable accessibilityLabel="进入个人页" onPress={openProfile} style={styles.avatarButton}>
            <Text style={styles.avatarLetter}>
              {(profile.nickname || profile.username || '我').slice(0, 1).toUpperCase()}
            </Text>
          </Pressable>
        </View>
      </View>

      <View style={styles.contentArea}>
        {loading ? (
          <ScreenState kind="loading" title="正在加载帖子…" />
        ) : errorMessage ? (
          <ScreenState kind="error" message={errorMessage} title="加载失败" />
        ) : posts.length === 0 ? (
          <ScreenState
            kind="empty"
            message="还没有人发布内容，发布功能将在后续阶段开放。"
            title="暂无帖子"
          />
        ) : (
          <FlatList
            contentContainerStyle={styles.list}
            data={posts}
            keyExtractor={post => post.id}
            renderItem={({item}) => (
              <PostCard
                onPress={() => navigation.navigate('PostDetail', {postId: item.id})}
                post={item}
              />
            )}
            showsVerticalScrollIndicator={false}
          />
        )}
      </View>

      <View style={styles.discoverButton} pointerEvents="none">
        <Text style={styles.discoverIcon}>⌕</Text>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  page: {flex: 1, backgroundColor: '#FFFFFF'},
  appBar: {height: 66, flexDirection: 'row', alignItems: 'center', paddingHorizontal: 14, borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: '#E2E8F0', backgroundColor: '#FFFFFF'},
  brandGroup: {flex: 1, flexDirection: 'row', alignItems: 'center'},
  brandIcon: {width: 38, height: 38, alignItems: 'center', justifyContent: 'center', marginRight: 10, borderRadius: 12, backgroundColor: '#E3F2FD'},
  brandGlyph: {color: '#1976D2', fontSize: 18, fontWeight: '800'},
  brand: {color: '#1E293B', fontSize: 19, fontWeight: '800'},
  channel: {marginTop: 1, color: '#64748B', fontSize: 11, fontWeight: '500'},
  actions: {flexDirection: 'row', alignItems: 'center', gap: 3},
  iconButton: {width: 36, height: 40, alignItems: 'center', justifyContent: 'center'},
  actionIcon: {color: '#64748B', fontSize: 24},
  addIcon: {color: '#2196F3', fontSize: 27, fontWeight: '400'},
  avatarButton: {width: 34, height: 34, alignItems: 'center', justifyContent: 'center', marginLeft: 3, borderRadius: 17, backgroundColor: '#E3F2FD'},
  avatarLetter: {color: '#1976D2', fontSize: 14, fontWeight: '800'},
  contentArea: {flex: 1, backgroundColor: '#F8FAFC'},
  list: {paddingBottom: 22},
  discoverButton: {position: 'absolute', right: 18, bottom: 18, width: 54, height: 54, alignItems: 'center', justifyContent: 'center', borderRadius: 17, backgroundColor: '#2196F3', shadowColor: '#0F172A', shadowOffset: {width: 0, height: 3}, shadowOpacity: 0.2, shadowRadius: 5, elevation: 5},
  discoverIcon: {color: '#FFFFFF', fontSize: 28, fontWeight: '700'},
});
