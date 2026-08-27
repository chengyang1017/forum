export type UserProfile = {
  id: string;
  uid: string;
  username: string;
  email: string | null;
  displayName: string | null;
  nickname: string | null;
  avatar: string | null;
  banned: boolean;
  role: string;
};

function readString(value: unknown): string | null {
  return typeof value === 'string' ? value : null;
}

export function decodeUserProfile(
  id: string,
  data: Record<string, unknown>,
): UserProfile {
  return {
    id,
    uid: readString(data.uid) ?? id,
    username: readString(data.username) ?? '',
    email: readString(data.email),
    displayName: readString(data.displayName),
    nickname: readString(data.nickname),
    avatar:
      readString(data.avatar) ??
      readString(data.avatarUrl) ??
      readString(data.photoUrl),
    banned: data.banned === true,
    role: readString(data.role) ?? 'user',
  };
}
