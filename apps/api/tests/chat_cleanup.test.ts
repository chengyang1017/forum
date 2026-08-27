import {
  describe,
  expect,
  it,
  vi,
} from 'vitest';

vi.mock(
  '../src/lib/firebase_admin.js',
  () => ({
    firebaseFirestore: {},
    getFirebaseStorageBucket:
      vi.fn(),
  }),
);

import {
  buildMessagePreview,
  getPathFromDownloadUrl,
  isHiddenForEveryone,
} from '../src/jobs/cleanup_expired_chat_messages.js';

describe(
  'chat cleanup helpers',
  () => {
    it(
      'decodes Firebase Storage download paths',
      () => {
        expect(
          getPathFromDownloadUrl(
            'https://firebasestorage.googleapis.com/v0/b/example/o/chats%2Fchat-1%2Fimage.jpg?alt=media',
          ),
        ).toBe(
          'chats/chat-1/image.jpg',
        );
      },
    );

    it(
      'returns null for invalid download URLs',
      () => {
        expect(
          getPathFromDownloadUrl(
            'not-a-url',
          ),
        ).toBeNull();
      },
    );

    it(
      'detects when every participant hides a message',
      () => {
        expect(
          isHiddenForEveryone(
            ['a', 'b'],
            ['a', 'b'],
          ),
        ).toBe(true);

        expect(
          isHiddenForEveryone(
            ['a', 'b'],
            ['a'],
          ),
        ).toBe(false);
      },
    );

    it(
      'builds deleted message previews',
      () => {
        expect(
          buildMessagePreview({
            status: 'deleted',
          }),
        ).toBe(
          '此消息已删除',
        );
      },
    );

    it(
      'builds image message previews',
      () => {
        expect(
          buildMessagePreview({
            imageUrl:
              'https://example.com/image.jpg',
          }),
        ).toBe(
          '[图片]',
        );
      },
    );

    it(
      'builds vocabulary message previews',
      () => {
        expect(
          buildMessagePreview({
            type: 'vocab',
            word: 'hello',
          }),
        ).toBe(
          '[单词] hello',
        );
      },
    );

    it(
      'builds text message previews',
      () => {
        expect(
          buildMessagePreview({
            content: 'hello',
          }),
        ).toBe(
          'hello',
        );
      },
    );
  },
);