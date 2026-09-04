import { Router } from 'express';
import { z } from 'zod';

import { Prisma } from '../generated/prisma/client.js';
import { prisma } from '../lib/prisma.js';
import { requireAuth } from '../middleware/require_auth.js';

export const postDataRouter = Router();

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

function postWhereById(id: string): Prisma.PostWhereInput {
  const databaseId = z.string().uuid().safeParse(id);
  const identity: Prisma.PostWhereInput = databaseId.success
    ? {
        OR: [
          { firestoreId: id },
          { id },
        ],
      }
    : { firestoreId: id };

  return {
    AND: [
      identity,
      {
        reports: {
          none: { status: 'actioned' },
        },
      },
    ],
  };
}

function serializePost(
  post: PostRecord,
  languageCode: string,
  currentUserLikeUid: string | null = null,
) {
  const version = post.versions.find(
    (item) => item.languageCode === languageCode,
  );

  if (version == null) {
    return null;
  }

  return {
    databaseId: post.id,
    id: post.firestoreId ?? post.id,
    uid: post.author?.firebaseUid ?? null,
    title: version.title,
    content: version.content,
    bodyDelta: version.bodyDelta,
    category: post.category,
    languageCode: version.languageCode,
    primaryLanguageCode: post.primaryLanguageCode,
    availableLanguageCodes: post.versions.map(
      (item) => item.languageCode,
    ),
    images: post.images.map((image) => image.url),
    likes: currentUserLikeUid == null ? [] : [currentUserLikeUid],
    likeCount: post.likeCount,
    commentCount: post.commentCount,
    timestamp: post.createdAt.toISOString(),
    updatedAt: post.updatedAt.toISOString(),
  };
}

// GET /api/v1/posts/by-user/:firebaseUid
postDataRouter.get(
  '/by-user/:firebaseUid',
  requireAuth,
  async (request, response) => {
    const firebaseUid = request.params.firebaseUid;

    const parsedLimit = z.coerce
      .number()
      .int()
      .min(1)
      .max(100)
      .default(50)
      .safeParse(request.query.limit);

    if (
      typeof firebaseUid !== 'string' ||
      !parsedLimit.success
    ) {
      response.status(400).json({
        error: 'INVALID_QUERY',
        message: 'Invalid user post query',
      });
      return;
    }

    const auth = response.locals.auth;

    try {
      const posts = await prisma.post.findMany({
        where: {
          author: {
            firebaseUid,
          },
          reports: {
            none: { status: 'actioned' },
          },
        },
        include: {
          ...postInclude,
          likes: {
            where: {
              user: {
                firebaseUid: auth.firebaseUid,
              },
            },
            select: {
              id: true,
            },
          },
          bookmarks: {
            where: {
              user: {
                firebaseUid: auth.firebaseUid,
              },
            },
            select: {
              id: true,
            },
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
        take: parsedLimit.data,
      });

      const result = posts
        .map((post) => {
          const serialized = serializePost(
            post,
            post.primaryLanguageCode,
            post.likes.length > 0 ? auth.firebaseUid : null,
          );

          if (serialized == null) {
            return null;
          }

          return {
            ...serialized,
            isBookmarked: post.bookmarks.length > 0,
          };
        })
        .filter(
          (post): post is NonNullable<typeof post> => post != null,
        );

      response.status(200).json({ posts: result });
    } catch (error) {
      console.error('Get user posts failed:', error);
      response.status(500).json({
        error: 'GET_USER_POSTS_FAILED',
        message: 'Unable to load user posts',
      });
    }
  },
);

// GET /api/v1/posts/:id/versions/:languageCode
postDataRouter.get(
  '/:id/versions/:languageCode',
  requireAuth,
  async (request, response) => {
    const id = request.params.id;
    const languageCode = request.params.languageCode;

    if (
      typeof id !== 'string' ||
      typeof languageCode !== 'string'
    ) {
      response.status(400).json({
        error: 'INVALID_REQUEST',
        message: 'Invalid post or language id',
      });
      return;
    }

    try {
      const post = await prisma.post.findFirst({
        where: postWhereById(id),
        select: {
          id: true,
        },
      });

      if (post == null) {
        response.status(404).json({
          error: 'POST_NOT_FOUND',
          message: 'Post does not exist',
        });
        return;
      }

      const version = await prisma.postVersion.findFirst({
        where: {
          postId: post.id,
          languageCode,
        },
      });

      if (version == null) {
        response.status(404).json({
          error: 'POST_VERSION_NOT_FOUND',
          message: 'Post language version does not exist',
        });
        return;
      }

      response.status(200).json({
        version: {
          id: version.id,
          languageCode: version.languageCode,
          title: version.title,
          content: version.content,
          bodyDelta: version.bodyDelta,
          type: version.type,
          createdAt: version.createdAt.toISOString(),
          updatedAt: version.updatedAt.toISOString(),
        },
      });
    } catch (error) {
      console.error('Get post version failed:', error);
      response.status(500).json({
        error: 'GET_POST_VERSION_FAILED',
        message: 'Unable to load post version',
      });
    }
  },
);

const updateVersionSchema = z.object({
  title: z.string().trim().min(1).max(300),
  content: z.string().trim().min(1).max(5000),
  bodyDelta: z.array(z.unknown()).optional(),
  images: z.array(z.string().url()).max(9).optional(),
});

// PATCH /api/v1/posts/:id/versions/:languageCode
//
// This router is mounted before postRouter, so this handler becomes the
// authoritative edit path. The previous version and image list are snapshotted
// in the same PostgreSQL transaction as the update.
postDataRouter.patch(
  '/:id/versions/:languageCode',
  requireAuth,
  async (request, response) => {
    const id = request.params.id;
    const languageCode = request.params.languageCode;

    if (
      typeof id !== 'string' ||
      typeof languageCode !== 'string'
    ) {
      response.status(400).json({
        error: 'INVALID_REQUEST',
        message: 'Invalid post or language id',
      });
      return;
    }

    const parsed = updateVersionSchema.safeParse(request.body);

    if (!parsed.success) {
      response.status(400).json({
        error: 'INVALID_REQUEST',
        message: 'Invalid post version data',
        details: parsed.error.flatten(),
      });
      return;
    }

    const auth = response.locals.auth;

    try {
      const result = await prisma.$transaction(
        async (transaction) => {
          const post = await transaction.post.findFirst({
            where: postWhereById(id),
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
            return { kind: 'post-not-found' as const };
          }

          if (post.author?.firebaseUid !== auth.firebaseUid) {
            return { kind: 'forbidden' as const };
          }

          const version = await transaction.postVersion.findFirst({
            where: {
              postId: post.id,
              languageCode,
            },
          });

          if (version == null) {
            return { kind: 'version-not-found' as const };
          }

          const currentImages = post.images.map((image) => image.url);
          const nextBodyDelta =
            parsed.data.bodyDelta ?? version.bodyDelta;
          const nextImages = parsed.data.images ?? currentImages;

          const changed =
            version.title !== parsed.data.title ||
            version.content !== parsed.data.content ||
            JSON.stringify(version.bodyDelta) !==
              JSON.stringify(nextBodyDelta) ||
            JSON.stringify(currentImages) !==
              JSON.stringify(nextImages);

          if (changed) {
            const historyCount = await transaction.postEditHistory.count({
              where: {
                postId: post.id,
                languageCode,
              },
            });

            await transaction.postEditHistory.create({
              data: {
                postId: post.id,
                editedById: post.authorId,
                languageCode,
                type: historyCount === 0 ? 'original' : 'edit',
                title: version.title,
                content: version.content,
                bodyDelta:
                  version.bodyDelta as Prisma.InputJsonValue,
                imageUrls:
                  currentImages as Prisma.InputJsonValue,
                editedAt:
                  historyCount === 0
                    ? version.createdAt
                    : version.updatedAt,
              },
            });
          }

          await transaction.postVersion.update({
            where: {
              id: version.id,
            },
            data: {
              title: parsed.data.title,
              content: parsed.data.content,
              ...(parsed.data.bodyDelta !== undefined
                ? {
                    bodyDelta:
                      parsed.data.bodyDelta as Prisma.InputJsonValue,
                  }
                : {}),
            },
          });

          if (parsed.data.images !== undefined) {
            await transaction.postImage.deleteMany({
              where: {
                postId: post.id,
              },
            });

            if (parsed.data.images.length > 0) {
              await transaction.postImage.createMany({
                data: parsed.data.images.map((url, index) => ({
                  postId: post.id,
                  url,
                  position: index,
                })),
              });
            }
          }

          await transaction.post.update({
            where: {
              id: post.id,
            },
            data: {
              updatedAt: new Date(),
            },
          });

          const updated = await transaction.post.findUniqueOrThrow({
            where: {
              id: post.id,
            },
            include: postInclude,
          });

          return {
            kind: 'ok' as const,
            post: updated,
          };
        },
      );

      if (result.kind === 'post-not-found') {
        response.status(404).json({
          error: 'POST_NOT_FOUND',
          message: 'Post does not exist',
        });
        return;
      }

      if (result.kind === 'forbidden') {
        response.status(403).json({
          error: 'FORBIDDEN',
          message: 'You cannot edit this post',
        });
        return;
      }

      if (result.kind === 'version-not-found') {
        response.status(404).json({
          error: 'POST_VERSION_NOT_FOUND',
          message: 'Post language version does not exist',
        });
        return;
      }

      response.status(200).json({
        post: serializePost(result.post, languageCode),
      });
    } catch (error) {
      console.error('Update post version failed:', error);
      response.status(500).json({
        error: 'UPDATE_POST_VERSION_FAILED',
        message: 'Unable to update post version',
      });
    }
  },
);

// GET /api/v1/posts/:id/edit-history
postDataRouter.get(
  '/:id/edit-history',
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

    const auth = response.locals.auth;

    try {
      const post = await prisma.post.findFirst({
        where: postWhereById(id),
        include: {
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

      if (post.author?.firebaseUid !== auth.firebaseUid) {
        response.status(403).json({
          error: 'FORBIDDEN',
          message: 'You cannot view this edit history',
        });
        return;
      }

      const history = await prisma.postEditHistory.findMany({
        where: {
          postId: post.id,
        },
        orderBy: {
          editedAt: 'desc',
        },
      });

      response.status(200).json({
        history: history.map((item) => ({
          id: item.id,
          type: item.type,
          languageCode: item.languageCode,
          title: item.title,
          content: item.content,
          bodyDelta: item.bodyDelta,
          imageUrls: item.imageUrls,
          editedAt: item.editedAt.toISOString(),
        })),
      });
    } catch (error) {
      console.error('Get edit history failed:', error);
      response.status(500).json({
        error: 'GET_EDIT_HISTORY_FAILED',
        message: 'Unable to load edit history',
      });
    }
  },
);
