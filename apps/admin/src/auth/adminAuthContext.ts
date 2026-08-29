import {
  createContext,
  useContext,
} from 'react';
import type { User } from 'firebase/auth';

import type { AdminIdentity } from '../api/adminApi';

export interface AdminAuthContextValue {
  user: User | null;
  admin: AdminIdentity | null;
  loading: boolean;
  login: (
    email: string,
    password: string,
  ) => Promise<void>;
  logout: () => Promise<void>;
  refreshAdmin: () => Promise<void>;
}

export const AdminAuthContext =
  createContext<AdminAuthContextValue | null>(
    null,
  );

export function useAdminAuth() {
  const context =
    useContext(AdminAuthContext);

  if (context == null) {
    throw new Error(
      'useAdminAuth must be used inside AdminAuthProvider',
    );
  }

  return context;
}
