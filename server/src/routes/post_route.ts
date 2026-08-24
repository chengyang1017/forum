import { Router } from 'express';
import { z } from 'zod';

import { Prisma } from '../generated/prisma/client.js';
import { prisma } from '../lib/prisma.js';
import { requireAuth } from '../middleware/require_auth.js';

export const postRouter = Router();

// ============================================================
// Prisma 查询结构
// ============================================================

const postInclude = {
  author: {
    select: {
      firebaseUid: true,
    },
  },

  versions: true,

  images: {
    orderBy: {
      position: 'asc',
    },
  },
} satisfies Prisma.PostInclude;

type PostRecord = Prisma.PostGetPayload<{
  include: typeof postInclude;
}>;

// ============================================================
// Flutter PostModel Response
// ============================================================

function serializePost(
  post: PostRecord,
  languageCode: string,
) {
  const version = post.versions.find(
    (item) =>
      item.languageCode === languageCode,
  );

  if (version == null) {
    return null;
  }

  return {
    // --------------------------------------------------------
    // 迁移期间继续把 Firestore ID 给 Flutter。
    //
    // 因为 likes/comments 还在 Firestore，
    // Flutter 暂时不能拿 PostgreSQL UUID 当 post.id。
    // --------------------------------------------------------

    databaseId: post.id,

    id:
      post.firestoreId ??
      post.id,

    uid:
      post.author?.firebaseUid ?? null,

    title:
      version.title,

    content:
      version.content,

    bodyDelta:
      version.bodyDelta,

    category:
      post.category,

    languageCode:
      version.languageCode,

    primaryLanguageCode:
      post.primaryLanguageCode,

    availableLanguageCodes:
      post.versions.map(
        (item) =>
          item.languageCode,
      ),

    images:
      post.images.map(
        (image) =>
          image.url,
      ),

    likeCount:
      post.likeCount,

    commentCount:
      post.commentCount,

    timestamp:
      post.createdAt.toISOString(),

    updatedAt:
      post.updatedAt.toISOString(),
  };
}

// ============================================================
// POST /api/v1/posts
//
// 创建帖子。
// PostgreSQL 是新的业务主库。
// Firebase Storage 暂时仍负责图片文件。
//
// firestoreId:
// 迁移期继续使用 Flutter 提前生成的 Firestore doc id，
// 这样 Storage / Firestore likes/comments 仍能使用同一个帖子 ID。
// ============================================================

const createPostSchema = z.object({
  firestoreId: z
    .string()
    .trim()
    .min(1)
    .max(128),

  title: z
    .string()
    .trim()
    .min(1)
    .max(300),

  content: z
    .string()
    .max(5000),

  bodyDelta: z
    .array(z.unknown())
    .default([]),

  category: z
    .string()
    .trim()
    .min(1)
    .max(100),

  languageCode: z
    .string()
    .trim()
    .min(1)
    .max(32),

  images: z
    .array(
      z.string().url(),
    )
    .max(9)
    .default([]),
});

postRouter.post(
  '/',
  requireAuth,
  async (request, response) => {
    const parsed =
      createPostSchema.safeParse(
        request.body,
      );

    if (!parsed.success) {
      response.status(400).json({
        error: 'INVALID_REQUEST',
        message:
          'Invalid post data',
        details:
          parsed.error.flatten(),
      });

      return;
    }

    const auth =
      response.locals.auth;

    const {
      firestoreId,
      title,
      content,
      bodyDelta,
      category,
      languageCode,
      images,
    } = parsed.data;

    try {
      // --------------------------------------------------------
      // 当前 Firebase 用户
      // ↓
      // PostgreSQL User
      // --------------------------------------------------------

      const author =
        await prisma.user.findUnique({
          where: {
            firebaseUid:
              auth.firebaseUid,
          },

          select: {
            id: true,
          },
        });

      if (author == null) {
        response.status(404).json({
          error: 'USER_NOT_FOUND',
          message:
            'Backend user does not exist',
        });

        return;
      }

      // --------------------------------------------------------
      // 防止网络重试产生重复帖子。
      //
      // Flutter 已经生成固定 firestoreId，
      // 所以它可以暂时充当幂等键。
      // --------------------------------------------------------

      const existing =
        await prisma.post.findUnique({
          where: {
            firestoreId,
          },

          include: postInclude,
        });

      if (existing != null) {
        if (
          existing.authorId !==
          author.id
        ) {
          response.status(409).json({
            error:
              'POST_ID_CONFLICT',

            message:
              'Post id already exists',
          });

          return;
        }

        const result =
          serializePost(
            existing,
            existing.primaryLanguageCode,
          );

        response.status(200).json({
          post: result,
        });

        return;
      }

      // --------------------------------------------------------
      // Post + 主语言版本 + 图片
      // 必须作为一个数据库事务创建。
      // --------------------------------------------------------

      const post =
        await prisma.$transaction(
          async (transaction) => {
            const createdPost =
              await transaction.post.create({
                data: {
                  firestoreId,

                  authorId:
                    author.id,

                  category,

                  primaryLanguageCode:
                    languageCode,

                  likeCount: 0,
                  commentCount: 0,
                },
              });

            await transaction
              .postVersion
              .create({
                data: {
                  postId:
                    createdPost.id,

                  authorId:
                    author.id,

                  languageCode,

                  title,
                  content,

                  bodyDelta:
                    bodyDelta as Prisma.InputJsonValue,

                  type:
                    'original',
                },
              });

            if (images.length > 0) {
              await transaction
                .postImage
                .createMany({
                  data:
                    images.map(
                      (url, index) => ({
                        postId:
                          createdPost.id,

                        url,

                        position:
                          index,
                      }),
                    ),
                });
            }

            return transaction
              .post.findUniqueOrThrow({
                where: {
                  id:
                    createdPost.id,
                },

                include:
                  postInclude,
              });
          },
        );

      const result =
        serializePost(
          post,
          languageCode,
        );

      response.status(201).json({
        post: result,
      });
    } catch (error) {
      console.error(
        'Create post failed:',
        error,
      );

      response.status(500).json({
        error:
          'CREATE_POST_FAILED',

        message:
          'Unable to create post',
      });
    }
  },
);

// ============================================================
// 根据 Flutter 当前使用的帖子 ID 查 PostgreSQL Post
//
// 迁移期 Flutter 传的通常还是 firestoreId。
// 以后完全切 PostgreSQL 后，也允许传数据库 UUID。
// ============================================================

function postWhereById(
  id: string,
): Prisma.PostWhereInput {
  const isDatabaseId =
    z.string().uuid().safeParse(id).success;

  if (isDatabaseId) {
    return {
      OR: [
        {
          firestoreId: id,
        },
        {
          id,
        },
      ],
    };
  }

  return {
    firestoreId: id,
  };
}

function prismaErrorCode(
  error: unknown,
): string | null {
  if (
    typeof error !== 'object' ||
    error == null ||
    !('code' in error)
  ) {
    return null;
  }

  const code =
    (error as { code?: unknown }).code;

  return typeof code === 'string'
    ? code
    : null;
}

// ============================================================
// POST /api/v1/posts/:id/versions
//
// 给现有帖子发布新的语言版本。
//
// 保持你现有业务规则：
// 登录用户可以为帖子添加新的翻译版本。
// ============================================================

const createPostVersionSchema = z.object({
  languageCode: z
    .string()
    .trim()
    .min(1)
    .max(32),

  title: z
    .string()
    .trim()
    .min(1)
    .max(300),

  content: z
    .string()
    .trim()
    .min(1)
    .max(5000),

  bodyDelta: z
    .array(z.unknown())
    .default([]),

  type: z
    .enum([
      'manual',
      'ai',
      'ai_assisted',
    ])
    .default('manual'),
});

postRouter.post(
  '/:id/versions',
  requireAuth,
  async (request, response) => {
    const id = request.params.id;

    if (typeof id !== 'string') {
      response.status(400).json({
        error: 'INVALID_POST_ID',
        message: 'Invalid post id',
      });

      return;
    }

    const parsed =
      createPostVersionSchema.safeParse(
        request.body,
      );

    if (!parsed.success) {
      response.status(400).json({
        error: 'INVALID_REQUEST',
        message:
          'Invalid post version data',
        details:
          parsed.error.flatten(),
      });

      return;
    }

    const auth =
      response.locals.auth;

    const {
      languageCode,
      title,
      content,
      bodyDelta,
      type,
    } = parsed.data;

    try {
      // --------------------------------------------------------
      // 当前翻译作者
      // --------------------------------------------------------

      const author =
        await prisma.user.findUnique({
          where: {
            firebaseUid:
              auth.firebaseUid,
          },

          select: {
            id: true,
          },
        });

      if (author == null) {
        response.status(404).json({
          error: 'USER_NOT_FOUND',
          message:
            'Backend user does not exist',
        });

        return;
      }

      // --------------------------------------------------------
      // 找原帖子
      // --------------------------------------------------------

      const post =
        await prisma.post.findFirst({
          where:
            postWhereById(id),

          select: {
            id: true,
            primaryLanguageCode: true,
          },
        });

      if (post == null) {
        response.status(404).json({
          error: 'POST_NOT_FOUND',
          message:
            'Post does not exist',
        });

        return;
      }

      // 主语言本身已经存在，
      // 不能再通过“新增翻译”接口添加一次。
      if (
        languageCode ===
        post.primaryLanguageCode
      ) {
        response.status(409).json({
          error:
            'POST_VERSION_EXISTS',

          message:
            'Primary language version already exists',
        });

        return;
      }

      const existingVersion =
        await prisma.postVersion.findFirst({
          where: {
            postId:
              post.id,

            languageCode,
          },

          select: {
            id: true,
          },
        });

      if (existingVersion != null) {
        response.status(409).json({
          error:
            'POST_VERSION_EXISTS',

          message:
            'Post language version already exists',
        });

        return;
      }

      // --------------------------------------------------------
      // 新建版本 + 更新 Post.updatedAt
      // --------------------------------------------------------

      const result =
        await prisma.$transaction(
          async (transaction) => {
            await transaction
              .postVersion
              .create({
                data: {
                  postId:
                    post.id,

                  authorId:
                    author.id,

                  languageCode,

                  title,
                  content,

                  bodyDelta:
                    bodyDelta as Prisma.InputJsonValue,

                  type,
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
                  updatedAt:
                    new Date(),
                },
              });

            return transaction
              .post
              .findUniqueOrThrow({
                where: {
                  id:
                    post.id,
                },

                include:
                  postInclude,
              });
          },
        );

      response.status(201).json({
        post:
          serializePost(
            result,
            languageCode,
          ),
      });
    } catch (error) {
      console.error(
        'Create post version failed:',
        error,
      );

      if (
        prismaErrorCode(error) ===
        'P2002'
      ) {
        response.status(409).json({
          error:
            'POST_VERSION_EXISTS',

          message:
            'Post language version already exists',
        });

        return;
      }

      response.status(500).json({
        error:
          'CREATE_POST_VERSION_FAILED',

        message:
          'Unable to create post version',
      });
    }
  },
);

// ============================================================
// PATCH /api/v1/posts/:id/versions/:languageCode
//
// 编辑已有语言版本。
//
// 保持你现在 Firestore 的规则：
// 只有帖子所有者可以编辑帖子语言版本。
// ============================================================

const updatePostVersionSchema = z.object({
  title: z
    .string()
    .trim()
    .min(1)
    .max(300),

  content: z
    .string()
    .trim()
    .min(1)
    .max(5000),

  bodyDelta: z
    .array(z.unknown())
    .optional(),
});

postRouter.patch(
  '/:id/versions/:languageCode',
  requireAuth,
  async (request, response) => {
    const id =
      request.params.id;

    const languageCode =
      request.params.languageCode;

    if (
      typeof id !== 'string' ||
      typeof languageCode !== 'string'
    ) {
      response.status(400).json({
        error: 'INVALID_REQUEST',
        message:
          'Invalid post or language id',
      });

      return;
    }

    const parsed =
      updatePostVersionSchema.safeParse(
        request.body,
      );

    if (!parsed.success) {
      response.status(400).json({
        error: 'INVALID_REQUEST',
        message:
          'Invalid post version data',
        details:
          parsed.error.flatten(),
      });

      return;
    }

    const auth =
      response.locals.auth;

    const {
      title,
      content,
      bodyDelta,
    } = parsed.data;

    try {
      // --------------------------------------------------------
      // 找帖子，同时检查所有者。
      // --------------------------------------------------------

      const post =
        await prisma.post.findFirst({
          where:
            postWhereById(id),

          select: {
            id: true,

            author: {
              select: {
                firebaseUid: true,
              },
            },
          },
        });

      if (post == null) {
        response.status(404).json({
          error: 'POST_NOT_FOUND',
          message:
            'Post does not exist',
        });

        return;
      }

      if (
        post.author?.firebaseUid !==
        auth.firebaseUid
      ) {
        response.status(403).json({
          error: 'FORBIDDEN',
          message:
            'You cannot edit this post',
        });

        return;
      }

      // --------------------------------------------------------
      // 确认目标语言版本存在。
      // --------------------------------------------------------

      const version =
        await prisma.postVersion.findFirst({
          where: {
            postId:
              post.id,

            languageCode,
          },

          select: {
            id: true,
          },
        });

      if (version == null) {
        response.status(404).json({
          error:
            'POST_VERSION_NOT_FOUND',

          message:
            'Post language version does not exist',
        });

        return;
      }

      // --------------------------------------------------------
      // 正文版本 + Post.updatedAt 同一个事务更新。
      // --------------------------------------------------------

      const result =
        await prisma.$transaction(
          async (transaction) => {
            await transaction
              .postVersion
              .update({
                where: {
                  id:
                    version.id,
                },

                data: {
                  title,
                  content,

                  ...(bodyDelta !== undefined
                    ? {
                        bodyDelta:
                          bodyDelta as Prisma.InputJsonValue,
                      }
                    : {}),
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
                  updatedAt:
                    new Date(),
                },
              });

            return transaction
              .post
              .findUniqueOrThrow({
                where: {
                  id:
                    post.id,
                },

                include:
                  postInclude,
              });
          },
        );

      response.status(200).json({
        post:
          serializePost(
            result,
            languageCode,
          ),
      });
    } catch (error) {
      console.error(
        'Update post version failed:',
        error,
      );

      response.status(500).json({
        error:
          'UPDATE_POST_VERSION_FAILED',

        message:
          'Unable to update post version',
      });
    }
  },
);

// ============================================================
// PATCH /api/v1/posts/:id/images
//
// 更新帖子顶部图片。
// Firebase Storage 仍负责文件本身，
// PostgreSQL 只保存图片 URL 和顺序。
// ============================================================

const updatePostImagesSchema = z.object({
  images: z
    .array(
      z.string().url(),
    )
    .max(9),
});

postRouter.patch(
  '/:id/images',
  requireAuth,
  async (request, response) => {
    const id = request.params.id;

    if (typeof id !== 'string') {
      response.status(400).json({
        error: 'INVALID_POST_ID',
        message: 'Invalid post id',
      });

      return;
    }

    const parsed =
      updatePostImagesSchema.safeParse(
        request.body,
      );

    if (!parsed.success) {
      response.status(400).json({
        error: 'INVALID_REQUEST',
        message: 'Invalid image data',
        details: parsed.error.flatten(),
      });

      return;
    }

    const auth =
      response.locals.auth;

    const { images } = parsed.data;

    try {
      const post =
        await prisma.post.findFirst({
          where:
            postWhereById(id),

          select: {
            id: true,

            author: {
              select: {
                firebaseUid: true,
              },
            },
          },
        });

      if (post == null) {
        response.status(404).json({
          error: 'POST_NOT_FOUND',
          message: 'Post does not exist',
        });

        return;
      }

      if (
        post.author?.firebaseUid !==
        auth.firebaseUid
      ) {
        response.status(403).json({
          error: 'FORBIDDEN',
          message:
            'You cannot edit this post',
        });

        return;
      }

      const result =
        await prisma.$transaction(
          async (transaction) => {
            // 先删旧的图片关系
            await transaction
              .postImage
              .deleteMany({
                where: {
                  postId:
                    post.id,
                },
              });

            // 再按新顺序写回
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

            await transaction
              .post
              .update({
                where: {
                  id:
                    post.id,
                },

                data: {
                  updatedAt:
                    new Date(),
                },
              });

            return transaction
              .post
              .findUniqueOrThrow({
                where: {
                  id:
                    post.id,
                },

                include:
                  postInclude,
              });
          },
        );

      response.status(200).json({
        post:
          serializePost(
            result,
            result.primaryLanguageCode,
          ),
      });
    } catch (error) {
      console.error(
        'Update post images failed:',
        error,
      );

      response.status(500).json({
        error:
          'UPDATE_POST_IMAGES_FAILED',

        message:
          'Unable to update post images',
      });
    }
  },
);

// ============================================================
// DELETE /api/v1/posts/:id
//
// 删除帖子。
//
// PostVersion / PostImage 因为 Prisma relation
// 设置了 onDelete: Cascade，
// 所以删除 Post 后会自动一起删除。
// ============================================================

postRouter.delete(
  '/:id',
  requireAuth,
  async (request, response) => {
    const id = request.params.id;

    if (typeof id !== 'string') {
      response.status(400).json({
        error: 'INVALID_POST_ID',
        message: 'Invalid post id',
      });

      return;
    }

    const auth =
      response.locals.auth;

    try {
      const post =
        await prisma.post.findFirst({
          where:
            postWhereById(id),

          include: {
            author: {
              select: {
                firebaseUid: true,
              },
            },

            images: {
              orderBy: {
                position: 'asc',
              },
            },
          },
        });

      if (post == null) {
        response.status(404).json({
          error: 'POST_NOT_FOUND',
          message: 'Post does not exist',
        });

        return;
      }

      if (
        post.author?.firebaseUid !==
        auth.firebaseUid
      ) {
        response.status(403).json({
          error: 'FORBIDDEN',
          message:
            'You cannot delete this post',
        });

        return;
      }

      // 先记住 Storage URL。
      // PostgreSQL 删除后 Flutter 后面还能用它们
      // 做 Firebase Storage 清理。
      const imageUrls =
        post.images.map(
          (image) =>
            image.url,
        );

      await prisma.post.delete({
        where: {
          id:
            post.id,
        },
      });

      response.status(200).json({
        deleted: true,

        firestoreId:
          post.firestoreId,

        imageUrls,
      });
    } catch (error) {
      console.error(
        'Delete post failed:',
        error,
      );

      response.status(500).json({
        error:
          'DELETE_POST_FAILED',

        message:
          'Unable to delete post',
      });
    }
  },
);

// ============================================================
// PUT /api/v1/posts/:id/like
//
// 点赞帖子。
//
// PUT 表示“确保当前用户已经点赞”，
// 所以即使客户端因为网络问题重复请求，
// 也不会产生重复点赞。
// ============================================================

postRouter.put(
  '/:id/like',
  requireAuth,
  async (request, response) => {
    const id = request.params.id;

    if (typeof id !== 'string') {
      response.status(400).json({
        error: 'INVALID_POST_ID',
        message: 'Invalid post id',
      });

      return;
    }

    const auth =
      response.locals.auth;

    try {
      const [user, post] =
        await Promise.all([
          prisma.user.findUnique({
            where: {
              firebaseUid:
                auth.firebaseUid,
            },

            select: {
              id: true,
            },
          }),

          prisma.post.findFirst({
            where:
              postWhereById(id),

            select: {
              id: true,
            },
          }),
        ]);

      if (user == null) {
        response.status(404).json({
          error: 'USER_NOT_FOUND',
          message:
            'Backend user does not exist',
        });

        return;
      }

      if (post == null) {
        response.status(404).json({
          error: 'POST_NOT_FOUND',
          message:
            'Post does not exist',
        });

        return;
      }

      const result =
        await prisma.$transaction(
          async (transaction) => {
            // -----------------------------------------------
            // @@unique([postId, userId])
            // 已经从数据库层保证不能重复点赞。
            //
            // skipDuplicates 让重复 PUT 请求
            // 直接变成无副作用操作。
            // -----------------------------------------------

            await transaction
              .postLike
              .createMany({
                data: [
                  {
                    postId:
                      post.id,

                    userId:
                      user.id,
                  },
                ],

                skipDuplicates: true,
              });

            // -----------------------------------------------
            // 直接根据 PostLike 事实重新计算 likeCount。
            //
            // 这样即使历史 count 曾经漂移，
            // 点赞操作也会自动校正。
            // -----------------------------------------------

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

            return {
              liked: true,
              likeCount,
            };
          },
        );

      response.status(200).json(
        result,
      );
    } catch (error) {
      console.error(
        'Like post failed:',
        error,
      );

      response.status(500).json({
        error:
          'LIKE_POST_FAILED',

        message:
          'Unable to like post',
      });
    }
  },
);


// ============================================================
// DELETE /api/v1/posts/:id/like
//
// 取消点赞。
//
// DELETE 同样是幂等的：
// 没点赞的人重复取消，也不会报错。
// ============================================================

postRouter.delete(
  '/:id/like',
  requireAuth,
  async (request, response) => {
    const id =
      request.params.id;

    if (typeof id !== 'string') {
      response.status(400).json({
        error: 'INVALID_POST_ID',
        message: 'Invalid post id',
      });

      return;
    }

    const auth =
      response.locals.auth;

    try {
      const [user, post] =
        await Promise.all([
          prisma.user.findUnique({
            where: {
              firebaseUid:
                auth.firebaseUid,
            },

            select: {
              id: true,
            },
          }),

          prisma.post.findFirst({
            where:
              postWhereById(id),

            select: {
              id: true,
            },
          }),
        ]);

      if (user == null) {
        response.status(404).json({
          error: 'USER_NOT_FOUND',
          message:
            'Backend user does not exist',
        });

        return;
      }

      if (post == null) {
        response.status(404).json({
          error: 'POST_NOT_FOUND',
          message:
            'Post does not exist',
        });

        return;
      }

      const result =
        await prisma.$transaction(
          async (transaction) => {
            await transaction
              .postLike
              .deleteMany({
                where: {
                  postId:
                    post.id,

                  userId:
                    user.id,
                },
              });

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

            return {
              liked: false,
              likeCount,
            };
          },
        );

      response.status(200).json(
        result,
      );
    } catch (error) {
      console.error(
        'Unlike post failed:',
        error,
      );

      response.status(500).json({
        error:
          'UNLIKE_POST_FAILED',

        message:
          'Unable to unlike post',
      });
    }
  },
);

// ============================================================
// GET /api/v1/posts
//
// 示例：
//
// GET /api/v1/posts
//   ?category=general
//   &languageCode=zh
//
// 当前 Flutter watchPosts() 本来就要求：
// category + languageCode
// ============================================================

const listPostsQuerySchema = z.object({
  category: z
    .string()
    .trim()
    .min(1)
    .max(100),

  languageCode: z
    .string()
    .trim()
    .min(1)
    .max(32),

  limit: z
    .coerce
    .number()
    .int()
    .min(1)
    .max(50)
    .default(50),
});

postRouter.get(
  '/',
  requireAuth,
  async (request, response) => {
    const parsed =
      listPostsQuerySchema.safeParse(
        request.query,
      );

    if (!parsed.success) {
      response.status(400).json({
        error: 'INVALID_QUERY',
        message:
          'Invalid post query',
        details:
          parsed.error.flatten(),
      });

      return;
    }

    const {
      category,
      languageCode,
      limit,
    } = parsed.data;

    try {
      const posts =
        await prisma.post.findMany({
          where: {
            category,

            // -----------------------------------------------
            // 只返回存在目标语言版本的帖子。
            // -----------------------------------------------

            versions: {
              some: {
                languageCode,
              },
            },
          },

          include: postInclude,

          orderBy: {
            createdAt: 'desc',
          },

          take: limit,
        });

      const result = posts
        .map(
          (post) =>
            serializePost(
              post,
              languageCode,
            ),
        )
        .filter(
          (
            post,
          ): post is NonNullable<
            typeof post
          > => post != null,
        );

      response.status(200).json({
        posts: result,
      });
    } catch (error) {
      console.error(
        'Get posts failed:',
        error,
      );

      response.status(500).json({
        error: 'GET_POSTS_FAILED',
        message:
          'Unable to load posts',
      });
    }
  },
);

// ============================================================
// GET /api/v1/posts/:id
//
// 可选：
//
// GET /api/v1/posts/xxx?languageCode=vi
//
// 如果没有 languageCode，
// 默认返回主语言版本。
// ============================================================

const getPostQuerySchema = z.object({
  languageCode: z
    .string()
    .trim()
    .min(1)
    .max(32)
    .optional(),
});

postRouter.get(
  '/:id',
  requireAuth,
  async (request, response) => {
    const id = request.params.id;

    if (typeof id !== 'string') {
      response.status(400).json({
        error: 'INVALID_POST_ID',
        message:
          'Invalid post id',
      });

      return;
    }

    const parsed =
      getPostQuerySchema.safeParse(
        request.query,
      );

    if (!parsed.success) {
      response.status(400).json({
        error: 'INVALID_QUERY',
        message:
          'Invalid post query',
        details:
          parsed.error.flatten(),
      });

      return;
    }

    try {
      // --------------------------------------------------------
      // 目前 Flutter 使用的是 Firestore post id。
      //
      // 同时允许 PostgreSQL UUID，
      // 方便以后完全切库之后继续使用这个接口。
      // --------------------------------------------------------

      const validDatabaseId =
        z.string().uuid().safeParse(id);

      const post =
        await prisma.post.findFirst({
          where:
            validDatabaseId.success
              ? {
                  OR: [
                    {
                      firestoreId: id,
                    },
                    {
                      id,
                    },
                  ],
                }
              : {
                  firestoreId: id,
                },

          include: postInclude,
        });

      if (post == null) {
        response.status(404).json({
          error: 'POST_NOT_FOUND',
          message:
            'Post does not exist',
        });

        return;
      }

      const languageCode =
        parsed.data.languageCode ??
        post.primaryLanguageCode;

      const result =
        serializePost(
          post,
          languageCode,
        );

      if (result == null) {
        response.status(404).json({
          error:
            'POST_VERSION_NOT_FOUND',

          message:
            'Post language version does not exist',
        });

        return;
      }

      response.status(200).json({
        post: result,
      });
    } catch (error) {
      console.error(
        'Get post failed:',
        error,
      );

      response.status(500).json({
        error: 'GET_POST_FAILED',
        message:
          'Unable to load post',
      });
    }
  },
);