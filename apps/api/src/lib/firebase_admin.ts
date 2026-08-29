import {
  applicationDefault,
  getApps,
  initializeApp,
} from 'firebase-admin/app';

import {
  getAuth,
} from 'firebase-admin/auth';

import {
  getFirestore,
} from 'firebase-admin/firestore';

import {
  getStorage,
} from 'firebase-admin/storage';

const firebaseApp =
  getApps().length > 0
    ? getApps()[0]
    : initializeApp({
        credential: applicationDefault(),
      });

export const firebaseAuth =
  getAuth(firebaseApp);

export const firebaseFirestore =
  getFirestore(firebaseApp);

export function getFirebaseStorageBucket() {
  const bucketName =
    process.env
      .FIREBASE_STORAGE_BUCKET
      ?.trim();

  if (!bucketName) {
    throw new Error(
      'FIREBASE_STORAGE_BUCKET is not configured',
    );
  }

  return getStorage(firebaseApp)
    .bucket(bucketName);
}