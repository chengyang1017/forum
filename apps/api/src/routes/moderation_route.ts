import { Router } from 'express';
import { z } from 'zod';

import {
  firebaseAuth,
  firebaseFirestore,
  getFirebaseStorageBucket,
} from '../lib/firebase_admin.js';
import { prisma } from '../lib/prisma.js';
import { requireAuth } from '../middleware/require_auth.js';
import { requireAdmin } from '../middleware/require_admin.js';

export const moderationRouter = Router();

moderationRouter.use(requireAuth, requireAdmin);

const uuidSchema = z.string().uuid();

function storagePathFromDownloadUrl(downloadUrl: string): string | null {
  try {
    const url = new URL(downloadUrl);
    const marker = '/o/';
    const markerIndex = url.pathname.indexOf(marker);
    if (markerIndex === -1) return null;
    return decodeURIComponent(url.pathname.substring(markerIndex + marker.length));
  } catch {
    return null;
  }
}

async function findReport(reportId: string) {
  return prisma.postReport.findUnique({
    where: { id: reportId },
    include: {
      post: {
        include: {
          author: {
            select: {
              id: true,
              firebaseUid: true,
              username: true,
            },
          },
          images: {
            select: { url: true },
          },
        },
      },
    },
  });
}

// Soft-hide a reported post. Public post reads treat any actioned report as a
// moderation visibility barrier, while the post remains available to admins.
moderationRouter.post(
  '/reports/:reportId/hide-post',
  async (request, response) => {
    const reportId = request.params.reportId;
    if (typeof reportId !== 'string' || !uuidSchema.safeParse(reportId).success) {
      response.status(400).json({ error: 'INVALID_REPORT_ID' });
      return;
    }

    const admin = response.locals.admin;

    try {
      const report = await prisma.postReport.findUnique({
        where: { id: reportId },
        select: { id: true },
      });
      if (report == null) {
        response.status(404).json({ error: 'REPORT_NOT_FOUND' });
        return;
      }

      const updated = await prisma.postReport.update({
        where: { id: reportId },
        data: {
          status: 'actioned',
          handledById: admin.id,
          handledAt: new Date(),
        },
      });

      response.status(200).json({
        hidden: true,
        reportId: updated.id,
        status: updated.status,
      });
    } catch (error) {
      console.error('Admin hide post failed:', error);
      response.status(500).json({ error: 'ADMIN_HIDE_POST_FAILED' });
    }
  },
);

// Restore a post by clearing all actioned moderation reports for that post.
moderationRouter.post(
  '/reports/:reportId/restore-post',
  async (request, response) => {
    const reportId = request.params.reportId;
    if (typeof reportId !== 'string' || !uuidSchema.safeParse(reportId).success) {
      response.status(400).json({ error: 'INVALID_REPORT_ID' });
      return;
    }

    const admin = response.locals.admin;

    try {
      const report = await prisma.postReport.findUnique({
        where: { id: reportId },
        select: { postId: true },
      });
      if (report == null) {
        response.status(404).json({ error: 'REPORT_NOT_FOUND' });
        return;
      }

      const result = await prisma.postReport.updateMany({
        where: {
          postId: report.postId,
          status: 'actioned',
        },
        data: {
          status: 'reviewed',
          handledById: admin.id,
          handledAt: new Date(),
        },
      });

      response.status(200).json({
        hidden: false,
        restoredReports: result.count,
      });
    } catch (error) {
      console.error('Admin restore post failed:', error);
      response.status(500).json({ error: 'ADMIN_RESTORE_POST_FAILED' });
    }
  },
);

// Permanently delete the reported post and best-effort delete its Storage media.
moderationRouter.delete(
  '/reports/:reportId/post',
  async (request, response) => {
    const reportId = request.params.reportId;
    if (typeof reportId !== 'string' || !uuidSchema.safeParse(reportId).success) {
      response.status(400).json({ error: 'INVALID_REPORT_ID' });
      return;
    }

    try {
      const report = await findReport(reportId);
      if (report == null) {
        response.status(404).json({ error: 'REPORT_NOT_FOUND' });
        return;
      }

      const imageUrls = report.post.images.map((image) => image.url);
      await prisma.post.delete({
        where: { id: report.post.id },
      });

      let deletedMedia = 0;
      try {
        const bucket = getFirebaseStorageBucket();
        for (const url of imageUrls) {
          const path = storagePathFromDownloadUrl(url);
          if (path == null) continue;
          try {
            await bucket.file(path).delete({ ignoreNotFound: true });
            deletedMedia += 1;
          } catch (error) {
            console.warn('Unable to delete moderated post media:', path, error);
          }
        }
      } catch (error) {
        console.warn('Storage cleanup unavailable after moderated post delete:', error);
      }

      response.status(200).json({
        deleted: true,
        postId: report.post.id,
        deletedMedia,
      });
    } catch (error) {
      console.error('Admin delete post failed:', error);
      response.status(500).json({ error: 'ADMIN_DELETE_POST_FAILED' });
    }
  },
);

// Disable the reported post's author at the identity provider and mark the
// legacy profile projection as banned. Existing refresh tokens are revoked.
moderationRouter.post(
  '/reports/:reportId/ban-author',
  async (request, response) => {
    const reportId = request.params.reportId;
    if (typeof reportId !== 'string' || !uuidSchema.safeParse(reportId).success) {
      response.status(400).json({ error: 'INVALID_REPORT_ID' });
      return;
    }

    const admin = response.locals.admin;

    try {
      const report = await findReport(reportId);
      if (report == null) {
        response.status(404).json({ error: 'REPORT_NOT_FOUND' });
        return;
      }

      const author = report.post.author;
      if (author == null) {
        response.status(409).json({ error: 'POST_AUTHOR_NOT_AVAILABLE' });
        return;
      }

      await firebaseAuth.updateUser(author.firebaseUid, { disabled: true });
      await firebaseAuth.revokeRefreshTokens(author.firebaseUid);
      await firebaseFirestore.collection('users').doc(author.firebaseUid).set(
        { banned: true },
        { merge: true },
      );

      await prisma.postReport.update({
        where: { id: reportId },
        data: {
          status: 'actioned',
          handledById: admin.id,
          handledAt: new Date(),
        },
      });

      response.status(200).json({
        banned: true,
        firebaseUid: author.firebaseUid,
        username: author.username,
      });
    } catch (error) {
      console.error('Admin ban author failed:', error);
      response.status(500).json({ error: 'ADMIN_BAN_AUTHOR_FAILED' });
    }
  },
);

moderationRouter.post(
  '/users/:firebaseUid/unban',
  async (request, response) => {
    const firebaseUid = request.params.firebaseUid;
    if (typeof firebaseUid !== 'string' || firebaseUid.trim().length === 0) {
      response.status(400).json({ error: 'INVALID_USER_ID' });
      return;
    }

    try {
      await firebaseAuth.updateUser(firebaseUid, { disabled: false });
      await firebaseFirestore.collection('users').doc(firebaseUid).set(
        { banned: false },
        { merge: true },
      );

      response.status(200).json({ banned: false, firebaseUid });
    } catch (error) {
      console.error('Admin unban user failed:', error);
      response.status(500).json({ error: 'ADMIN_UNBAN_USER_FAILED' });
    }
  },
);
