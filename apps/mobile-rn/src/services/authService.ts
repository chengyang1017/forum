import {
  createUserWithEmailAndPassword,
  getAuth,
  signInWithEmailAndPassword,
  signOut,
} from '@react-native-firebase/auth';
import {
  collection,
  doc,
  getDocs,
  getFirestore,
  limit,
  query,
  serverTimestamp,
  setDoc,
  where,
} from '@react-native-firebase/firestore';

import {getUserProfile} from './userService';

export async function loginWithEmail(
  email: string,
  password: string,
): Promise<void> {
  if (!email || !password) {
    throw new Error('請輸入電子郵件和密碼');
  }

  const credential = await signInWithEmailAndPassword(
    getAuth(),
    email,
    password,
  );
  const profile = await getUserProfile(credential.user.uid);

  if (profile === null) {
    await signOut(getAuth());
    throw new Error('用戶資料不存在，請重新註冊');
  }

  if (profile.banned) {
    await signOut(getAuth());
    throw new Error('帳號已被封禁');
  }

  await setDoc(
    doc(getFirestore(), 'users', credential.user.uid),
    {lastLogin: serverTimestamp()},
    {merge: true},
  );
}

export async function registerWithEmail(
  email: string,
  password: string,
  username: string,
): Promise<void> {
  if (!username) {
    throw new Error('請輸入使用者名稱');
  }
  if (username.length < 2 || username.length > 20) {
    throw new Error('使用者名稱必須是 2 至 20 個字元');
  }
  if (!/^[a-zA-Z0-9_\u4e00-\u9fa5]+$/.test(username)) {
    throw new Error('使用者名稱只能包含中英文、數字和底線');
  }
  if (!email || !password) {
    throw new Error('請輸入電子郵件和密碼');
  }
  if (password.length < 6) {
    throw new Error('密碼至少需要 6 位');
  }

  const usernameSnapshot = await getDocs(
    query(
      collection(getFirestore(), 'users'),
      where('username', '==', username),
      limit(1),
    ),
  );

  if (!usernameSnapshot.empty) {
    throw new Error('該使用者名稱已被使用，請換一個');
  }

  const credential = await createUserWithEmailAndPassword(
    getAuth(),
    email,
    password,
  );
  const uid = credential.user.uid;

  try {
    await setDoc(doc(getFirestore(), 'users', uid), {
      uid,
      username,
      email,
      displayName: username,
      photoUrl: null,
      bio: null,
      friends: [],
      friendRequests: [],
      createdAt: serverTimestamp(),
      lastActive: serverTimestamp(),
      banned: false,
      role: 'user',
    });
  } catch (error) {
    await signOut(getAuth());
    throw error;
  }
}

export function logout(): Promise<void> {
  return signOut(getAuth());
}
