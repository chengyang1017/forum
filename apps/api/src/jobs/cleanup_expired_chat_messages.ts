import {
  FieldValue,
  Timestamp,
} from 'firebase-admin/firestore';

import type {
  DocumentReference,
} from 'firebase-admin/firestore';

import {
  firebaseFirestore,
  getFirebaseStorageBucket,
} from '../lib/firebase_admin.js';

const CLEANUP_BATCH_SIZE = 200;

type MessageData =
  Record<string, unknown>;

function toStringArray(
  value: unknown,
): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value.filter(
    (item): item is string =>
      typeof item === 'string',
  );
}

function errorMessage(
  error: unknown,
): string {
  return error instanceof Error
    ? error.message
    : String(error);
}

function isStorageNotFoundError(
  error: unknown,
): boolean {
  if (
    typeof error !== 'object' ||
    error == null
  ) {
    return false;
  }

  const code =
    (error as {
      code?: unknown;
    }).code;

  return code === 404 ||
    code === '404';
}

export function getPathFromDownloadUrl(
  downloadUrl: unknown,
): string | null {
  if (
    typeof downloadUrl !== 'string' ||
    downloadUrl.trim().length === 0
  ) {
    return null;
  }

  try {
    const url =
      new URL(downloadUrl);

    const marker = '/o/';

    const markerIndex =
      url.pathname.indexOf(marker);

    if (markerIndex === -1) {
      return null;
    }

    const encodedPath =
      url.pathname.substring(
        markerIndex +
          marker.length,
      );

    return decodeURIComponent(
      encodedPath,
    );
  } catch {
    return null;
  }
}

export function isHiddenForEveryone(
  participants: string[],
  hiddenFor: string[],
): boolean {
  return participants.length > 0 &&
    participants.every(
      (userId) =>
        hiddenFor.includes(userId),
    );
}

export function buildMessagePreview(
  message: MessageData,
): string {
  const status =
    typeof message.status === 'string'
      ? message.status
      : 'active';

  if (status === 'deleted') {
    return '此消息已删除';
  }

  const imageUrl =
    typeof message.imageUrl === 'string'
      ? message.imageUrl.trim()
      : '';

  if (imageUrl.length > 0) {
    return '[图片]';
  }

  if (message.type === 'vocab') {
    const word =
      typeof message.word === 'string'
        ? message.word.trim()
        : '';

    return word.length > 0
      ? `[单词] ${word}`
      : '[单词]';
  }

  const content =
    typeof message.content === 'string'
      ? message.content.trim()
      : '';

  return content.length > 0
    ? content
    : '[消息]';
}

async function deleteMessageImage(
  message: MessageData,
  bucket:
    ReturnType<
      typeof getFirebaseStorageBucket
    >,
): Promise<boolean> {
  const explicitImagePath =
    typeof message.imagePath === 'string'
      ? message.imagePath.trim()
      : '';

  const imagePath =
    explicitImagePath.length > 0
      ? explicitImagePath
      : getPathFromDownloadUrl(
          message.imageUrl,
        );

  if (!imagePath) {
    return true;
  }

  try {
    await bucket
      .file(imagePath)
      .delete();

    console.info(
      'Chat image cleaned:',
      imagePath,
    );

    return true;
  } catch (error) {
    if (
      isStorageNotFoundError(
        error,
      )
    ) {
      return true;
    }

    console.error(
      'Chat image cleanup failed:',
      {
        imagePath,
        error:
          errorMessage(error),
      },
    );

    return false;
  }
}

async function refreshChatPreviewAfterDeletion(
  chatReference:
    DocumentReference,
  deletedMessageId: string,
): Promise<void> {
  const chatSnapshot =
    await chatReference.get();

  const chat =
    chatSnapshot.data();

  if (chat == null) {
    return;
  }

  if (
    chat.lastMessageId !==
    deletedMessageId
  ) {
    return;
  }

  const participants =
    toStringArray(chat.users);

  const messagesSnapshot =
    await chatReference
      .collection('messages')
      .orderBy(
        'timestamp',
        'desc',
      )
      .limit(50)
      .get();

  let latestVisibleDocument:
    typeof messagesSnapshot.docs[number] |
    null = null;

  for (
    const document
    of messagesSnapshot.docs
  ) {
    const message =
      document.data() as MessageData;

    const hiddenFor =
      toStringArray(
        message.hiddenFor,
      );

    if (
      isHiddenForEveryone(
        participants,
        hiddenFor,
      )
    ) {
      continue;
    }

    latestVisibleDocument =
      document;

    break;
  }

  if (
    latestVisibleDocument == null
  ) {
    await chatReference.update({
      lastMessage: '',
      lastMessageId: null,
      lastSenderId: null,
      updatedAt:
        FieldValue
          .serverTimestamp(),
    });

    return;
  }

  const latestMessage =
    latestVisibleDocument
      .data() as MessageData;

  await chatReference.update({
    lastMessage:
      buildMessagePreview(
        latestMessage,
      ),

    lastMessageId:
      latestVisibleDocument.id,

    lastSenderId:
      typeof latestMessage
        .senderId === 'string'
        ? latestMessage.senderId
        : null,

    updatedAt:
      latestMessage.timestamp ??
      FieldValue.serverTimestamp(),
  });
}

export type ChatCleanupResult = {
  queriedCount: number;
  deletedCount: number;
  skippedCount: number;
  invalidCount: number;
  hasMore: boolean;
};

export async function
cleanupExpiredChatMessages():
Promise<ChatCleanupResult> {
  const bucket =
    getFirebaseStorageBucket();

  const now =
    Timestamp.now();

  let deletedCount = 0;
  let skippedCount = 0;
  let invalidCount = 0;

  const cleanupSnapshot =
    await firebaseFirestore
      .collectionGroup('messages')
      .where(
        'cleanupAt',
        '<=',
        now,
      )
      .orderBy('cleanupAt')
      .limit(CLEANUP_BATCH_SIZE)
      .get();

  for (
    const messageDocument
    of cleanupSnapshot.docs
  ) {
    const message =
      messageDocument
        .data() as MessageData;

    const chatReference =
      messageDocument
        .ref
        .parent
        .parent;

    if (
      chatReference == null ||
      chatReference.parent.id !==
        'chats'
    ) {
      console.warn(
        'Skip non-chat message:',
        messageDocument.ref.path,
      );

      skippedCount++;
      continue;
    }

    const chatSnapshot =
      await chatReference.get();

    const chat =
      chatSnapshot.data();

    if (chat == null) {
      const imageDeleted =
        await deleteMessageImage(
          message,
          bucket,
        );

      if (!imageDeleted) {
        skippedCount++;
        continue;
      }

      await messageDocument
        .ref
        .delete();

      deletedCount++;
      continue;
    }

    const participants =
      toStringArray(
        chat.users,
      );

    const hiddenFor =
      toStringArray(
        message.hiddenFor,
      );

    const status =
      typeof message.status ===
      'string'
        ? message.status
        : 'active';

    const hiddenForEveryone =
      isHiddenForEveryone(
        participants,
        hiddenFor,
      );

    const canPhysicallyDelete =
      status === 'deleted' ||
      hiddenForEveryone;

    if (!canPhysicallyDelete) {
      console.warn(
        'Message does not satisfy cleanup conditions:',
        messageDocument.ref.path,
      );

      await messageDocument
        .ref
        .update({
          cleanupAt:
            FieldValue.delete(),
        });

      invalidCount++;
      continue;
    }

    const imageDeleted =
      await deleteMessageImage(
        message,
        bucket,
      );

    if (!imageDeleted) {
      skippedCount++;
      continue;
    }

    const deletedMessageId =
      messageDocument.id;

    await messageDocument
      .ref
      .delete();

    await refreshChatPreviewAfterDeletion(
      chatReference,
      deletedMessageId,
    );

    deletedCount++;

    console.info(
      'Chat message physically deleted:',
      messageDocument.ref.path,
    );
  }

  return {
    queriedCount:
      cleanupSnapshot.size,

    deletedCount,
    skippedCount,
    invalidCount,

    hasMore:
      cleanupSnapshot.size ===
      CLEANUP_BATCH_SIZE,
  };
}