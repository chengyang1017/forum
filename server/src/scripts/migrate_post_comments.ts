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

type LegacyComment = {
  firestoreId: string;
  uid: string;
  user: string;
  text: string;
  imageUrl: string | null;
  replyTo: string | null;
  createdAt: Date;
  replies: LegacyComment[];
};

function stringValue(
  value: unknown,
) {
  return typeof value === 'string'
    ? value.trim()
    : '';
}

function nullableString(
  value: unknown,
  maxLength?: number,
) {
  const result =
    stringValue(value);

  if (result.length === 0) {
    return null;
  }

  return maxLength == null
    ? result
    : result.slice(
        0,
        maxLength,
      );
}

function displayNameValue(
  value: unknown,
) {
  const result =
    stringValue(value);

  return (
    result.length > 0
      ? result
      : 'Guest'
  ).slice(
    0,
    100,
  );
}

function dateValue(
  value: unknown,
) {
  if (value instanceof Date) {
    return value;
  }

  if (
    typeof value === 'object' &&
    value != null &&
    'toDate' in value
  ) {
    const toDate =
      (value as {
        toDate?: unknown;
      }).toDate;

    if (
      typeof toDate ===
      'function'
    ) {
      const result =
        (
          toDate as () => unknown
        ).call(value);

      if (result instanceof Date) {
        return result;
      }
    }
  }

  return new Date();
}

async function readLegacyComments(
  firestorePostId: string,
) {
  const commentsSnapshot =
    await firestore
      .collection('posts')
      .doc(firestorePostId)
      .collection('comments')
      .get();

  const comments: LegacyComment[] = [];

  for (
    const commentDoc
    of commentsSnapshot.docs
  ) {
    const data =
      commentDoc.data();

    const repliesSnapshot =
      await commentDoc.ref
        .collection('replies')
        .get();

    const replies =
      repliesSnapshot.docs.map(
        (replyDoc) => {
          const reply =
            replyDoc.data();

          return {
            firestoreId:
              replyDoc.id,

            uid:
              stringValue(
                reply.uid,
              ),

            user:
              displayNameValue(
                reply.user,
              ),

            text:
              stringValue(
                reply.text,
              ),

            imageUrl:
              nullableString(
                reply.imageUrl,
              ),

            replyTo:
              nullableString(
                reply.replyTo,
                100,
              ),

            createdAt:
              dateValue(
                reply.timestamp,
              ),

            replies: [],
          } satisfies LegacyComment;
        },
      );

    comments.push({
      firestoreId:
        commentDoc.id,

      uid:
        stringValue(
          data.uid,
        ),

      user:
        displayNameValue(
          data.user,
        ),

      text:
        stringValue(
          data.text,
        ),

      imageUrl:
        nullableString(
          data.imageUrl,
        ),

      replyTo: null,

      createdAt:
        dateValue(
          data.timestamp,
        ),

      replies,
    });
  }

  return comments;
}

async function migratePostComments() {
  console.log(
    'Starting post comments migration...',
  );

  // 不能枚举 Firestore 的 posts 父文档来发现评论：
  // Firestore 允许父文档不存在、子集合仍存在。
  //
  // PostgreSQL 已经拥有完整帖子清单，
  // 所以从 PostgreSQL 的 firestoreId 逐个回查旧 comments 最稳妥。
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
      },
    });

  let postsChecked = 0;

  let commentsFound = 0;
  let repliesFound = 0;

  let commentsUpserted = 0;
  let repliesUpserted = 0;

  let missingUsers = 0;
  let failed = 0;

  for (const post of posts) {
    const firestorePostId =
      post.firestoreId;

    if (firestorePostId == null) {
      continue;
    }

    postsChecked++;

    try {
      const legacyComments =
        await readLegacyComments(
          firestorePostId,
        );

      commentsFound +=
        legacyComments.length;

      repliesFound +=
        legacyComments.reduce(
          (sum, comment) =>
            sum +
            comment.replies.length,
          0,
        );

      const firebaseUids =
        [
          ...new Set(
            legacyComments
              .flatMap(
                (comment) => [
                  comment.uid,
                  ...comment.replies.map(
                    (reply) =>
                      reply.uid,
                  ),
                ],
              )
              .filter(
                (uid) =>
                  uid.length > 0,
              ),
          ),
        ];

      const users =
        firebaseUids.length === 0
          ? []
          : await prisma
              .user
              .findMany({
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

      const userIdByFirebaseUid =
        new Map(
          users.map(
            (user) => [
              user.firebaseUid,
              user.id,
            ],
          ),
        );

      for (
        const firebaseUid
        of firebaseUids
      ) {
        if (
          !userIdByFirebaseUid.has(
            firebaseUid,
          )
        ) {
          missingUsers++;

          console.warn(
            `[USER MISSING] post=${firestorePostId} uid=${firebaseUid}`,
          );
        }
      }

      await prisma.$transaction(
        async (transaction) => {
          for (
            const legacyComment
            of legacyComments
          ) {
            const commentPath =
              `posts/${firestorePostId}/comments/${legacyComment.firestoreId}`;

            // 完整 Firestore path 是迁移幂等键。
            // 重跑脚本只更新旧记录，不会删除 Node 新产生的评论。
            const comment =
              await transaction
                .postComment
                .upsert({
                  where: {
                    firestorePath:
                      commentPath,
                  },

                  update: {
                    authorId:
                      userIdByFirebaseUid
                        .get(
                          legacyComment.uid,
                        ) ?? null,

                    authorName:
                      legacyComment.user,

                    text:
                      legacyComment.text,

                    imageUrl:
                      legacyComment.imageUrl,

                    createdAt:
                      legacyComment.createdAt,
                  },

                  create: {
                    firestorePath:
                      commentPath,

                    postId:
                      post.id,

                    authorId:
                      userIdByFirebaseUid
                        .get(
                          legacyComment.uid,
                        ) ?? null,

                    authorName:
                      legacyComment.user,

                    text:
                      legacyComment.text,

                    imageUrl:
                      legacyComment.imageUrl,

                    createdAt:
                      legacyComment.createdAt,
                  },

                  select: {
                    id: true,
                  },
                });

            for (
              const legacyReply
              of legacyComment.replies
            ) {
              const replyPath =
                `${commentPath}/replies/${legacyReply.firestoreId}`;

              await transaction
                .postComment
                .upsert({
                  where: {
                    firestorePath:
                      replyPath,
                  },

                  update: {
                    postId:
                      post.id,

                    authorId:
                      userIdByFirebaseUid
                        .get(
                          legacyReply.uid,
                        ) ?? null,

                    parentId:
                      comment.id,

                    authorName:
                      legacyReply.user,

                    text:
                      legacyReply.text,

                    imageUrl:
                      legacyReply.imageUrl,

                    replyTo:
                      legacyReply.replyTo,

                    createdAt:
                      legacyReply.createdAt,
                  },

                  create: {
                    firestorePath:
                      replyPath,

                    postId:
                      post.id,

                    authorId:
                      userIdByFirebaseUid
                        .get(
                          legacyReply.uid,
                        ) ?? null,

                    parentId:
                      comment.id,

                    authorName:
                      legacyReply.user,

                    text:
                      legacyReply.text,

                    imageUrl:
                      legacyReply.imageUrl,

                    replyTo:
                      legacyReply.replyTo,

                    createdAt:
                      legacyReply.createdAt,
                  },
                });
            }
          }

          // 重新按数据库真实 top-level 评论数计算，
          // 因此即使 backfill 后已经出现 Node 新评论，count 也不会回退。
          const commentCount =
            await transaction
              .postComment
              .count({
                where: {
                  postId:
                    post.id,

                  parentId: null,
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
                commentCount,
              },
            });
        },
      );

      commentsUpserted +=
        legacyComments.length;

      repliesUpserted +=
        legacyComments.reduce(
          (sum, comment) =>
            sum +
            comment.replies.length,
          0,
        );
    } catch (error) {
      failed++;

      console.error(
        `[FAILED] ${firestorePostId}`,
        error,
      );
    }
  }

  const postgresComments =
    await prisma
      .postComment
      .count({
        where: {
          parentId: null,
        },
      });

  const postgresReplies =
    await prisma
      .postComment
      .count({
        where: {
          parentId: {
            not: null,
          },
        },
      });

  console.log('');
  console.log(
    'Post comments migration finished.',
  );
  console.log(
    `PostgreSQL posts checked: ${postsChecked}`,
  );
  console.log(
    `Firestore comments found: ${commentsFound}`,
  );
  console.log(
    `Firestore replies found: ${repliesFound}`,
  );
  console.log(
    `Comments upserted: ${commentsUpserted}`,
  );
  console.log(
    `Replies upserted: ${repliesUpserted}`,
  );
  console.log(
    `Missing users: ${missingUsers}`,
  );
  console.log(
    `Failed: ${failed}`,
  );
  console.log('');
  console.log(
    `PostgreSQL comments: ${postgresComments}`,
  );
  console.log(
    `PostgreSQL replies: ${postgresReplies}`,
  );
}

migratePostComments()
  .catch((error) => {
    console.error(
      'Post comments migration failed:',
      error,
    );

    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
