export type FirestoreTimestampLike = {
  toDate(): Date;
};

export type Post = {
  id: string;
  userId: string | null;
  username: string | null;
  nickname: string | null;
  title: string;
  content: string;
  category: string | null;
  languageCode: string | null;
  imageUrls: string[];
  likes: string[];
  likeCount: number;
  commentCount: number;
  createdAt: Date | null;
  updatedAt: Date | null;
};

function readString(value: unknown): string | null {
  return typeof value === 'string' ? value : null;
}

function readStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value.filter((item): item is string => typeof item === 'string');
}

function readInteger(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value)
    ? Math.trunc(value)
    : 0;
}

export function firestoreTimestampToDate(value: unknown): Date | null {
  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? null : value;
  }

  if (
    typeof value !== 'object' ||
    value === null ||
    !('toDate' in value) ||
    typeof value.toDate !== 'function'
  ) {
    return null;
  }

  try {
    const date = (value as FirestoreTimestampLike).toDate();
    return date instanceof Date && !Number.isNaN(date.getTime())
      ? date
      : null;
  } catch {
    return null;
  }
}

export function decodePost(
  id: string,
  data: Record<string, unknown>,
): Post {
  const likes = readStringArray(data.likes);
  const storedLikeCount = readInteger(data.likeCount);

  return {
    id,
    userId: readString(data.uid) ?? readString(data.userId),
    username: readString(data.username),
    nickname: readString(data.nickname),
    title: readString(data.title) ?? '',
    content: readString(data.content) ?? '',
    category: readString(data.category),
    languageCode: readString(data.languageCode),
    imageUrls: readStringArray(data.images),
    likes,
    likeCount: likes.length > 0 ? likes.length : storedLikeCount,
    commentCount: readInteger(data.commentCount),
    createdAt: firestoreTimestampToDate(
      data.timestamp ?? data.createdAt,
    ),
    updatedAt: firestoreTimestampToDate(data.updatedAt),
  };
}
