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

// ============================================================
// Firebase Admin
// ============================================================

if (getApps().length === 0) {
  initializeApp({
    credential: applicationDefault(),
  });
}

const firestore = getFirestore();

// ============================================================
// Migration
// ============================================================

async function migratePostLikes() {
  console.log(
    'Starting post likes migration...',
  );

  const snapshot =
    await firestore
      .collection('posts')
      .get();

  let postsChecked = 0;
  let postsFound = 0;

  let likesFound = 0;
  let likesCreated = 0;

  let missingPosts = 0;
  let missingUsers = 0;

  let failed = 0;

  for (const firestorePost of snapshot.docs) {
    postsChecked++;

    const firestoreId =
      firestorePost.id;

    const data =
      firestorePost.data();

    try {
      // --------------------------------------------------------
      // 找 PostgreSQL Post
      // --------------------------------------------------------

      const post =
        await prisma.post.findUnique({
          where: {
            firestoreId,
          },

          select: {
            id: true,
          },
        });

      if (post == null) {
        missingPosts++;

        console.warn(
          `[POST MISSING] ${firestoreId}`,
        );

        continue;
      }

      postsFound++;

      // --------------------------------------------------------
      // Firestore likes[]
      // --------------------------------------------------------

      const rawLikes =
        Array.isArray(data.likes)
          ? data.likes
          : [];

      // Set 去重，避免历史脏数据中同一 uid 重复。
      const firebaseUids =
        [
          ...new Set(
            rawLikes
              .map(
                (value) =>
                  String(value).trim(),
              )
              .filter(
                (value) =>
                  value.length > 0,
              ),
          ),
        ];

      likesFound +=
        firebaseUids.length;

      // --------------------------------------------------------
      // 把 Firebase UID 转换成 PostgreSQL User UUID
      // --------------------------------------------------------

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
          users.map(
            (user) => [
              user.firebaseUid,
              user.id,
            ],
          ),
        );

      const validUserIds: string[] = [];

      for (const firebaseUid of firebaseUids) {
        const userId =
          userByFirebaseUid.get(
            firebaseUid,
          );

        if (userId == null) {
          missingUsers++;

          console.warn(
            `[USER MISSING] post=${firestoreId} uid=${firebaseUid}`,
          );

          continue;
        }

        validUserIds.push(
          userId,
        );
      }

      // --------------------------------------------------------
      // 这一步仍属于历史 backfill 阶段。
      //
      // 对该帖子执行 replace：
      // Firestore 当前点赞状态
      // ↓
      // PostgreSQL 当前点赞状态
      //
      // 所以重复跑脚本也不会制造重复记录。
      // --------------------------------------------------------

      await prisma.$transaction(
        async (transaction) => {
          await transaction
            .postLike
            .deleteMany({
              where: {
                postId:
                  post.id,
              },
            });

          if (
            validUserIds.length > 0
          ) {
            const created =
              await transaction
                .postLike
                .createMany({
                  data:
                    validUserIds.map(
                      (userId) => ({
                        postId:
                          post.id,

                        userId,
                      }),
                    ),

                  skipDuplicates: true,
                });

            likesCreated +=
              created.count;
          }

          // ----------------------------------------------------
          // 不相信旧 Firestore likeCount。
          //
          // 根据真正写入 post_likes 的数量重新计算。
          // ----------------------------------------------------

          const likeCount =
            await transaction
              .postLike
              .count({
                where: {
                  postId:
                    post.id,
                },
              });

          await transaction
            .post
            .update({
              where: {
                id:
                  post.id,
              },

              data: {
                likeCount,
              },
            });
        },
      );
    } catch (error) {
      failed++;

      console.error(
        `[FAILED] ${firestoreId}`,
        error,
      );
    }
  }

  // ============================================================
  // 最终数据库统计
  // ============================================================

  const postgresLikes =
    await prisma.postLike.count();

  const postgresPosts =
    await prisma.post.count();

  console.log('');
  console.log(
    'Post likes migration finished.',
  );

  console.log(
    `Firestore posts checked: ${postsChecked}`,
  );

  console.log(
    `PostgreSQL posts found: ${postsFound}`,
  );

  console.log(
    `Firestore likes found: ${likesFound}`,
  );

  console.log(
    `Likes created: ${likesCreated}`,
  );

  console.log(
    `Missing posts: ${missingPosts}`,
  );

  console.log(
    `Missing users: ${missingUsers}`,
  );

  console.log(
    `Failed: ${failed}`,
  );

  console.log('');
  console.log(
    `PostgreSQL posts: ${postgresPosts}`,
  );

  console.log(
    `PostgreSQL post likes: ${postgresLikes}`,
  );
}

// ============================================================
// Run
// ============================================================

migratePostLikes()
  .catch((error) => {
    console.error(
      'Post likes migration failed:',
      error,
    );

    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });