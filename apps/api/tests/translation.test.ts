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
  translatePostWithAi: vi.fn(),
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
  '../src/services/post_translation_service.js',
  () => ({
    translatePostWithAi:
      mocks.translatePostWithAi,
  }),
);

import {
  translationRouter,
} from '../src/routes/translation_route.js';

function createTestApp() {
  const app = express();

  app.use(express.json());

  app.use(
    '/api/v1/translations',
    translationRouter,
  );

  return app;
}

describe(
  'translation routes',
  () => {
    beforeEach(() => {
      vi.clearAllMocks();

      mocks.verifyIdToken
        .mockResolvedValue({
          uid: 'firebase-user',
          email: 'user@example.com',
        });

      mocks.translatePostWithAi
        .mockResolvedValue({
          title: 'Xin chào',
          content: 'Nội dung đã dịch',
        });
    });

    it(
      'rejects unauthenticated requests',
      async () => {
        const response =
          await request(
            createTestApp(),
          )
            .post(
              '/api/v1/translations/posts',
            )
            .send({
              content: 'Hello',
              targetLanguageCode: 'vi',
            });

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
      'rejects incomplete translation input',
      async () => {
        const response =
          await request(
            createTestApp(),
          )
            .post(
              '/api/v1/translations/posts',
            )
            .set(
              'Authorization',
              'Bearer valid-token',
            )
            .send({
              title: 'Hello',
            });

        expect(
          response.status,
        ).toBe(400);

        expect(
          response.body.error,
        ).toBe(
          'INVALID_REQUEST',
        );
      },
    );

    it(
      'returns translated post data',
      async () => {
        const response =
          await request(
            createTestApp(),
          )
            .post(
              '/api/v1/translations/posts',
            )
            .set(
              'Authorization',
              'Bearer valid-token',
            )
            .send({
              title: ' Hello ',
              content: ' World ',
              sourceLanguageCode: ' en ',
              targetLanguageCode: ' vi ',
              targetLanguageName:
                ' Vietnamese ',
            });

        expect(
          response.status,
        ).toBe(200);

        expect(
          response.body,
        ).toEqual({
          title: 'Xin chào',
          content: 'Nội dung đã dịch',
        });

        expect(
          mocks.translatePostWithAi,
        ).toHaveBeenCalledWith({
          title: 'Hello',
          content: 'World',
          sourceLanguageCode: 'en',
          targetLanguageCode: 'vi',
          targetLanguageName:
            'Vietnamese',
        });
      },
    );

    it(
      'returns 500 when translation fails',
      async () => {
        mocks.translatePostWithAi
          .mockRejectedValue(
            new Error(
              'OpenAI failure',
            ),
          );

        const response =
          await request(
            createTestApp(),
          )
            .post(
              '/api/v1/translations/posts',
            )
            .set(
              'Authorization',
              'Bearer valid-token',
            )
            .send({
              content: 'Hello',
              targetLanguageCode: 'vi',
            });

        expect(
          response.status,
        ).toBe(500);

        expect(
          response.body.error,
        ).toBe(
          'TRANSLATION_FAILED',
        );
      },
    );
  },
);