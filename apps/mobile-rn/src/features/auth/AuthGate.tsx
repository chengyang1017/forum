import {getAuth, onAuthStateChanged} from '@react-native-firebase/auth';
import type {User} from '@react-native-firebase/auth';
import {useEffect, useState} from 'react';
import {ActivityIndicator, StyleSheet, Text, View} from 'react-native';

import type {UserProfile} from '../../models/User';
import {loginWithEmail, logout, registerWithEmail} from '../../services/authService';
import {getUserProfile} from '../../services/userService';
import {AppNavigator} from '../../navigation/AppNavigator';
import {AuthContext} from './AuthContext';
import {LoginScreen} from './LoginScreen';
import {RegisterScreen} from './RegisterScreen';

function messageFromError(error: unknown): string {
  return error instanceof Error ? error.message : '操作失敗，請稍後再試';
}

async function loadProfileAfterAuth(uid: string): Promise<UserProfile | null> {
  for (let attempt = 0; attempt < 5; attempt += 1) {
    const profile = await getUserProfile(uid);
    if (profile !== null) return profile;
    if (attempt < 4) {
      await new Promise<void>(resolve => setTimeout(resolve, 200));
    }
  }
  return null;
}

export function AuthGate() {
  const [firebaseUser, setFirebaseUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [checkingAuth, setCheckingAuth] = useState(true);
  const [busy, setBusy] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [mode, setMode] = useState<'login' | 'register'>('login');

  useEffect(() => {
    let active = true;
    const unsubscribe = onAuthStateChanged(getAuth(), async user => {
      setCheckingAuth(true);

      if (user === null) {
        if (active) {
          setFirebaseUser(null);
          setProfile(null);
          setCheckingAuth(false);
        }
        return;
      }

      try {
        const loadedProfile = await loadProfileAfterAuth(user.uid);
        if (!active) return;

        if (loadedProfile === null) {
          await logout();
          setErrorMessage('用戶資料不存在，請重新註冊');
          return;
        }
        if (loadedProfile.banned) {
          await logout();
          setErrorMessage('帳號已被封禁');
          return;
        }

        setFirebaseUser(user);
        setProfile(loadedProfile);
        setErrorMessage(null);
      } catch (error) {
        if (active) {
          setFirebaseUser(null);
          setProfile(null);
          setErrorMessage(messageFromError(error));
        }
      } finally {
        if (active) setCheckingAuth(false);
      }
    });

    return () => {
      active = false;
      unsubscribe();
    };
  }, []);

  const runAuthAction = async (action: () => Promise<void>) => {
    setBusy(true);
    setErrorMessage(null);
    try {
      await action();
    } catch (error) {
      setErrorMessage(messageFromError(error));
    } finally {
      setBusy(false);
    }
  };

  if (checkingAuth) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" />
        <Text style={styles.loadingText}>正在確認登入狀態…</Text>
      </View>
    );
  }

  if (firebaseUser && profile) {
    return (
      <AuthContext.Provider value={{firebaseUser, profile, logout}}>
        <AppNavigator />
      </AuthContext.Provider>
    );
  }

  if (mode === 'register') {
    return (
      <RegisterScreen
        busy={busy}
        errorMessage={errorMessage}
        onRegister={(email, password, username) =>
          runAuthAction(() => registerWithEmail(email, password, username))
        }
        onShowLogin={() => {
          setErrorMessage(null);
          setMode('login');
        }}
      />
    );
  }

  return (
    <LoginScreen
      busy={busy}
      errorMessage={errorMessage}
      onLogin={(email, password) =>
        runAuthAction(() => loginWithEmail(email, password))
      }
      onShowRegister={() => {
        setErrorMessage(null);
        setMode('register');
      }}
    />
  );
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#F4F1F8',
  },
  loadingText: {marginTop: 14, color: '#5E5864'},
});
