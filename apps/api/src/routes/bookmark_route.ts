import { Router } from 'express';
import { z } from 'zod';

import { Prisma } from '../generated/prisma/client.js';
import { prisma } from '../lib/prisma.js';
import { requireAuth } from '../middleware/require_auth.js';

export const postBookmarkRouter = Router();
export const userBookmarkRouter = Router();

// ============================================================
// Post 查询结构
// ============================================================

const bookmarkedPostInclude = {
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

type BookmarkedPostRecord =
  Prisma.PostGetPayload<{
    include: typeof bookmarkedPostInclude;
  }>;

// ============================================================
// Flutter PostModel Response
// ============================================================

function serializeBookmarkedPost(
  post: BookmarkedPostRecord,
  bookmarkedAt: Date,
) {
  const version =
    post.versions.find(
      (item) =>
        item.languageCode ===
        post.primaryLanguageCode,
    ) ??
    post.versions[0];

  if (version == null) {
    return null;
  }

  return {
    databaseId: post.id,

    id:
      post.firestoreId ??
      post.id,

    uid:
      post.author?.firebaseUid ??
      null,

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

    isBookmarked: true,

    bookmarkedAt:
      bookmarkedAt.toISOString(),
  };
}

// ============================================================
// Helpers
// ============================================================

function postWhereById(
  id: string,
): Prisma.PostWhereInput {
  const isDatabaseId =
    z.string()
      .uuid()
      .safeParse(id)
      .success;

  const identity: Prisma.PostWhereInput =
    isDatabaseId
      ? {
          OR: [
            { id },
            { firestoreId: id },
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

async function findCurrentUser(
  firebaseUid: string,
) {
  return prisma.user.findUnique({
    where: {
      firebaseUid,
    },

    select: {
      id: true,
    },
  });
}

async function findPost(
  id: string,
) {
  return prisma.post.findFirst({
    where:
      postWhereById(id),

    select: {
      id: true,
    },
  });
}

// ============================================================
// POST /api/v1/posts/:id/bookmark
//
// 收藏帖子。
// 使用 upsert，重复请求不会产生重复收藏。
// ============================================================

postBookmarkRouter.post(
  '/:id/bookmark',
  requireAuth,
  async (request, response) => {
    const rawId =
      request.params.id;

    if (
      typeof rawId !== 'string' ||
      rawId.trim().length === 0
    ) {
      response.status(400).json({
        error: 'INVALID_POST_ID',
        message: 'Invalid post id',
      });

      return;
    }

    const id = rawId.trim();

    const auth =
      response.locals.auth;

    try {
      const [user, post] =
        await Promise.all([
          findCurrentUser(
            auth.firebaseUid,
          ),
          findPost(id),
        ]);

      if (user == null) {
        response.status(404).json({
          error:
            'USER_NOT_FOUND',
          message:
            'Backend user does not exist',
        });

        return;
      }

      if (post == null) {
        response.status(404).json({
          error:
            'POST_NOT_FOUND',
          message:
            'Post does not exist',
        });

        return;
      }

      await prisma.postBookmark.upsert({
        where: {
          userId_postId: {
            userId: user.id,
            postId: post.id,
          },
        },

        update: {},

        create: {
          userId: user.id,
          postId: post.id,
        },
      });

      response.status(200).json({
        isBookmarked: true,
      });
    } catch (error) {
      console.error(
        'Bookmark post failed:',
        error,
      );

      response.status(500).json({
        error:
          'BOOKMARK_POST_FAILED',
        message:
          'Unable to bookmark post',
      });
    }
  },
);

// ============================================================
// DELETE /api/v1/posts/:id/bookmark
//
// 取消收藏。
// deleteMany 让重复 DELETE 也保持幂等。
// ============================================================

postBookmarkRouter.delete(
  '/:id/bookmark',
  requireAuth,
  async (request, response) => {
    const rawId =
      request.params.id;

    if (
      typeof rawId !== 'string' ||
      rawId.trim().length === 0
    ) {
      response.status(400).json({
        error: 'INVALID_POST_ID',
        message: 'Invalid post id',
      });

      return;
    }

    const id = rawId.trim();

    const auth =
      response.locals.auth;

    try {
      const [user, post] =
        await Promise.all([
          findCurrentUser(
            auth.firebaseUid,
          ),
          findPost(id),
        ]);

      if (user == null) {
        response.status(404).json({
          error:
            'USER_NOT_FOUND',
          message:
            'Backend user does not exist',
        });

        return;
      }

      if (post == null) {
        response.status(404).json({
          error:
            'POST_NOT_FOUND',
          message:
            'Post does not exist',
        });

        return;
      }

      await prisma.postBookmark.deleteMany({
        where: {
          userId: user.id,
          postId: post.id,
        },
      });

      response.status(200).json({
        isBookmarked: false,
      });
    } catch (error) {
      console.error(
        'Remove bookmark failed:',
        error,
      );

      response.status(500).json({
        error:
          'REMOVE_BOOKMARK_FAILED',
        message:
          'Unable to remove bookmark',
      });
    }
  },
);

// ============================================================
// GET /api/v1/users/me/bookmarks
//
// 获取当前用户全部收藏。
// 最新收藏排前面。
// ============================================================

userBookmarkRouter.get(
  '/',
  requireAuth,
  async (_request, response) => {
    const auth =
      response.locals.auth;

    try {
      const user =
        await findCurrentUser(
          auth.firebaseUid,
        );

      if (user == null) {
        response.status(404).json({
          error:
            'USER_NOT_FOUND',
          message:
            'Backend user does not exist',
        });

        return;
      }

      const bookmarks =
        await prisma.postBookmark.findMany({
          where: {
            userId: user.id,
            post: {
              reports: {
                none: { status: 'actioned' },
              },
            },
          },

          orderBy: {
            createdAt: 'desc',
          },

          include: {
            post: {
              include:
                bookmarkedPostInclude,
            },
          },
        });

      const posts =
        bookmarks
          .map((bookmark) =>
            serializeBookmarkedPost(
              bookmark.post,
              bookmark.createdAt,
            ),
          )
          .filter(
            (post) =>
              post != null,
          );

      response.status(200).json({
        posts,
      });
    } catch (error) {
      console.error(
        'Get bookmarks failed:',
        error,
      );

      response.status(500).json({
        error:
          'GET_BOOKMARKS_FAILED',
        message:
          'Unable to load bookmarks',
      });
    }
  },
);