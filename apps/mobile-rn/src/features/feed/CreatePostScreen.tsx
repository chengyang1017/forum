import type {NativeStackScreenProps} from '@react-navigation/native-stack';
import {useState} from 'react';
import {
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import type {FeedStackParamList} from '../../navigation/types';
import {postRepository} from '../../repositories/PostRepository';
import {useAuth} from '../auth/AuthContext';

type Props = NativeStackScreenProps<FeedStackParamList, 'CreatePost'>;

const languages = [
  {code: 'zh', name: '中文'},
  {code: 'en', name: 'English'},
  {code: 'ms', name: 'Bahasa Melayu'},
  {code: 'vi', name: 'Tiếng Việt'},
] as const;

const categories = [
  {id: 'chat', name: '闲聊'},
  {id: 'language_learning', name: '语言学习'},
  {id: 'programming', name: '编程'},
  {id: 'technology', name: '科技'},
  {id: 'travel', name: '旅行'},
] as const;

export function CreatePostScreen({navigation}: Props) {
  const {firebaseUser, profile} = useAuth();
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [languageCode, setLanguageCode] = useState('zh');
  const [category, setCategory] = useState('chat');
  const [submitting, setSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const selectedLanguage = languages.find(item => item.code === languageCode) ?? languages[0];
  const selectedCategory = categories.find(item => item.id === category) ?? categories[0];

  const submit = async () => {
    if (submitting) return;
    const cleanTitle = title.trim();
    const cleanContent = content.trim();

    if (!cleanTitle || !cleanContent) {
      setErrorMessage('请填写标题和内容');
      return;
    }

    setSubmitting(true);
    setErrorMessage(null);
    try {
      await postRepository.createPost({
        uid: firebaseUser.uid,
        username: profile.username || '匿名用户',
        nickname: profile.nickname || '',
        title: cleanTitle,
        content: cleanContent,
        category,
        languageCode,
        languageName: selectedLanguage.name,
      });
      navigation.goBack();
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : '发布失败');
      setSubmitting(false);
    }
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={styles.page}>
      <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
        <View style={styles.channelCard}>
          <View style={styles.categoryBadge}>
            <Text style={styles.categoryBadgeText}>{selectedCategory.name}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.languageBadge}>
            <Text style={styles.languageBadgeText}>{selectedLanguage.name}</Text>
          </View>
          <Text style={styles.channelHint}>发布到此频道</Text>
        </View>

        <Text style={styles.sectionLabel}>分类</Text>
        <View style={styles.chips}>
          {categories.map(item => (
            <Pressable
              disabled={submitting}
              key={item.id}
              onPress={() => setCategory(item.id)}
              style={[styles.chip, category === item.id && styles.chipSelected]}>
              <Text style={[styles.chipText, category === item.id && styles.chipTextSelected]}>{item.name}</Text>
            </Pressable>
          ))}
        </View>

        <Text style={styles.sectionLabel}>语言频道</Text>
        <View style={styles.chips}>
          {languages.map(item => (
            <Pressable
              disabled={submitting}
              key={item.code}
              onPress={() => setLanguageCode(item.code)}
              style={[styles.chip, languageCode === item.code && styles.chipSelected]}>
              <Text style={[styles.chipText, languageCode === item.code && styles.chipTextSelected]}>{item.name}</Text>
            </Pressable>
          ))}
        </View>

        <Text style={styles.inputLabel}>标题</Text>
        <TextInput
          editable={!submitting}
          maxLength={100}
          onChangeText={setTitle}
          placeholder="输入帖子标题…"
          placeholderTextColor="#94A3B8"
          style={styles.titleInput}
          value={title}
        />
        <Text style={styles.counter}>{title.length}/100</Text>

        <Text style={styles.inputLabel}>内容</Text>
        <TextInput
          editable={!submitting}
          maxLength={5000}
          multiline
          onChangeText={setContent}
          placeholder={'输入帖子内容…\n\n支持换行和表情符号'}
          placeholderTextColor="#94A3B8"
          style={styles.contentInput}
          textAlignVertical="top"
          value={content}
        />
        <Text style={styles.counter}>{content.length}/5000</Text>

        <View style={styles.imagePlaceholder}>
          <Text style={styles.imageTitle}>▧ 图片（可选）</Text>
          <Text style={styles.imageHint}>图片上传不在本阶段实现</Text>
        </View>

        {errorMessage ? (
          <View style={styles.errorBox}><Text style={styles.errorText}>{errorMessage}</Text></View>
        ) : null}

        <Pressable
          disabled={submitting}
          onPress={() => void submit()}
          style={({pressed}) => [styles.submitButton, pressed && styles.pressed, submitting && styles.disabled]}>
          {submitting ? (
            <View style={styles.loadingRow}>
              <ActivityIndicator color="#FFFFFF" />
              <Text style={styles.submitText}>发布中…</Text>
            </View>
          ) : <Text style={styles.submitText}>发布帖子</Text>}
        </Pressable>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  page: {flex: 1, backgroundColor: '#FFFFFF'},
  content: {padding: 16, paddingBottom: 36},
  channelCard: {flexDirection: 'row', alignItems: 'center', padding: 12, borderWidth: 1, borderColor: '#90CAF9', borderRadius: 12, backgroundColor: '#E3F2FD'},
  categoryBadge: {paddingHorizontal: 10, paddingVertical: 6, borderRadius: 18, backgroundColor: '#2196F3'},
  categoryBadgeText: {color: '#FFFFFF', fontSize: 13, fontWeight: '700'},
  divider: {width: 1, height: 20, marginHorizontal: 8, backgroundColor: '#64B5F6'},
  languageBadge: {paddingHorizontal: 10, paddingVertical: 6, borderWidth: 1, borderColor: '#64B5F6', borderRadius: 18, backgroundColor: '#FFFFFF'},
  languageBadgeText: {color: '#1976D2', fontSize: 12, fontWeight: '700'},
  channelHint: {flex: 1, color: '#42A5F5', fontSize: 11, textAlign: 'right'},
  sectionLabel: {marginTop: 20, marginBottom: 9, color: '#334155', fontSize: 14, fontWeight: '700'},
  chips: {flexDirection: 'row', flexWrap: 'wrap', gap: 8},
  chip: {paddingHorizontal: 12, paddingVertical: 8, borderWidth: 1, borderColor: '#CBD5E1', borderRadius: 18, backgroundColor: '#FFFFFF'},
  chipSelected: {borderColor: '#2196F3', backgroundColor: '#E3F2FD'},
  chipText: {color: '#64748B', fontSize: 13, fontWeight: '600'},
  chipTextSelected: {color: '#1976D2'},
  inputLabel: {marginTop: 22, marginBottom: 7, color: '#334155', fontSize: 14, fontWeight: '700'},
  titleInput: {height: 54, paddingHorizontal: 14, borderWidth: 1, borderColor: '#CBD5E1', borderRadius: 12, color: '#0F172A', fontSize: 16},
  contentInput: {minHeight: 180, padding: 14, borderWidth: 1, borderColor: '#CBD5E1', borderRadius: 12, color: '#0F172A', fontSize: 16, lineHeight: 24},
  counter: {marginTop: 5, color: '#94A3B8', fontSize: 11, textAlign: 'right'},
  imagePlaceholder: {marginTop: 20, padding: 14, borderWidth: 1, borderColor: '#E2E8F0', borderRadius: 12, backgroundColor: '#F8FAFC'},
  imageTitle: {color: '#334155', fontSize: 14, fontWeight: '700'},
  imageHint: {marginTop: 5, color: '#94A3B8', fontSize: 12},
  errorBox: {marginTop: 16, padding: 12, borderRadius: 9, backgroundColor: '#FEF2F2'},
  errorText: {color: '#DC2626', lineHeight: 20},
  submitButton: {height: 52, alignItems: 'center', justifyContent: 'center', marginTop: 22, borderRadius: 12, backgroundColor: '#2196F3'},
  submitText: {color: '#FFFFFF', fontSize: 16, fontWeight: '700'},
  loadingRow: {flexDirection: 'row', alignItems: 'center', gap: 10},
  pressed: {opacity: 0.82},
  disabled: {opacity: 0.65},
});
