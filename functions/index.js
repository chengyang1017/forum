const {
  setGlobalOptions,
} = require("firebase-functions/v2");

const {
  onSchedule,
} = require("firebase-functions/v2/scheduler");

const logger = require("firebase-functions/logger");

const {
  initializeApp,
} = require("firebase-admin/app");

const {
  getFirestore,
  FieldValue,
  Timestamp,
} = require("firebase-admin/firestore");

const {
  getStorage,
} = require("firebase-admin/storage");

initializeApp();

setGlobalOptions({
  maxInstances: 10,
});

const CLEANUP_BATCH_SIZE = 200;

/**
 * 从 Firebase Storage 下载地址解析文件路径。
 *
 * @param {string|null|undefined} downloadUrl 下载地址
 * @return {string|null} Storage 文件路径
 */
function getPathFromDownloadUrl(downloadUrl) {
  if (
    typeof downloadUrl !== "string" ||
    downloadUrl.trim().length === 0
  ) {
    return null;
  }

  try {
    const url = new URL(downloadUrl);
    const marker = "/o/";

    const markerIndex =
      url.pathname.indexOf(marker);

    if (markerIndex === -1) {
      return null;
    }

    const encodedPath =
      url.pathname.substring(
          markerIndex + marker.length,
      );

    return decodeURIComponent(encodedPath);
  } catch (error) {
    logger.warn(
        "无法从下载地址解析 Storage 路径",
        {
          downloadUrl,
          error: error.message,
        },
    );

    return null;
  }
}

/**
 * 判断消息是否已经被全部聊天室成员隐藏。
 *
 * @param {Array<string>} participants 聊天成员
 * @param {Array<string>} hiddenFor 已隐藏消息的成员
 * @return {boolean} 是否所有成员都已隐藏
 */
function isHiddenForEveryone(
    participants,
    hiddenFor,
) {
  return participants.length > 0 &&
    participants.every(
        (userId) => hiddenFor.includes(userId),
    );
}

/**
 * 生成聊天列表中的消息预览。
 *
 * @param {Object} message 消息数据
 * @return {string} 消息预览
 */
function buildMessagePreview(message) {
  const status =
    typeof message.status === "string" ?
      message.status :
      "active";

  if (status === "deleted") {
    return "此消息已删除";
  }

  const imageUrl =
    typeof message.imageUrl === "string" ?
      message.imageUrl.trim() :
      "";

  if (imageUrl.length > 0) {
    return "[图片]";
  }

  if (message.type === "vocab") {
    const word =
      typeof message.word === "string" ?
        message.word.trim() :
        "";

    return word.length > 0 ?
      `[单词] ${word}` :
      "[单词]";
  }

  const content =
    typeof message.content === "string" ?
      message.content.trim() :
      "";

  return content.length > 0 ?
    content :
    "[消息]";
}

/**
 * 删除消息所关联的 Storage 图片。
 *
 * @param {Object} message 消息数据
 * @param {Object} bucket Storage Bucket
 * @return {Promise<boolean>} 是否删除成功
 */
async function deleteMessageImage(
    message,
    bucket,
) {
  const imagePath =
    message.imagePath ||
    getPathFromDownloadUrl(
        message.imageUrl,
    );

  if (
    typeof imagePath !== "string" ||
    imagePath.trim().length === 0
  ) {
    return true;
  }

  try {
    await bucket
        .file(imagePath)
        .delete();

    logger.info(
        "聊天图片已清理",
        {
          imagePath,
        },
    );

    return true;
  } catch (error) {
    if (error.code === 404) {
      return true;
    }

    logger.error(
        "聊天图片清理失败",
        {
          imagePath,
          error: error.message,
        },
    );

    return false;
  }
}

/**
 * 消息物理删除后刷新聊天室预览。
 *
 * 只有被删除的消息正好是聊天室最后一条消息时，
 * 才需要重新寻找上一条有效消息。
 *
 * @param {Object} chatReference 聊天室文档引用
 * @param {string} deletedMessageId 已删除消息 ID
 * @return {Promise<void>}
 */
async function refreshChatPreviewAfterDeletion(
    chatReference,
    deletedMessageId,
) {
  const chatSnapshot =
    await chatReference.get();

  const chat = chatSnapshot.data();

  if (chat === undefined) {
    return;
  }

  if (chat.lastMessageId !== deletedMessageId) {
    return;
  }

  const participants =
    Array.isArray(chat.users) ?
      chat.users :
      [];

  const messagesSnapshot =
    await chatReference
        .collection("messages")
        .orderBy(
            "timestamp",
            "desc",
        )
        .limit(50)
        .get();

  let latestVisibleDocument = null;

  for (const document of messagesSnapshot.docs) {
    const message = document.data();

    const hiddenFor =
      Array.isArray(message.hiddenFor) ?
        message.hiddenFor :
        [];

    const hiddenForEveryone =
      isHiddenForEveryone(
          participants,
          hiddenFor,
      );

    if (hiddenForEveryone) {
      continue;
    }

    latestVisibleDocument = document;
    break;
  }

  if (latestVisibleDocument === null) {
    await chatReference.update({
      lastMessage: "",
      lastMessageId: null,
      lastSenderId: null,
      updatedAt:
        FieldValue.serverTimestamp(),
    });

    return;
  }

  const latestMessage =
    latestVisibleDocument.data();

  await chatReference.update({
    lastMessage:
      buildMessagePreview(latestMessage),

    lastMessageId:
      latestVisibleDocument.id,

    lastSenderId:
      latestMessage.senderId || null,

    updatedAt:
      latestMessage.timestamp ||
      FieldValue.serverTimestamp(),
  });
}

/**
 * 每小时清理已经到期的聊天消息。
 */
exports.cleanupExpiredChatMessages =
  onSchedule(
      {
        schedule: "every 60 minutes",
        timeZone: "Asia/Kuala_Lumpur",
        region: "asia-southeast1",
        maxInstances: 1,
        timeoutSeconds: 540,
      },
      async () => {
        const firestore =
          getFirestore();

        const bucket =
          getStorage().bucket();

        const now =
          Timestamp.now();

        let deletedCount = 0;
        let skippedCount = 0;
        let invalidCount = 0;

        /*
         * 每次最多处理 200 条。
         *
         * 不使用无限 while 循环，避免某张图片一直删除失败时，
         * 同一批消息被反复查询直到函数超时。
         * 未完成的消息会在下一小时继续处理。
         */
        const cleanupSnapshot =
          await firestore
              .collectionGroup("messages")
              .where(
                  "cleanupAt",
                  "<=",
                  now,
              )
              .orderBy("cleanupAt")
              .limit(CLEANUP_BATCH_SIZE)
              .get();

        for (
          const messageDocument
          of cleanupSnapshot.docs
        ) {
          const message =
            messageDocument.data();

          const chatReference =
            messageDocument.ref.parent.parent;

          /*
           * collectionGroup("messages") 可能找到其他位置
           * 同名的 messages 子集合。
           */
          if (
            chatReference === null ||
            chatReference.parent.id !== "chats"
          ) {
            logger.warn(
                "跳过非聊天消息文档",
                {
                  messagePath:
                    messageDocument.ref.path,
                },
            );

            skippedCount++;
            continue;
          }

          const chatSnapshot =
            await chatReference.get();

          const chat =
            chatSnapshot.data();

          /*
           * 聊天室父文档已经不存在时，
           * 消息属于孤儿数据，可以直接清理。
           */
          if (chat === undefined) {
            const imageDeleted =
              await deleteMessageImage(
                  message,
                  bucket,
              );

            if (!imageDeleted) {
              skippedCount++;
              continue;
            }

            await messageDocument.ref.delete();

            deletedCount++;
            continue;
          }

          const participants =
            Array.isArray(chat.users) ?
              chat.users :
              [];

          const hiddenFor =
            Array.isArray(message.hiddenFor) ?
              message.hiddenFor :
              [];

          const status =
            typeof message.status === "string" ?
              message.status :
              "active";

          const hiddenForEveryone =
            isHiddenForEveryone(
                participants,
                hiddenFor,
            );

          const canPhysicallyDelete =
            status === "deleted" ||
            hiddenForEveryone;

          /*
           * 防止异常客户端给正常消息伪造 cleanupAt。
           */
          if (!canPhysicallyDelete) {
            logger.warn(
                "消息不符合物理删除条件",
                {
                  messagePath:
                    messageDocument.ref.path,
                  status,
                  participants,
                  hiddenFor,
                },
            );

            await messageDocument.ref.update({
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

          await messageDocument.ref.delete();

          await refreshChatPreviewAfterDeletion(
              chatReference,
              deletedMessageId,
          );

          deletedCount++;

          logger.info(
              "聊天消息已物理删除",
              {
                messagePath:
                  messageDocument.ref.path,
              },
          );
        }

        logger.info(
            "聊天消息定时清理完成",
            {
              queriedCount:
                cleanupSnapshot.size,

              deletedCount,
              skippedCount,
              invalidCount,

              hasMore:
                cleanupSnapshot.size ===
                CLEANUP_BATCH_SIZE,

              executedAt:
                now
                    .toDate()
                    .toISOString(),
            },
        );
      },
  );
