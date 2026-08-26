import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  type User,
} from 'firebase/auth';
import {
  useCallback,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';

import {
  getAdminMe,
  type AdminIdentity,
} from '../api/adminApi';
import {
  AdminAuthContext,
  type AdminAuthContextValue,
} from './adminAuthContext';
import { auth } from './firebase';

export function AdminAuthProvider({
  children,
}: {
  children: ReactNode;
}) {
  const [user, setUser] =
    useState<User | null>(null);

  const [admin, setAdmin] =
    useState<AdminIdentity | null>(null);

  const [loading, setLoading] =
    useState(true);

  const loadAdmin = useCallback(
    async () => {
      if (auth.currentUser == null) {
        setAdmin(null);
        return;
      }

      const currentAdmin =
        await getAdminMe();

      setAdmin(currentAdmin);
    },
    [],
  );

  useEffect(() => {
    const unsubscribe =
      onAuthStateChanged(
        auth,
        async (nextUser) => {
          setUser(nextUser);
          setLoading(true);

          if (nextUser == null) {
            setAdmin(null);
            setLoading(false);
            return;
          }

          try {
            await loadAdmin();
          } catch {
            setAdmin(null);
          } finally {
            setLoading(false);
          }
        },
      );

    return unsubscribe;
  }, [loadAdmin]);

  const login = useCallback(
    async (
      email: string,
      password: string,
    ) => {
      setLoading(true);

      try {
        await signInWithEmailAndPassword(
          auth,
          email,
          password,
        );

        try {
          await loadAdmin();
        } catch {
          await signOut(auth);

          throw new Error(
            'Administrator permission required',
          );
        }
      } finally {
        setLoading(false);
      }
    },
    [loadAdmin],
  );

  const logout =
    useCallback(async () => {
      await signOut(auth);
      setAdmin(null);
    }, []);

  const refreshAdmin =
    useCallback(async () => {
      setLoading(true);

      try {
        await loadAdmin();
      } finally {
        setLoading(false);
      }
    }, [loadAdmin]);

  const value =
    useMemo<AdminAuthContextValue>(
      () => ({
        user,
        admin,
        loading,
        login,
        logout,
        refreshAdmin,
      }),
      [
        user,
        admin,
        loading,
        login,
        logout,
        refreshAdmin,
      ],
    );

  return (
    <AdminAuthContext.Provider
      value={value}
    >
      {children}
    </AdminAuthContext.Provider>
  );
}
