import 'dotenv/config';

import {
  applicationDefault,
  getApps,
  initializeApp,
} from 'firebase-admin/app';

import {
  getFirestore,
} from 'firebase-admin/firestore';

import {
  Prisma,
} from '../generated/prisma/client.js';

import { prisma } from '../lib/prisma.js';

if (getApps().length === 0) {
  initializeApp({
    credential: applicationDefault(),
  });
}

const firestore = getFirestore();

function stringValue(
  value: unknown,
  fallback = '',
) {
  return typeof value === 'string'
    ? value
    : fallback;
}

function stringArray(
  value: unknown,
): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((item) => String(item).trim())
    .filter((item) => item.length > 0);
}

function jsonArray(
  value: unknown,
): Prisma.InputJsonValue {
  return Array.isArray(value)
    ? value as Prisma.InputJsonValue
    : [];
}

function dateValue(
  value: unknown,
  fallback: Date,
) {
  if (value instanceof Date) {
    return value;
  }

  if (
    typeof value === 'object' &&
    value != null &&
    'toDate' in value &&
    typeof (value as { toDate?: unknown }).toDate === 'function'
  ) {
    return (
      value as { toDate: () => Date }
    ).toDate();
  }

  if (typeof value === 'string') {
    const parsed = new Date(value);

    if (!Number.isNaN(parsed.getTime())) {
      return parsed;
    }
  }

  return fallback;
}

async function migratePostEditHistory() {
  console.log(
    'Starting post edit history migration...',
  );

  const posts =
    await prisma.post.findMany({
      where: {
        firestoreId: {
          not: null,
        },
      },
      select: {
        id: true,
        firestoreId: true,
        primaryLanguageCode: true,
        createdAt: true,
      },
    });

  let postsChecked = 0;
  let historyFound = 0;
  let historyUpserted = 0;
  let missingUsers = 0;
  let failed = 0;

  for (const post of posts) {
    const firestoreId = post.firestoreId;

    if (firestoreId == null) {
      continue;
    }

    postsChecked++;

    try {
      const snapshot =
        await firestore
          .collection('posts')
          .doc(firestoreId)
          .collection('editHistory')
          .get();

      historyFound += snapshot.size;

      const firebaseUids = [
        ...new Set(
          snapshot.docs
            .map((doc) =>
              stringValue(doc.data().editedBy).trim(),
            )
            .filter((uid) => uid.length > 0),
        ),
      ];

      const users =
        firebaseUids.length === 0
          ? []
          : await prisma.user.findMany({
              where: {
                firebaseUid: {
                  in: firebaseUids,
                },
              },
              select: {
                id: true,
                firebaseUid: true,
              },
            });

      const userByFirebaseUid =
        new Map(
          users.map((user) => [
            user.firebaseUid,
            user.id,
          ]),
        );

      for (const document of snapshot.docs) {
        const data = document.data();
        const firebaseUid =
          stringValue(data.editedBy).trim();

        const editedById =
          firebaseUid.length === 0
            ? null
            : userByFirebaseUid.get(firebaseUid) ?? null;

        if (
          firebaseUid.length > 0 &&
          editedById == null
        ) {
          missingUsers++;
        }

        const firestorePath =
          document.ref.path;

        const type =
          data.type === 'original'
            ? 'original'
            : 'edit';

        const languageCode =
          stringValue(
            data.languageCode,
            post.primaryLanguageCode,
          ).trim() || post.primaryLanguageCode;

        const editedAt =
          dateValue(
            data.editedAt,
            post.createdAt,
          );

        const bodyDelta =
          jsonArray(data.bodyDelta);

        const imageUrls =
          stringArray(data.imageUrls);

        await prisma.postEditHistory.upsert({
          where: {
            firestorePath,
          },
          update: {
            postId: post.id,
            editedById,
            languageCode,
            type,
            title:
              stringValue(data.title),
            content:
              stringValue(data.content),
            bodyDelta,
            imageUrls:
              imageUrls as Prisma.InputJsonValue,
            editedAt,
          },
          create: {
            firestorePath,
            postId: post.id,
            editedById,
            languageCode,
            type,
            title:
              stringValue(data.title),
            content:
              stringValue(data.content),
            bodyDelta,
            imageUrls:
              imageUrls as Prisma.InputJsonValue,
            editedAt,
          },
        });

        historyUpserted++;
      }
    } catch (error) {
      failed++;

      console.error(
        `[FAILED] post=${firestoreId}`,
        error,
      );
    }
  }

  const postgresHistory =
    await prisma.postEditHistory.count();

  console.log('');
  console.log(
    'Post edit history migration finished.',
  );
  console.log(
    `PostgreSQL posts checked: ${postsChecked}`,
  );
  console.log(
    `Firestore history found: ${historyFound}`,
  );
  console.log(
    `History upserted: ${historyUpserted}`,
  );
  console.log(
    `Missing users: ${missingUsers}`,
  );
  console.log(
    `Failed: ${failed}`,
  );
  console.log('');
  console.log(
    `PostgreSQL edit history: ${postgresHistory}`,
  );
}

migratePostEditHistory()
  .catch((error) => {
    console.error(
      'Post edit history migration failed:',
      error,
    );

    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
