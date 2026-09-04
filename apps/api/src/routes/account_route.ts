import { Router } from 'express';
import { FieldValue } from 'firebase-admin/firestore';

import {
  firebaseAuth,
  firebaseFirestore,
  getFirebaseStorageBucket,
} from '../lib/firebase_admin.js';
import { prisma } from '../lib/prisma.js';
import { requireAuth } from '../middleware/require_auth.js';

export const accountRouter = Router();

/**
 * DELETE /api/v1/account
 *
 * Deletes the authenticated Glyphora account across the authoritative
 * PostgreSQL user store, the legacy Firestore profile/social mirrors,
 * Firebase Storage and Firebase Authentication.
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
        select: {
          id: true,
          avatarUrl: true,
          posts: {
            select: {
              images: {
                select: { url: true },
              },
            },
          },
        },
      });

      if (user == null) {
        response.status(404).json({
          error: 'USER_NOT_FOUND',
          message: 'Backend user does not exist',
        });
        return;
      }

      const mediaUrls = [
        ...(user.avatarUrl == null ? [] : [user.avatarUrl]),
        ...user.posts.flatMap((post) => post.images.map((image) => image.url)),
      ];

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
      await cleanupAccountStorage(mediaUrls);

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

  const [
    sentRequests,
    receivedRequests,
    reverseFriends,
    reverseBlocks,
    outgoingFollows,
    incomingFollows,
  ] = await Promise.all([
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
    firebaseFirestore
      .collection('blocks')
      .where(firebaseUid, '==', true)
      .get(),
    firebaseFirestore
      .collection('follows')
      .where('followerId', '==', firebaseUid)
      .get(),
    firebaseFirestore
      .collection('follows')
      .where('followingId', '==', firebaseUid)
      .get(),
  ]);

  // BulkWriter avoids the 500-write ceiling of one Firestore WriteBatch for
  // established accounts with a large social graph.
  const writer = firebaseFirestore.bulkWriter();

  writer.delete(userRef);
  writer.delete(friendsRef);
  writer.delete(blocksRef);

  for (const doc of sentRequests.docs) {
    writer.delete(doc.ref);
  }

  for (const doc of receivedRequests.docs) {
    writer.delete(doc.ref);
  }

  for (const doc of reverseFriends.docs) {
    writer.update(doc.ref, {
      [firebaseUid]: FieldValue.delete(),
    });
  }

  for (const doc of reverseBlocks.docs) {
    writer.update(doc.ref, {
      [firebaseUid]: FieldValue.delete(),
    });
  }

  const followDocs = new Map(
    [...outgoingFollows.docs, ...incomingFollows.docs].map((doc) => [
      doc.ref.path,
      doc,
    ]),
  );

  for (const doc of followDocs.values()) {
    writer.delete(doc.ref);
  }

  await writer.close();
}

async function cleanupAccountStorage(urls: string[]) {
  if (urls.length === 0) {
    return;
  }

  try {
    const bucket = getFirebaseStorageBucket();
    const paths = new Set(
      urls
        .map(storagePathFromDownloadUrl)
        .filter((path): path is string => path != null),
    );

    for (const path of paths) {
      try {
        await bucket.file(path).delete({ ignoreNotFound: true });
      } catch (error) {
        console.warn('Unable to delete account media:', path, error);
      }
    }
  } catch (error) {
    // Database/auth deletion must not fail because an old Storage bucket is
    // unavailable. Orphan-file cleanup remains best effort and observable.
    console.warn('Account Storage cleanup unavailable:', error);
  }
}

function storagePathFromDownloadUrl(downloadUrl: string): string | null {
  try {
    const url = new URL(downloadUrl);
    const marker = '/o/';
    const markerIndex = url.pathname.indexOf(marker);

    if (markerIndex === -1) {
      return null;
    }

    return decodeURIComponent(url.pathname.substring(markerIndex + marker.length));
  } catch {
    return null;
  }
}
