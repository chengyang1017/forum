import 'dotenv/config';

import {
  applicationDefault,
  getApps,
  initializeApp,
} from 'firebase-admin/app';
import {
  getFirestore,
  Timestamp,
} from 'firebase-admin/firestore';

import { prisma } from '../lib/prisma.js';

if (getApps().length === 0) {
  initializeApp({
    credential: applicationDefault(),
  });
}

const firestore = getFirestore();

function stringOrNull(value: unknown): string | null {
  if (typeof value !== 'string') return null;

  const result = value.trim();
  return result.length === 0 ? null : result;
}

function toDate(value: unknown): Date | null {
  if (value == null) return null;

  if (value instanceof Timestamp) {
    return value.toDate();
  }

  if (value instanceof Date) {
    return value;
  }

  if (typeof value === 'string') {
    const date = new Date(value);

    if (!Number.isNaN(date.getTime())) {
      return date;
    }
  }

  return null;
}

async function resolveMigrationUsername(
  firebaseUid: string,
  username: string,
): Promise<string> {
  const usernameOwner =
    await prisma.user.findUnique({
      where: {
        username,
      },
      select: {
        firebaseUid: true,
      },
    });

  // 没人占用，可以直接使用旧 username。
  if (usernameOwner == null) {
    return username;
  }

  // 理论上的幂等保护。
  if (
    usernameOwner.firebaseUid ===
    firebaseUid
  ) {
    return username;
  }

  // Firestore 历史数据存在重复 username。
  // 使用 Firebase UID 的一部分生成稳定的 fallback。
  const suffix =
    firebaseUid.slice(0, 8);

  let candidate =
    `${username}_${suffix}`;

  let attempt = 1;

  while (true) {
    const candidateOwner =
      await prisma.user.findUnique({
        where: {
          username: candidate,
        },
        select: {
          id: true,
        },
      });

    if (candidateOwner == null) {
      console.warn(
        `[USERNAME COLLISION] ${username} -> ${candidate} (${firebaseUid})`,
      );

      return candidate;
    }

    candidate =
      `${username}_${suffix}_${attempt}`;

    attempt++;
  }
}

async function migrateUsers() {
  const snapshot =
    await firestore.collection('users').get();

  let created = 0;
  let existing = 0;
  let skipped = 0;
  let failed = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();

    // Firestore document id 才是旧系统真正使用的 Firebase UID
    const firebaseUid = doc.id;

    const username = stringOrNull(data.username);

    if (username == null) {
      skipped++;
      console.warn(
        `[SKIP] ${firebaseUid}: missing username`,
      );
      continue;
    }

    try {
      const alreadyExists =
        await prisma.user.findUnique({
          where: {
            firebaseUid,
          },
          select: {
            id: true,
          },
        });

      

      // 已经通过新系统同步过的用户不要拿旧数据覆盖
      if (alreadyExists != null) {
        existing++;
        continue;
      }

      const migratedUsername =
  await resolveMigrationUsername(
    firebaseUid,
    username,
  );

      const nickname =
        stringOrNull(data.nickname) ??
        stringOrNull(data.displayName);

      const avatarUrl =
        stringOrNull(data.avatar) ??
        stringOrNull(data.avatarUrl) ??
        stringOrNull(data.photoUrl);

      await prisma.user.create({
        data: {
          firebaseUid,
          username: migratedUsername,
          email: stringOrNull(data.email),
          nickname,
          avatarUrl,
          bio: stringOrNull(data.bio),
          birthday: toDate(data.birthday),
          showAge:
              typeof data.showAge === 'boolean'
                  ? data.showAge
                  : true,
          lastActiveAt: toDate(data.lastActive),

          ...(toDate(data.createdAt) != null
              ? {
                  createdAt: toDate(data.createdAt)!,
                }
              : {}),
        },
      });

      created++;

      if (migratedUsername == username) {
        console.log(
          `[OK] ${username}`,
        );
      } else {
        console.log(
          `[OK] ${username} -> ${migratedUsername}`,
        );
      }
    } catch (error) {
      failed++;
      console.error(
        `[FAIL] ${firebaseUid} (${username})`,
        error,
      );
    }
  }

  const postgresCount =
      await prisma.user.count();

  console.log('');
  console.log('Migration finished');
  console.log(`Firestore users: ${snapshot.size}`);
  console.log(`Created: ${created}`);
  console.log(`Already existed: ${existing}`);
  console.log(`Skipped: ${skipped}`);
  console.log(`Failed: ${failed}`);
  console.log(`PostgreSQL users: ${postgresCount}`);
}

migrateUsers()
  .catch((error) => {
    console.error('Migration failed:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });