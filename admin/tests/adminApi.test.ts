import {
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from 'vitest';

const mocks = vi.hoisted(() => ({
  get: vi.fn(),
}));

vi.mock(
  '../src/api/http',
  () => ({
    http: {
      get:
        mocks.get,

      patch:
        vi.fn(),
    },
  }),
);

import {
  getAdminDashboard,
  getAdminMe,
} from '../src/api/adminApi';

describe(
  'admin API',
  () => {
    beforeEach(() => {
      vi.clearAllMocks();
    });

    it(
      'loads the current admin',
      async () => {
        const admin = {
          id:
            'database-admin',

          firebaseUid:
            'firebase-admin',

          role:
            'admin',
        };

        mocks.get
          .mockResolvedValue({
            data: {
              admin,
            },
          });

        await expect(
          getAdminMe(),
        ).resolves.toEqual(
          admin,
        );

        expect(
          mocks.get,
        ).toHaveBeenCalledWith(
          '/admin/me',
        );
      },
    );

    it(
      'loads dashboard statistics',
      async () => {
        const dashboard = {
          reports: {
            total: 8,
            pending: 3,
            reviewed: 2,
            dismissed: 1,
            actioned: 2,
          },
        };

        mocks.get
          .mockResolvedValue({
            data:
              dashboard,
          });

        await expect(
          getAdminDashboard(),
        ).resolves.toEqual(
          dashboard,
        );

        expect(
          mocks.get,
        ).toHaveBeenCalledWith(
          '/admin/dashboard',
        );
      },
    );
  },
);
