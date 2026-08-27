import type {User} from '@react-native-firebase/auth';
import {createContext, useContext} from 'react';

import type {UserProfile} from '../../models/User';

export type AuthContextValue = {
  firebaseUser: User;
  profile: UserProfile;
  logout(): Promise<void>;
};

export const AuthContext = createContext<AuthContextValue | null>(null);

export function useAuth(): AuthContextValue {
  const value = useContext(AuthContext);

  if (value === null) {
    throw new Error('useAuth 必須在 AuthContext.Provider 內使用');
  }

  return value;
}
