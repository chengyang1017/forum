import 'dotenv/config';

import {
  applicationDefault,
  getApps,
  initializeApp,
} from 'firebase-admin/app';

import {
  getFirestore,
} from 'firebase-admin/firestore';

import { prisma } from '../lib/prisma.js';

if (getApps().length === 0) {
  initializeApp({
    credential: applicationDefault(),
  });
}

const firestore = getFirestore();

const missingPostIds = [
  'NHh0Nvf1uhOHEJyJsZ3Q',
  'OiLBtPs7t2NxlVIYWZTW',
];

function stringOrNull(
  value: unknown,
): string | null {
  if (typeof value !== 'string') {
    return null;
  }

  const valueTrimmed = value.trim();

  return valueTrimmed.length > 0
    ? valueTrimmed
    : null;
}

async function inspectUid(
  firebaseUid: string,
) {
  const firestoreUser =
      await firestore
          .collection('users')
          .doc(firebaseUid)
          .get();

  const postgresUser =
      await prisma.user.findUnique({
        where: {
          firebaseUid,
        },
        select: {
          id: true,
          username: true,
        },
      });

  console.log(
    `    Firestore user exists: ${firestoreUser.exists}`,
  );

  console.log(
    `    PostgreSQL user exists: ${postgresUser != null}`,
  );

  if (postgresUser != null) {
    console.log(
      `    PostgreSQL username: ${postgresUser.username}`,
    );
  }
}

async function inspect() {
  for (const postId of missingPostIds) {
    console.log('');
    console.log('='.repeat(70));
    console.log(`POST: ${postId}`);

    const postRef =
        firestore
            .collection('posts')
            .doc(postId);

    const postDoc =
        await postRef.get();

    if (!postDoc.exists) {
      console.log(
        'Firestore post does not exist',
      );

      continue;
    }

    const data =
        postDoc.data()!;

    console.log(
      `title: ${stringOrNull(data.title) ?? '(none)'}`,
    );

    console.log(
      `root uid: ${stringOrNull(data.uid) ?? '(none)'}`,
    );

    console.log(
      `root userId: ${stringOrNull(data.userId) ?? '(none)'}`,
    );

    console.log(
      `root authorId: ${stringOrNull(data.authorId) ?? '(none)'}`,
    );

    console.log('');
    console.log('VERSIONS');

    const versions =
        await postRef
            .collection('versions')
            .get();

    if (versions.empty) {
      console.log(
        '  No versions found',
      );

      continue;
    }

    for (const version of versions.docs) {
      const versionData =
          version.data();

      const authorId =
          stringOrNull(
            versionData.authorId,
          );

      console.log('');
      console.log(
        `  version: ${version.id}`,
      );

      console.log(
        `  languageCode: ${
          stringOrNull(
            versionData.languageCode,
          ) ??
          '(none)'
        }`,
      );

      console.log(
        `  type: ${
          stringOrNull(
            versionData.type,
          ) ??
          '(none)'
        }`,
      );

      console.log(
        `  authorId: ${authorId ?? '(none)'}`,
      );

      if (authorId != null) {
        await inspectUid(
          authorId,
        );
      }
    }
  }
}

inspect()
    .catch((error) => {
      console.error(
        'Inspection failed:',
        error,
      );

      process.exitCode = 1;
    })
    .finally(async () => {
      await prisma.$disconnect();
    });