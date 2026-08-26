import { Router } from 'express';
import { z } from 'zod';

import { Prisma } from '../generated/prisma/client.js';
import { prisma } from '../lib/prisma.js';
import { requireAuth } from '../middleware/require_auth.js';

export const postReportRouter = Router();
export const userReportRouter = Router();

// ============================================================
// Validation
// ============================================================

const reportReasonSchema = z.enum([
  'spam',
  'harassment',
  'hate',
  'sexual',
  'violence',
  'misinformation',
  'copyright',
  'other',
]);

const createReportBodySchema = z
  .object({
    reason: reportReasonSchema,
    details: z
      .string()
      .trim()
      .max(2000)
      .nullable()
      .optional(),
  })
  .strict();

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

  if (isDatabaseId) {
    return {
      OR: [
        {
          id,
        },
        {
          firestoreId: id,
        },
      ],
    };
  }

  return {
    firestoreId: id,
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
      firestoreId: true,
      authorId: true,
    },
  });
}

function isUniqueConstraintError(
  error: unknown,
) {
  if (
    typeof error !== 'object' ||
    error == null ||
    !('code' in error)
  ) {
    return false;
  }

  return (
    (error as { code?: unknown }).code ===
    'P2002'
  );
}

function normalizeDetails(
  details: string | null | undefined,
) {
  if (
    details == null ||
    details.length === 0
  ) {
    return null;
  }

  return details;
}

// ============================================================
// GET /api/v1/users/me/reports
//
// 获取当前用户提交过的举报。
// 这里只暴露当前用户自己的举报，不暴露其他举报用户。
// ============================================================

userReportRouter.get(
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

      const reports =
        await prisma.postReport.findMany({
          where: {
            userId: user.id,
          },

          orderBy: {
            createdAt: 'desc',
          },

          include: {
            post: {
              include: {
                author: {
                  select: {
                    firebaseUid: true,
                  },
                },

                versions: true,
              },
            },
          },
        });

      response.status(200).json({
        reports:
          reports.map((report) => {
            const version =
              report.post.versions.find(
                (item) =>
                  item.languageCode ===
                  report.post
                    .primaryLanguageCode,
              ) ??
              report.post.versions[0];

            return {
              id:
                report.id,

              reason:
                report.reason,

              details:
                report.details,

              status:
                report.status,

              createdAt:
                report.createdAt
                  .toISOString(),

              updatedAt:
                report.updatedAt
                  .toISOString(),

              post: {
                databaseId:
                  report.post.id,

                id:
                  report.post.firestoreId ??
                  report.post.id,

                uid:
                  report.post.author
                    ?.firebaseUid ??
                  null,

                title:
                  version?.title ??
                  '',

                content:
                  version?.content ??
                  '',

                languageCode:
                  version?.languageCode ??
                  report.post
                    .primaryLanguageCode,

                primaryLanguageCode:
                  report.post
                    .primaryLanguageCode,

                timestamp:
                  report.post.createdAt
                    .toISOString(),

                updatedAt:
                  report.post.updatedAt
                    .toISOString(),
              },
            };
          }),
      });
    } catch (error) {
      console.error(
        'Get reports failed:',
        error,
      );

      response.status(500).json({
        error:
          'GET_REPORTS_FAILED',
        message:
          'Unable to load reports',
      });
    }
  },
);

// ============================================================
// POST /api/v1/posts/:id/reports
//
// 举报帖子。
// 同一用户同一帖子只能有一条举报。
// ============================================================

postReportRouter.post(
  '/:id/reports',
  requireAuth,
  async (request, response) => {
    const rawId =
      request.params.id;

    if (
      typeof rawId !== 'string' ||
      rawId.trim().length === 0
    ) {
      response.status(400).json({
        error:
          'INVALID_POST_ID',
        message:
          'Invalid post id',
      });

      return;
    }

    const parsedBody =
      createReportBodySchema.safeParse(
        request.body,
      );

    if (!parsedBody.success) {
      response.status(400).json({
        error:
          'INVALID_REPORT',
        message:
          'Invalid report payload',
        details:
          parsedBody.error.flatten(),
      });

      return;
    }

    const id =
      rawId.trim();

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

      if (post.authorId === user.id) {
        response.status(403).json({
          error:
            'SELF_REPORT_NOT_ALLOWED',
          message:
            'You cannot report your own post',
        });

        return;
      }

      const existingReport =
        await prisma.postReport.findUnique({
          where: {
            userId_postId: {
              userId:
                user.id,
              postId:
                post.id,
            },
          },

          select: {
            id: true,
          },
        });

      if (existingReport != null) {
        response.status(409).json({
          error:
            'REPORT_ALREADY_EXISTS',
          message:
            'You have already reported this post',
        });

        return;
      }

      const report =
        await prisma.postReport.create({
          data: {
            userId:
              user.id,

            postId:
              post.id,

            reason:
              parsedBody.data.reason,

            details:
              normalizeDetails(
                parsedBody.data.details,
              ),
          },
        });

      response.status(201).json({
        report: {
          id:
            report.id,

          postId:
            post.firestoreId ??
            post.id,

          reason:
            report.reason,

          details:
            report.details,

          status:
            report.status,

          createdAt:
            report.createdAt
              .toISOString(),

          updatedAt:
            report.updatedAt
              .toISOString(),
        },
      });
    } catch (error) {
      if (
        isUniqueConstraintError(error)
      ) {
        response.status(409).json({
          error:
            'REPORT_ALREADY_EXISTS',
          message:
            'You have already reported this post',
        });

        return;
      }

      console.error(
        'Create report failed:',
        error,
      );

      response.status(500).json({
        error:
          'CREATE_REPORT_FAILED',
        message:
          'Unable to report post',
      });
    }
  },
);
