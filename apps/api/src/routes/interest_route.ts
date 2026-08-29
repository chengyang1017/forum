import { Router } from 'express';
import { z } from 'zod';

import { prisma } from '../lib/prisma.js';
import { requireAuth } from '../middleware/require_auth.js';

export const interestRouter = Router();

const interestsSchema = z.object({
  interests: z
    .array(
      z
        .string()
        .trim()
        .min(1)
        .max(150),
    )
    .max(200),
});

function normalizeInterests(
  interests: string[],
): string[] {
  return [...new Set(
    interests
      .map((interest) => interest.trim())
      .filter((interest) => interest.length > 0),
  )];
}

// ============================================================
// GET /api/v1/users/me/interests
//
// 从 PostgreSQL 获取当前用户兴趣。
// ============================================================

interestRouter.get(
  '/',
  requireAuth,
  async (_request, response) => {
    const auth = response.locals.auth;

    try {
      const user = await prisma.user.findUnique({
        where: {
          firebaseUid: auth.firebaseUid,
        },

        select: {
          interests: true,
          interestsMigratedAt: true,
        },
      });

      if (user == null) {
        response.status(404).json({
          error: 'USER_NOT_FOUND',
          message: 'Backend user does not exist',
        });

        return;
      }

      response.status(200).json({
        interests: user.interests,
        migrated:
          user.interestsMigratedAt != null,
      });
    } catch (error) {
      console.error(
        'Get interests failed:',
        error,
      );

      response.status(500).json({
        error: 'GET_INTERESTS_FAILED',
        message: 'Unable to load interests',
      });
    }
  },
);

// ============================================================
// PUT /api/v1/users/me/interests
//
// 正常修改兴趣。
// 前端传完整 interests 数组，后端完整替换。
// ============================================================

interestRouter.put(
  '/',
  requireAuth,
  async (request, response) => {
    const parsed =
      interestsSchema.safeParse(request.body);

    if (!parsed.success) {
      response.status(400).json({
        error: 'INVALID_REQUEST',
        message: 'Invalid interests',
        details: parsed.error.flatten(),
      });

      return;
    }

    const auth = response.locals.auth;

    const interests = normalizeInterests(
      parsed.data.interests,
    );

    try {
      const user = await prisma.user.update({
        where: {
          firebaseUid: auth.firebaseUid,
        },

        data: {
          interests,

          // 一旦已经开始使用 PostgreSQL 修改兴趣，
          // 就不能再让旧 Firestore 数据覆盖回来。
          interestsMigratedAt: new Date(),
        },

        select: {
          interests: true,
        },
      });

      response.status(200).json({
        interests: user.interests,
      });
    } catch (error) {
      console.error(
        'Update interests failed:',
        error,
      );

      response.status(500).json({
        error: 'UPDATE_INTERESTS_FAILED',
        message: 'Unable to update interests',
      });
    }
  },
);

// ============================================================
// POST /api/v1/users/me/interests/migrate
//
// 旧 Firestore → PostgreSQL 一次性迁移。
//
// interestsMigratedAt 已有值：
// 不再覆盖 PostgreSQL。
// ============================================================

interestRouter.post(
  '/migrate',
  requireAuth,
  async (request, response) => {
    const parsed =
      interestsSchema.safeParse(request.body);

    if (!parsed.success) {
      response.status(400).json({
        error: 'INVALID_REQUEST',
        message: 'Invalid interests',
        details: parsed.error.flatten(),
      });

      return;
    }

    const auth = response.locals.auth;

    const interests = normalizeInterests(
      parsed.data.interests,
    );

    try {
      const migration =
        await prisma.user.updateMany({
          where: {
            firebaseUid: auth.firebaseUid,
            interestsMigratedAt: null,
          },

          data: {
            interests,
            interestsMigratedAt: new Date(),
          },
        });

      const user = await prisma.user.findUnique({
        where: {
          firebaseUid: auth.firebaseUid,
        },

        select: {
          interests: true,
          interestsMigratedAt: true,
        },
      });

      if (user == null) {
        response.status(404).json({
          error: 'USER_NOT_FOUND',
          message: 'Backend user does not exist',
        });

        return;
      }

      response.status(200).json({
        interests: user.interests,

        // true = 这一次真的执行了旧数据迁移
        // false = 以前已经迁移过
        migrated: migration.count > 0,
      });
    } catch (error) {
      console.error(
        'Migrate interests failed:',
        error,
      );

      response.status(500).json({
        error: 'MIGRATE_INTERESTS_FAILED',
        message: 'Unable to migrate interests',
      });
    }
  },
);