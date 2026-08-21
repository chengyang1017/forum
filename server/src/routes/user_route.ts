import { Router } from 'express';
import { z } from 'zod';

import { prisma } from '../lib/prisma.js';
import { requireAuth } from '../middleware/require_auth.js';

const syncUserSchema = z.object({
  username: z.string().trim().min(1).max(50),
  nickname: z.string().trim().max(100).nullable().optional(),
  avatarUrl: z.string().trim().url().nullable().optional(),
  bio: z.string().max(5000).nullable().optional(),
  showAge: z.boolean().optional(),
});

export const userRouter = Router();

userRouter.put(
  '/me',
  requireAuth,
  async (request, response) => {
    const parsed = syncUserSchema.safeParse(request.body);

    if (!parsed.success) {
      response.status(400).json({
        error: 'INVALID_REQUEST',
        message: 'Invalid user data',
      });
      return;
    }

    const auth = response.locals.auth;

    const user = await prisma.user.upsert({
      where: {
        firebaseUid: auth.firebaseUid,
      },
      update: {
        email: auth.email,
        username: parsed.data.username,
        nickname: parsed.data.nickname,
        avatarUrl: parsed.data.avatarUrl,
        bio: parsed.data.bio,
        showAge: parsed.data.showAge,
      },
      create: {
        firebaseUid: auth.firebaseUid,
        email: auth.email,
        username: parsed.data.username,
        nickname: parsed.data.nickname,
        avatarUrl: parsed.data.avatarUrl,
        bio: parsed.data.bio,
        showAge: parsed.data.showAge ?? true,
      },
    });

    response.status(200).json({
      user,
    });
  },
);