#!/usr/bin/env python3
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / 'src' / 'routes'

HIDDEN_FILTER = "status: 'actioned'"


def replace_function(path: Path, next_marker: str, replacement: str) -> None:
    text = path.read_text(encoding='utf-8')

    # The generated patch may be evaluated more than once by GitHub Actions.
    # If this helper already contains the moderation filter, leave it alone.
    helper_match = re.search(
        rf"function postWhereById\([\s\S]*?\n}}\n\n(?={re.escape(next_marker)})",
        text,
    )
    if helper_match is None:
        raise RuntimeError(f'{path}: postWhereById helper not found')
    if HIDDEN_FILTER in helper_match.group(0):
        return

    text = text[: helper_match.start()] + replacement + text[helper_match.end() :]
    path.write_text(text, encoding='utf-8')


def replace_once_regex(
    path: Path,
    pattern: str,
    replacement: str,
    already_present: str,
) -> None:
    text = path.read_text(encoding='utf-8')
    if already_present in text:
        return

    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f'{path}: expected one patch location, found {count}')
    path.write_text(updated, encoding='utf-8')


post_route = ROOT / 'post_route.ts'
replace_function(
    post_route,
    'function prismaErrorCode',
    """function postWhereById(
  id: string,
): Prisma.PostWhereInput {
  const isDatabaseId =
    z.string().uuid().safeParse(id).success;

  const identity: Prisma.PostWhereInput =
    isDatabaseId
      ? {
          OR: [
            { firestoreId: id },
            { id },
          ],
        }
      : { firestoreId: id };

  return {
    AND: [
      identity,
      {
        reports: {
          none: { status: 'actioned' },
        },
      },
    ],
  };
}

""",
)
replace_once_regex(
    post_route,
    r"(const posts\s*=\s*await prisma\.post\.findMany\(\{\s*where:\s*\{\s*category,\s*versions:\s*\{\s*some:\s*\{\s*languageCode,\s*\},\s*\},)(\s*\},)",
    r"\1\n\n            reports: {\n              none: {\n                status: 'actioned',\n              },\n            },\2",
    "reports: {\n              none: {\n                status: 'actioned',",
)

post_data = ROOT / 'post_data_route.ts'
replace_function(
    post_data,
    'function serializePost',
    """function postWhereById(id: string): Prisma.PostWhereInput {
  const databaseId = z.string().uuid().safeParse(id);
  const identity: Prisma.PostWhereInput = databaseId.success
    ? {
        OR: [
          { firestoreId: id },
          { id },
        ],
      }
    : { firestoreId: id };

  return {
    AND: [
      identity,
      {
        reports: {
          none: { status: 'actioned' },
        },
      },
    ],
  };
}

""",
)
replace_once_regex(
    post_data,
    r"(const posts = await prisma\.post\.findMany\(\{\s*where:\s*\{\s*author:\s*\{\s*firebaseUid,\s*\},)(\s*\},)",
    r"\1\n          reports: {\n            none: { status: 'actioned' },\n          },\2",
    "author: {\n            firebaseUid,\n          },\n          reports:",
)

bookmark = ROOT / 'bookmark_route.ts'
replace_function(
    bookmark,
    'async function findCurrentUser',
    """function postWhereById(
  id: string,
): Prisma.PostWhereInput {
  const isDatabaseId =
    z.string()
      .uuid()
      .safeParse(id)
      .success;

  const identity: Prisma.PostWhereInput =
    isDatabaseId
      ? {
          OR: [
            { id },
            { firestoreId: id },
          ],
        }
      : { firestoreId: id };

  return {
    AND: [
      identity,
      {
        reports: {
          none: { status: 'actioned' },
        },
      },
    ],
  };
}

""",
)
replace_once_regex(
    bookmark,
    r"(const bookmarks\s*=\s*await prisma\.postBookmark\.findMany\(\{\s*where:\s*\{\s*userId: user\.id,)(\s*\},\s*orderBy:)",
    r"\1\n            post: {\n              reports: {\n                none: { status: 'actioned' },\n              },\n            },\2",
    "const bookmarks =\n        await prisma.postBookmark.findMany({\n          where: {\n            userId: user.id,\n            post:",
)

print('Moderation visibility filters patched.')
