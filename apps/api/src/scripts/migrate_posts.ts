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

import { Prisma } from '../generated/prisma/client.js';
import { prisma } from '../lib/prisma.js';

if (getApps().length === 0) {
  initializeApp({
    credential: applicationDefault(),
  });
}

const firestore = getFirestore();

// ============================================================
// 基础转换
// ============================================================

function stringOrNull(
  value: unknown,
): string | null {
  if (typeof value !== 'string') {
    return null;
  }

  const result = value.trim();

  return result.length === 0
    ? null
    : result;
}

function toDate(
  value: unknown,
): Date | null {
  if (value == null) {
    return null;
  }

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

function toCount(
  value: unknown,
  fallback = 0,
): number {
  if (
    typeof value !== 'number' ||
    !Number.isFinite(value)
  ) {
    return fallback;
  }

  return Math.max(
    0,
    Math.trunc(value),
  );
}

function toBodyDelta(
  value: unknown,
): Prisma.InputJsonValue {
  if (!Array.isArray(value)) {
    return [];
  }

  try {
    return JSON.parse(
      JSON.stringify(value),
    ) as Prisma.InputJsonValue;
  } catch {
    return [];
  }
}

// ============================================================
// 版本迁移结构
// ============================================================

type MigratedVersion = {
  languageCode: string;

  authorId: string | null;

  title: string;
  content: string;

  bodyDelta: Prisma.InputJsonValue;

  type: string;

  createdAt: Date;
  updatedAt: Date;
};

// ============================================================
// 用户 UID → PostgreSQL UUID 缓存
// ============================================================

const userIdCache =
  new Map<string, string | null>();

async function getDatabaseUserId(
  firebaseUid: string | null,
): Promise<string | null> {
  if (firebaseUid == null) {
    return null;
  }

  if (userIdCache.has(firebaseUid)) {
    return userIdCache.get(firebaseUid) ?? null;
  }

  const user = await prisma.user.findUnique({
    where: {
      firebaseUid,
    },

    select: {
      id: true,
    },
  });

  const id = user?.id ?? null;

  userIdCache.set(
    firebaseUid,
    id,
  );

  return id;
}

// ============================================================
// 主迁移
// ============================================================

async function migratePosts() {
  const snapshot =
    await firestore
      .collection('posts')
      .get();

  let created = 0;
  let alreadyExisted = 0;
  let missingAuthors = 0;
  let failed = 0;

  let versionsCreated = 0;
  let imagesCreated = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();

    const firestoreId = doc.id;

    // ----------------------------------------------------------
    // 已经迁过就跳过。
    // Backfill 不覆盖 PostgreSQL 新数据。
    // ----------------------------------------------------------

    const existing =
      await prisma.post.findUnique({
        where: {
          firestoreId,
        },

        select: {
          id: true,
        },
      });

    if (existing != null) {
      alreadyExisted++;
      continue;
    }

    // ----------------------------------------------------------
    // 帖子作者
    // ----------------------------------------------------------

    // const authorFirebaseUid =
    //   stringOrNull(data.uid) ??
    //   stringOrNull(data.userId);

    // const authorId =
    //   await getDatabaseUserId(
    //     authorFirebaseUid,
    //   );

    // if (authorId == null) {
    //   missingAuthors++;

    //   console.warn(
    //     `[SKIP] ${firestoreId}: post author missing`,
    //   );

    //   continue;
    // }

    const authorFirebaseUid =
  stringOrNull(data.uid) ??
  stringOrNull(data.userId);

let authorId: string | null = null;

if (authorFirebaseUid != null) {
  authorId =
    await getDatabaseUserId(
      authorFirebaseUid,
    );

  // 帖子明确记录了作者 UID，
  // 但 PostgreSQL 找不到对应用户。
  // 这是真正的数据完整性异常，仍然跳过。
  if (authorId == null) {
    missingAuthors++;

    console.warn(
      `[SKIP] ${firestoreId}: ` +
      `author user missing (${authorFirebaseUid})`,
    );

    continue;
  }
} else {
  // 早期帖子根本没有作者字段。
  // 这是合法历史数据，不再跳过。
  console.warn(
    `[LEGACY] ${firestoreId}: ` +
    'no author, migrating with authorId=null',
  );
}

    // ----------------------------------------------------------
    // 主语言
    // ----------------------------------------------------------

    const primaryLanguageCode =
      stringOrNull(
        data.primaryLanguageCode,
      ) ??
      stringOrNull(
        data.languageCode,
      ) ??
      'und';

    const createdAt =
      toDate(data.timestamp) ??
      toDate(data.createdAt) ??
      new Date();

    const updatedAt =
      toDate(data.updatedAt) ??
      toDate(data.editedAt) ??
      createdAt;

    // ----------------------------------------------------------
    // likes / comments 当前只迁统计数字。
    // 真正关系后面单独迁。
    // ----------------------------------------------------------

    const legacyLikes =
      Array.isArray(data.likes)
        ? data.likes.length
        : 0;

    const likeCount =
      toCount(
        data.likeCount,
        legacyLikes,
      );

    const commentCount =
      toCount(data.commentCount);

    // ----------------------------------------------------------
    // 收集版本
    // key = languageCode
    // ----------------------------------------------------------

    const versionMap =
      new Map<
        string,
        MigratedVersion
      >();

    // 主语言永远先从 posts 根文档建立。
    versionMap.set(
      primaryLanguageCode,
      {
        languageCode:
          primaryLanguageCode,

        authorId,

        title:
          stringOrNull(data.title) ?? '',

        content:
          stringOrNull(data.content) ?? '',

        bodyDelta:
          toBodyDelta(data.bodyDelta),

        type: 'original',

        createdAt,
        updatedAt,
      },
    );

    // ----------------------------------------------------------
    // Firestore:
    // posts/{postId}/versions/{languageCode}
    // ----------------------------------------------------------

    const versionsSnapshot =
      await doc.ref
        .collection('versions')
        .get();

    for (
      const versionDoc
      of versionsSnapshot.docs
    ) {
      const versionData =
        versionDoc.data();

      const languageCode =
        stringOrNull(
          versionData.languageCode,
        ) ??
        versionDoc.id;

      if (languageCode.length === 0) {
        continue;
      }

      const versionAuthorFirebaseUid =
        stringOrNull(
          versionData.authorId,
        );

      const versionAuthorId =
        await getDatabaseUserId(
          versionAuthorFirebaseUid,
        );

      const versionCreatedAt =
        toDate(
          versionData.createdAt,
        ) ??
        createdAt;

      const versionUpdatedAt =
        toDate(
          versionData.updatedAt,
        ) ??
        versionCreatedAt;

      // --------------------------------------------------------
      // 如果这个 versions 文档就是主语言：
      // 正文仍以 root Post 为准，
      // 但保留 versions 里的作者/type/时间。
      // --------------------------------------------------------

      if (
        languageCode ===
        primaryLanguageCode
      ) {
        const primaryVersion =
          versionMap.get(
            primaryLanguageCode,
          )!;

        versionMap.set(
          primaryLanguageCode,
          {
            ...primaryVersion,

            authorId:
              versionAuthorId ??
              primaryVersion.authorId,

            type:
              stringOrNull(
                versionData.type,
              ) ??
              primaryVersion.type,

            createdAt:
              versionCreatedAt,

            updatedAt:
              versionUpdatedAt,
          },
        );

        continue;
      }

      // --------------------------------------------------------
      // 其他语言版本直接使用 versions 子集合数据。
      // --------------------------------------------------------

      versionMap.set(
        languageCode,
        {
          languageCode,

          authorId:
            versionAuthorId,

          title:
            stringOrNull(
              versionData.title,
            ) ?? '',

          content:
            stringOrNull(
              versionData.content,
            ) ?? '',

          bodyDelta:
            toBodyDelta(
              versionData.bodyDelta,
            ),

          type:
            stringOrNull(
              versionData.type,
            ) ??
            'manual',

          createdAt:
            versionCreatedAt,

          updatedAt:
            versionUpdatedAt,
        },
      );
    }

    // ----------------------------------------------------------
    // 图片
    // ----------------------------------------------------------

    const images =
      Array.isArray(data.images)
        ? data.images
            .map((value) =>
              stringOrNull(value),
            )
            .filter(
              (value): value is string =>
                value != null,
            )
        : [];

    try {
      const result =
        await prisma.$transaction(
          async (transaction) => {
            const post =
              await transaction.post.create({
                data: {
                  firestoreId,

                  authorId,

                  category:
                    stringOrNull(
                      data.category,
                    ),

                  primaryLanguageCode,

                  likeCount,
                  commentCount,

                  createdAt,
                  updatedAt,
                },
              });

            const versions =
              [...versionMap.values()];

            if (versions.length > 0) {
              await transaction
                .postVersion
                .createMany({
                  data:
                    versions.map(
                      (version) => ({
                        postId:
                          post.id,

                        authorId:
                          version.authorId,

                        languageCode:
                          version.languageCode,

                        title:
                          version.title,

                        content:
                          version.content,

                        bodyDelta:
                          version.bodyDelta,

                        type:
                          version.type,

                        createdAt:
                          version.createdAt,

                        updatedAt:
                          version.updatedAt,
                      }),
                    ),
                });
            }

            if (images.length > 0) {
              await transaction
                .postImage
                .createMany({
                  data:
                    images.map(
                      (url, index) => ({
                        postId:
                          post.id,

                        url,

                        position:
                          index,
                      }),
                    ),
                });
            }

            return {
              versions:
                versions.length,

              images:
                images.length,
            };
          },
        );

      created++;

      versionsCreated +=
        result.versions;

      imagesCreated +=
        result.images;

      console.log(
        `[OK] ${firestoreId}: ` +
        `${result.versions} versions, ` +
        `${result.images} images`,
      );
    } catch (error) {
      failed++;

      console.error(
        `[FAIL] ${firestoreId}`,
        error,
      );
    }
  }

  const postgresPosts =
    await prisma.post.count();

  const postgresVersions =
    await prisma.postVersion.count();

  const postgresImages =
    await prisma.postImage.count();

  console.log('');
  console.log(
    'Post migration finished',
  );

  console.log(
    `Firestore posts: ${snapshot.size}`,
  );

  console.log(
    `Created: ${created}`,
  );

  console.log(
    `Already existed: ${alreadyExisted}`,
  );

  console.log(
    `Missing authors: ${missingAuthors}`,
  );

  console.log(
    `Failed: ${failed}`,
  );

  console.log(
    `Versions created: ${versionsCreated}`,
  );

  console.log(
    `Images created: ${imagesCreated}`,
  );

  console.log(
    `PostgreSQL posts: ${postgresPosts}`,
  );

  console.log(
    `PostgreSQL versions: ${postgresVersions}`,
  );

  console.log(
    `PostgreSQL images: ${postgresImages}`,
  );
}

migratePosts()
  .catch((error) => {
    console.error(
      'Post migration failed:',
      error,
    );

    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });