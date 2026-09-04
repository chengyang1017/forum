import { Router } from 'express';
import { FieldValue } from 'firebase-admin/firestore';

import { firebaseAuth, firebaseFirestore } from '../lib/firebase_admin.js';
import { prisma } from '../lib/prisma.js';
import { requireAuth } from '../middleware/require_auth.js';

export const accountRouter = Router();

/**
 * DELETE /api/v1/account
 *
 * Deletes the authenticated Glyphora account across the authoritative
 * PostgreSQL user store, the legacy Firestore profile/social mirrors and
 * Firebase Authentication.
 *
 * The Firebase account is disabled first so a partial cleanup can never leave
 * an account active after its application data has started being removed.
 */
accountRouter.delete(
  '/',
  requireAuth,
  async (_request, response) => {
    const { firebaseUid } = response.locals.auth;

    let firebaseDisabled = false;

    try {
      const user = await prisma.user.findUnique({
        where: { firebaseUid },
        select: { id: true },
      });

      if (user == null) {
        response.status(404).json({
          error: 'USER_NOT_FOUND',
          message: 'Backend user does not exist',
        });
        return;
      }

      // Stop new sessions before destructive cleanup begins.
      await firebaseAuth.updateUser(firebaseUid, { disabled: true });
      firebaseDisabled = true;
      await firebaseAuth.revokeRefreshTokens(firebaseUid);

      await prisma.$transaction(async (transaction) => {
        // User.posts uses SetNull for historical migration compatibility, so
        // account deletion explicitly removes posts authored by this account.
        // Post children cascade from the Post relation.
        await transaction.post.deleteMany({
          where: { authorId: user.id },
        });

        // Likes, bookmarks, reports, tags and languages cascade from User.
        // Comments/translations on other people's posts are anonymised by the
        // existing SetNull relations instead of deleting the other user's
        // discussion/history.
        await transaction.user.delete({
          where: { id: user.id },
        });
      });

      await cleanupLegacyFirestoreUser(firebaseUid);

      await firebaseAuth.deleteUser(firebaseUid);

      response.status(200).json({ deleted: true });
    } catch (error) {
      console.error('Delete account failed:', error);

      // If the failure happened after disabling Firebase Auth, leave the
      // account disabled rather than silently re-enabling a partially deleted
      // identity. This is safer and gives operators a recoverable state.
      response.status(500).json({
        error: 'DELETE_ACCOUNT_FAILED',
        message: firebaseDisabled
          ? 'Account cleanup failed after sign-in was disabled'
          : 'Unable to delete account',
      });
    }
  },
);

async function cleanupLegacyFirestoreUser(firebaseUid: string) {
  const userRef = firebaseFirestore.collection('users').doc(firebaseUid);
  const friendsRef = firebaseFirestore.collection('friends').doc(firebaseUid);
  const blocksRef = firebaseFirestore.collection('blocks').doc(firebaseUid);

  const [sentRequests, receivedRequests, reverseFriends] = await Promise.all([
    firebaseFirestore
      .collection('friend_requests')
      .where('from', '==', firebaseUid)
      .get(),
    firebaseFirestore
      .collection('friend_requests')
      .where('to', '==', firebaseUid)
      .get(),
    firebaseFirestore
      .collection('friends')
      .where(firebaseUid, '==', true)
      .get(),
  ]);

  const batch = firebaseFirestore.batch();

  batch.delete(userRef);
  batch.delete(friendsRef);
  batch.delete(blocksRef);

  for (const doc of sentRequests.docs) {
    batch.delete(doc.ref);
  }

  for (const doc of receivedRequests.docs) {
    batch.delete(doc.ref);
  }

  for (const doc of reverseFriends.docs) {
    batch.update(doc.ref, {
      [firebaseUid]: FieldValue.delete(),
    });
  }

  await batch.commit();
}
