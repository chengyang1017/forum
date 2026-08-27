import {
  doc,
  getDoc,
  getFirestore,
} from '@react-native-firebase/firestore';

import {decodeUserProfile, UserProfile} from '../models/User';

export async function getUserProfile(
  uid: string,
): Promise<UserProfile | null> {
  const snapshot = await getDoc(doc(getFirestore(), 'users', uid));

  if (!snapshot.exists()) {
    return null;
  }

  return decodeUserProfile(
    snapshot.id,
    snapshot.data() as Record<string, unknown>,
  );
}
