import {useState} from 'react';
import {ActivityIndicator, Pressable, StyleSheet, Text, View} from 'react-native';

import {useAuth} from '../auth/AuthContext';

export function ProfilePlaceholderScreen() {
  const {firebaseUser, profile, logout} = useAuth();
  const [loggingOut, setLoggingOut] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const displayName = profile.nickname || profile.displayName || profile.username || '万文社用户';

  const handleLogout = async () => {
    if (loggingOut) return;
    setLoggingOut(true);
    setErrorMessage(null);
    try {
      await logout();
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : '登出失败');
      setLoggingOut(false);
    }
  };

  return (
    <View style={styles.page}>
      <Text style={styles.pageTitle}>我的</Text>
      <View style={styles.card}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{displayName.slice(0, 1).toUpperCase()}</Text>
        </View>
        <Text style={styles.name}>{displayName}</Text>
        <Text style={styles.username}>@{profile.username || 'user'}</Text>
        <Text style={styles.email}>{profile.email || firebaseUser.email || ''}</Text>
        <View style={styles.placeholder}>
          <Text style={styles.placeholderText}>完整个人主页将在后续阶段实现</Text>
        </View>
        {errorMessage ? <Text style={styles.error}>{errorMessage}</Text> : null}
        <Pressable
          disabled={loggingOut}
          onPress={() => void handleLogout()}
          style={({pressed}) => [styles.logoutButton, pressed && styles.pressed, loggingOut && styles.disabled]}>
          {loggingOut ? <ActivityIndicator color="#DC2626" /> : <Text style={styles.logoutText}>登出</Text>}
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  page: {flex: 1, padding: 18, backgroundColor: '#F8FAFC'},
  pageTitle: {marginTop: 16, marginBottom: 18, color: '#1E293B', fontSize: 26, fontWeight: '800'},
  card: {alignItems: 'center', padding: 24, borderWidth: 1, borderColor: '#E2E8F0', borderRadius: 18, backgroundColor: '#FFFFFF'},
  avatar: {width: 82, height: 82, alignItems: 'center', justifyContent: 'center', borderRadius: 41, backgroundColor: '#E3F2FD'},
  avatarText: {color: '#1976D2', fontSize: 32, fontWeight: '800'},
  name: {marginTop: 14, color: '#1E293B', fontSize: 21, fontWeight: '800'},
  username: {marginTop: 3, color: '#2196F3', fontSize: 14, fontWeight: '600'},
  email: {marginTop: 5, color: '#64748B', fontSize: 13},
  placeholder: {width: '100%', marginTop: 22, padding: 14, borderRadius: 10, backgroundColor: '#F1F5F9'},
  placeholderText: {color: '#64748B', textAlign: 'center'},
  error: {marginTop: 14, color: '#DC2626', textAlign: 'center'},
  logoutButton: {width: '100%', height: 48, alignItems: 'center', justifyContent: 'center', marginTop: 22, borderWidth: 1, borderColor: '#FCA5A5', borderRadius: 11, backgroundColor: '#FFF7F7'},
  logoutText: {color: '#DC2626', fontSize: 16, fontWeight: '700'},
  pressed: {opacity: 0.8},
  disabled: {opacity: 0.6},
});
