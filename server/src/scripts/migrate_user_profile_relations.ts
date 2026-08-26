import 'dotenv/config';

import {
  applicationDefault,
  getApps,
  initializeApp,
} from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

import { prisma } from '../lib/prisma.js';

if (getApps().length === 0) {
  initializeApp({
    credential: applicationDefault(),
  });
}

const firestore = getFirestore();

function normalizeTags(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  const result = new Set<string>();

  for (const item of value) {
    if (typeof item !== 'string') {
      continue;
    }

    const tag = item.trim();

    if (tag.length === 0 || tag.length > 50) {
      continue;
    }

    result.add(tag);
  }

  return [...result];
}

type NormalizedLanguage = {
  languageCode: string;
  scriptCode: string;
  level: number;
};

function normalizeLevel(value: unknown): number {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    return 70;
  }

  return Math.max(
    0,
    Math.min(100, Math.round(value)),
  );
}

function normalizeLanguage(
  value: unknown,
): NormalizedLanguage | null {
  if (
    value == null ||
    typeof value !== 'object' ||
    Array.isArray(value)
  ) {
    return null;
  }

  const data = value as Record<string, unknown>;

  const rawCode = data.code ?? data.name;

  if (typeof rawCode !== 'string') {
    return null;
  }

  let languageCode = rawCode.trim().toLowerCase();

  if (
    languageCode.length === 0 ||
    languageCode.length > 32
  ) {
    return null;
  }

  let scriptCode =
    typeof data.scriptCode === 'string'
      ? data.scriptCode.trim()
      : '';

  if (scriptCode.length > 32) {
    return null;
  }

  // 兼容项目旧的喃字数据：
  // { name: 'chunom', level: 70 }
  // →
  // { languageCode: 'vi', scriptCode: 'Hnom' }
  if (languageCode === 'chunom') {
    languageCode = 'vi';

    if (scriptCode.length === 0) {
      scriptCode = 'Hnom';
    }
  }

  return {
    languageCode,
    scriptCode,
    level: normalizeLevel(data.level),
  };
}

function normalizeLanguages(
  value: unknown,
): NormalizedLanguage[] {
  if (!Array.isArray(value)) {
    return [];
  }

  const result = new Map<
    string,
    NormalizedLanguage
  >();

  for (const item of value) {
    const language = normalizeLanguage(item);

    if (language == null) {
      continue;
    }

    const key =
      `${language.languageCode}:` +
      language.scriptCode.toLowerCase();

    if (!result.has(key)) {
      result.set(key, language);
    }
  }

  return [...result.values()];
}

async function migrateUserProfileRelations() {
  const snapshot =
    await firestore.collection('users').get();

  let tagsCreated = 0;
  let languagesCreated = 0;
  let usersMissing = 0;
  let failed = 0;

  for (const doc of snapshot.docs) {
    const firebaseUid = doc.id;
    const data = doc.data();

    try {
      const user = await prisma.user.findUnique({
        where: {
          firebaseUid,
        },
        select: {
          id: true,
          username: true,
        },
      });

      if (user == null) {
        usersMissing++;

        console.warn(
          `[SKIP] PostgreSQL user missing: ${firebaseUid}`,
        );

        continue;
      }

      const tags = normalizeTags(data.tags);
      const languages =
        normalizeLanguages(data.languages);

      const result = await prisma.$transaction(
        async (transaction) => {
          const tagResult =
            tags.length === 0
              ? { count: 0 }
              : await transaction.userTag.createMany({
                  data: tags.map((value) => ({
                    userId: user.id,
                    value,
                  })),
                  skipDuplicates: true,
                });

          const languageResult =
            languages.length === 0
              ? { count: 0 }
              : await transaction.userLanguage.createMany({
                  data: languages.map((language) => ({
                    userId: user.id,
                    languageCode:
                      language.languageCode,
                    scriptCode:
                      language.scriptCode,
                    level: language.level,
                  })),
                  skipDuplicates: true,
                });

          return {
            tags: tagResult.count,
            languages: languageResult.count,
          };
        },
      );

      tagsCreated += result.tags;
      languagesCreated += result.languages;

      console.log(
        `[OK] ${user.username}: ` +
        `${result.tags} tags, ` +
        `${result.languages} languages`,
      );
    } catch (error) {
      failed++;

      console.error(
        `[FAIL] ${firebaseUid}`,
        error,
      );
    }
  }

  const totalTags = await prisma.userTag.count();
  const totalLanguages =
    await prisma.userLanguage.count();

  console.log('');
  console.log('Profile relation migration finished');
  console.log(`Firestore users: ${snapshot.size}`);
  console.log(`Tags created: ${tagsCreated}`);
  console.log(
    `Languages created: ${languagesCreated}`,
  );
  console.log(
    `PostgreSQL users missing: ${usersMissing}`,
  );
  console.log(`Failed: ${failed}`);
  console.log(`Total PostgreSQL tags: ${totalTags}`);
  console.log(
    `Total PostgreSQL languages: ${totalLanguages}`,
  );
}

migrateUserProfileRelations()
  .catch((error) => {
    console.error('Migration failed:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });