import express from 'express';
import request from 'supertest';
import {
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from 'vitest';

const mocks = vi.hoisted(() => ({
  verifyIdToken: vi.fn(),
  findUser: vi.fn(),
  groupReports: vi.fn(),
}));

vi.mock(
  '../src/lib/firebase_admin.js',
  () => ({
    firebaseAuth: {
      verifyIdToken:
        mocks.verifyIdToken,
    },
  }),
);

vi.mock(
  '../src/lib/prisma.js',
  () => ({
    prisma: {
      user: {
        findUnique:
          mocks.findUser,
      },

      postReport: {
        groupBy:
          mocks.groupReports,

        findMany:
          vi.fn(),

        findUnique:
          vi.fn(),

        update:
          vi.fn(),
      },
    },
  }),
);

import {
  adminRouter,
} from '../src/routes/admin_route.js';

function createTestApp() {
  const app = express();

  app.use(express.json());

  app.use(
    '/api/v1/admin',
    adminRouter,
  );

  return app;
}

describe(
  'admin routes',
  () => {
    beforeEach(() => {
      vi.clearAllMocks();

      mocks.verifyIdToken
        .mockResolvedValue({
          uid:
            'firebase-admin',

          email:
            'admin@example.com',
        });

      mocks.findUser
        .mockResolvedValue({
          id:
            'database-admin',

          firebaseUid:
            'firebase-admin',

          role:
            'admin',
        });
    });

    it(
      'rejects unauthenticated requests',
      async () => {
        const response =
          await request(
            createTestApp(),
          )
            .get(
              '/api/v1/admin/dashboard',
            );

        expect(
          response.status,
        ).toBe(401);

        expect(
          response.body.error,
        ).toBe(
          'UNAUTHORIZED',
        );
      },
    );

    it(
      'rejects authenticated non-admin users',
      async () => {
        mocks.findUser
          .mockResolvedValue({
            id:
              'database-user',

            firebaseUid:
              'firebase-user',

            role:
              'user',
          });

        const response =
          await request(
            createTestApp(),
          )
            .get(
              '/api/v1/admin/dashboard',
            )
            .set(
              'Authorization',
              'Bearer valid-token',
            );

        expect(
          response.status,
        ).toBe(403);

        expect(
          response.body.error,
        ).toBe(
          'ADMIN_REQUIRED',
        );
      },
    );

    it(
      'returns report statistics for admins',
      async () => {
        mocks.groupReports
          .mockResolvedValue([
            {
              status:
                'pending',

              _count: {
                _all: 3,
              },
            },
            {
              status:
                'reviewed',

              _count: {
                _all: 2,
              },
            },
            {
              status:
                'dismissed',

              _count: {
                _all: 1,
              },
            },
            {
              status:
                'actioned',

              _count: {
                _all: 4,
              },
            },
          ]);

        const response =
          await request(
            createTestApp(),
          )
            .get(
              '/api/v1/admin/dashboard',
            )
            .set(
              'Authorization',
              'Bearer valid-token',
            );

        expect(
          response.status,
        ).toBe(200);

        expect(
          response.body,
        ).toEqual({
          reports: {
            total: 10,
            pending: 3,
            reviewed: 2,
            dismissed: 1,
            actioned: 4,
          },
        });
      },
    );
  },
);
