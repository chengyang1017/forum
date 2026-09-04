#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / 'src' / 'routes'


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding='utf-8')
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{path}: expected 1 match, found {count}')
    path.write_text(text.replace(old, new), encoding='utf-8')


post_route = ROOT / 'post_route.ts'
replace_once(
    post_route,
    """function postWhereById(\n  id: string,\n): Prisma.PostWhereInput {\n  const isDatabaseId =\n    z.string().uuid().safeParse(id).success;\n\n  if (isDatabaseId) {\n    return {\n      OR: [\n        {\n          firestoreId: id,\n        },\n        {\n          id,\n        },\n      ],\n    };\n  }\n\n  return {\n    firestoreId: id,\n  };\n}\n""",
    """function postWhereById(\n  id: string,\n): Prisma.PostWhereInput {\n  const isDatabaseId =\n    z.string().uuid().safeParse(id).success;\n\n  const identity: Prisma.PostWhereInput =\n    isDatabaseId\n      ? {\n          OR: [\n            { firestoreId: id },\n            { id },\n          ],\n        }\n      : { firestoreId: id };\n\n  return {\n    AND: [\n      identity,\n      {\n        reports: {\n          none: { status: 'actioned' },\n        },\n      },\n    ],\n  };\n}\n""",
)
replace_once(
    post_route,
    """          where: {\n            category,\n\n            versions: {\n              some: {\n                languageCode,\n              },\n            },\n          },\n""",
    """          where: {\n            category,\n\n            versions: {\n              some: {\n                languageCode,\n              },\n            },\n\n            reports: {\n              none: {\n                status: 'actioned',\n              },\n            },\n          },\n""",
)

post_data = ROOT / 'post_data_route.ts'
replace_once(
    post_data,
    """function postWhereById(id: string): Prisma.PostWhereInput {\n  const databaseId = z.string().uuid().safeParse(id);\n\n  if (databaseId.success) {\n    return {\n      OR: [\n        { firestoreId: id },\n        { id },\n      ],\n    };\n  }\n\n  return { firestoreId: id };\n}\n""",
    """function postWhereById(id: string): Prisma.PostWhereInput {\n  const databaseId = z.string().uuid().safeParse(id);\n  const identity: Prisma.PostWhereInput = databaseId.success\n    ? {\n        OR: [\n          { firestoreId: id },\n          { id },\n        ],\n      }\n    : { firestoreId: id };\n\n  return {\n    AND: [\n      identity,\n      {\n        reports: {\n          none: { status: 'actioned' },\n        },\n      },\n    ],\n  };\n}\n""",
)
replace_once(
    post_data,
    """        where: {\n          author: {\n            firebaseUid,\n          },\n        },\n""",
    """        where: {\n          author: {\n            firebaseUid,\n          },\n          reports: {\n            none: { status: 'actioned' },\n          },\n        },\n""",
)

bookmark = ROOT / 'bookmark_route.ts'
replace_once(
    bookmark,
    """function postWhereById(\n  id: string,\n): Prisma.PostWhereInput {\n  const isDatabaseId =\n    z.string()\n      .uuid()\n      .safeParse(id)\n      .success;\n\n  if (isDatabaseId) {\n    return {\n      OR: [\n        {\n          id,\n        },\n        {\n          firestoreId: id,\n        },\n      ],\n    };\n  }\n\n  return {\n    firestoreId: id,\n  };\n}\n""",
    """function postWhereById(\n  id: string,\n): Prisma.PostWhereInput {\n  const isDatabaseId =\n    z.string()\n      .uuid()\n      .safeParse(id)\n      .success;\n\n  const identity: Prisma.PostWhereInput =\n    isDatabaseId\n      ? {\n          OR: [\n            { id },\n            { firestoreId: id },\n          ],\n        }\n      : { firestoreId: id };\n\n  return {\n    AND: [\n      identity,\n      {\n        reports: {\n          none: { status: 'actioned' },\n        },\n      },\n    ],\n  };\n}\n""",
)
replace_once(
    bookmark,
    """          where: {\n            userId: user.id,\n          },\n""",
    """          where: {\n            userId: user.id,\n            post: {\n              reports: {\n                none: { status: 'actioned' },\n              },\n            },\n          },\n""",
)

report = ROOT / 'report_route.ts'
text = report.read_text(encoding='utf-8')
old = """function postWhereById(\n  id: string,\n): Prisma.PostWhereInput {"""
if old not in text:
    raise RuntimeError('report_route.ts: postWhereById not found')
# Keep the report endpoint able to locate a post until it is actioned. No patch
# is required here because once hidden, repeated public reports are harmless and
# existing moderation history must remain accessible.

print('Moderation visibility filters patched.')
