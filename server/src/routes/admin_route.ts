import { Router } from 'express';
import { z } from 'zod';

import { prisma } from '../lib/prisma.js';
import { requireAuth } from '../middleware/require_auth.js';
import { requireAdmin } from '../middleware/require_admin.js';

export const adminRouter = Router();

adminRouter.use(
  requireAuth,
  requireAdmin,
);

// ============================================================
// Validation
// ============================================================

const reportStatusSchema = z.enum([
  'pending',
  'reviewed',
  'dismissed',
  'actioned',
]);

const reportListQuerySchema = z.object({
  status: reportStatusSchema
    .optional()
    .default('pending'),

  limit: z.coerce
    .number()
    .int()
    .min(1)
    .max(100)
    .optional()
    .default(50),

  cursor: z
    .string()
    .uuid()
    .optional(),
});

const updateReportStatusBodySchema = z
  .object({
    status: z.enum([
      'reviewed',
      'dismissed',
      'actioned',
    ]),

    note: z
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

function normalizeAdminNote(
  note: string | null | undefined,
) {
  if (
    note == null ||
    note.length === 0
  ) {
    return null;
  }

  return note;
}

function serializeReport(
  report: {
    id: string;
    reason: string;
    details: string | null;
    status: string;
    adminNote: string | null;
    handledAt: Date | null;
    createdAt: Date;
    updatedAt: Date;

    user: {
      username: string;
      nickname: string | null;
      avatarUrl: string | null;
    };

    handledBy: {
      username: string;
      nickname: string | null;
    } | null;

    post: {
      id: string;
      firestoreId: string | null;
      primaryLanguageCode: string;
      createdAt: Date;
      updatedAt: Date;

      author: {
        username: string;
        nickname: string | null;
        firebaseUid: string;
      } | null;

      versions: Array<{
        languageCode: string;
        title: string;
        content: string;
      }>;
    };
  },
) {
  const version =
    report.post.versions.find(
      (item) =>
        item.languageCode ===
        report.post.primaryLanguageCode,
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

    adminNote:
      report.adminNote,

    handledAt:
      report.handledAt
        ?.toISOString() ??
      null,

    handledBy:
      report.handledBy == null
        ? null
        : {
            username:
              report.handledBy.username,

            nickname:
              report.handledBy.nickname,
          },

    createdAt:
      report.createdAt.toISOString(),

    updatedAt:
      report.updatedAt.toISOString(),

    reporter: {
      username:
        report.user.username,

      nickname:
        report.user.nickname,

      avatarUrl:
        report.user.avatarUrl,
    },

    post: {
      databaseId:
        report.post.id,

      id:
        report.post.firestoreId ??
        report.post.id,

      title:
        version?.title ??
        '',

      content:
        version?.content ??
        '',

      languageCode:
        version?.languageCode ??
        report.post.primaryLanguageCode,

      primaryLanguageCode:
        report.post.primaryLanguageCode,

      author:
        report.post.author == null
          ? null
          : {
              firebaseUid:
                report.post.author.firebaseUid,

              username:
                report.post.author.username,

              nickname:
                report.post.author.nickname,
            },

      createdAt:
        report.post.createdAt
          .toISOString(),

      updatedAt:
        report.post.updatedAt
          .toISOString(),
    },
  };
}

const reportInclude = {
  user: {
    select: {
      username: true,
      nickname: true,
      avatarUrl: true,
    },
  },

  handledBy: {
    select: {
      username: true,
      nickname: true,
    },
  },

  post: {
    include: {
      author: {
        select: {
          firebaseUid: true,
          username: true,
          nickname: true,
        },
      },

      versions: {
        select: {
          languageCode: true,
          title: true,
          content: true,
        },
      },
    },
  },
} as const;

// ============================================================
// GET /api/v1/admin/me
// ============================================================

adminRouter.get(
  '/me',
  (_request, response) => {
    response.status(200).json({
      admin:
        response.locals.admin,
    });
  },
);

// ============================================================
// GET /api/v1/admin/dashboard
// ============================================================

adminRouter.get(
  '/dashboard',
  async (_request, response) => {
    try {
      const statusGroups =
        await prisma.postReport.groupBy({
          by: [
            'status',
          ],

          _count: {
            _all: true,
          },
        });

      const reports = {
        total: 0,
        pending: 0,
        reviewed: 0,
        dismissed: 0,
        actioned: 0,
      };

      for (const group of statusGroups) {
        const count =
          group._count._all;

        reports.total += count;

        switch (group.status) {
          case 'pending':
            reports.pending = count;
            break;

          case 'reviewed':
            reports.reviewed = count;
            break;

          case 'dismissed':
            reports.dismissed = count;
            break;

          case 'actioned':
            reports.actioned = count;
            break;
        }
      }

      response.status(200).json({
        reports,
      });
    } catch (error) {
      console.error(
        'Admin dashboard failed:',
        error,
      );

      response.status(500).json({
        error:
          'ADMIN_DASHBOARD_FAILED',

        message:
          'Unable to load admin dashboard',
      });
    }
  },
);

// ============================================================
// GET /api/v1/admin/reports
//
// ????? pending?
// ?? status / limit / cursor?
// ============================================================

adminRouter.get(
  '/reports',
  async (request, response) => {
    const parsedQuery =
      reportListQuerySchema.safeParse(
        request.query,
      );

    if (!parsedQuery.success) {
      response.status(400).json({
        error:
          'INVALID_REPORT_QUERY',

        message:
          'Invalid report query',

        details:
          parsedQuery.error.flatten(),
      });

      return;
    }

    const {
      status,
      limit,
      cursor,
    } = parsedQuery.data;

    try {
      const reports =
        await prisma.postReport.findMany({
          where: {
            status,
          },

          orderBy: [
            {
              createdAt: 'desc',
            },
            {
              id: 'desc',
            },
          ],

          take:
            limit + 1,

          ...(cursor == null
            ? {}
            : {
                cursor: {
                  id: cursor,
                },

                skip: 1,
              }),

          include:
            reportInclude,
        });

      const hasMore =
        reports.length > limit;

      const page =
        hasMore
          ? reports.slice(0, limit)
          : reports;

      response.status(200).json({
        reports:
          page.map(serializeReport),

        pagination: {
          limit,

          nextCursor:
            hasMore &&
            page.length > 0
              ? page[
                  page.length - 1
                ]!.id
              : null,
        },
      });
    } catch (error) {
      console.error(
        'Admin get reports failed:',
        error,
      );

      response.status(500).json({
        error:
          'ADMIN_GET_REPORTS_FAILED',

        message:
          'Unable to load reports',
      });
    }
  },
);

// ============================================================
// PATCH /api/v1/admin/reports/:id/status
//
// ????????
// ?????????
// handledById / handledAt / adminNote
// ============================================================

adminRouter.patch(
  '/reports/:id/status',
  async (request, response) => {
    const rawId =
      request.params.id;

    if (
      typeof rawId !== 'string' ||
      !z.string()
        .uuid()
        .safeParse(rawId)
        .success
    ) {
      response.status(400).json({
        error:
          'INVALID_REPORT_ID',

        message:
          'Invalid report id',
      });

      return;
    }

    const parsedBody =
      updateReportStatusBodySchema.safeParse(
        request.body,
      );

    if (!parsedBody.success) {
      response.status(400).json({
        error:
          'INVALID_REPORT_STATUS',

        message:
          'Invalid report status payload',

        details:
          parsedBody.error.flatten(),
      });

      return;
    }

    const admin =
      response.locals.admin;

    try {
      const existing =
        await prisma.postReport.findUnique({
          where: {
            id: rawId,
          },

          select: {
            id: true,
          },
        });

      if (existing == null) {
        response.status(404).json({
          error:
            'REPORT_NOT_FOUND',

          message:
            'Report does not exist',
        });

        return;
      }

      const report =
        await prisma.postReport.update({
          where: {
            id: rawId,
          },

          data: {
            status:
              parsedBody.data.status,

            adminNote:
              normalizeAdminNote(
                parsedBody.data.note,
              ),

            handledById:
              admin.id,

            handledAt:
              new Date(),
          },

          include:
            reportInclude,
        });

      response.status(200).json({
        report:
          serializeReport(report),
      });
    } catch (error) {
      console.error(
        'Admin update report failed:',
        error,
      );

      response.status(500).json({
        error:
          'ADMIN_UPDATE_REPORT_FAILED',

        message:
          'Unable to update report',
      });
    }
  },
);
