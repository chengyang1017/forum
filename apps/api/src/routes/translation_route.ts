import { Router } from 'express';
import { z } from 'zod';

import {
  requireAuth,
} from '../middleware/require_auth.js';

import {
  translatePostWithAi,
} from '../services/post_translation_service.js';

export const translationRouter =
  Router();

const optionalText = z.preprocess(
  (value) =>
    typeof value === 'string'
      ? value
      : '',
  z.string().trim(),
);

const requiredText = z.preprocess(
  (value) =>
    typeof value === 'string'
      ? value
      : '',
  z
    .string()
    .trim()
    .min(1),
);

const translatePostSchema = z.object({
  title: optionalText,

  content: requiredText,

  sourceLanguageCode:
    optionalText,

  targetLanguageCode:
    requiredText,

  targetLanguageName:
    optionalText,
});

// ============================================================
// POST /api/v1/translations/posts
//
// 将帖子内容翻译成目标语言。
// 必须使用 Firebase ID Token 登录。
// ============================================================

translationRouter.post(
  '/posts',
  requireAuth,
  async (request, response) => {
    const parsed =
      translatePostSchema.safeParse(
        request.body,
      );

    if (!parsed.success) {
      response.status(400).json({
        error: 'INVALID_REQUEST',
        message:
          'Translation parameters are incomplete',
        details:
          parsed.error.flatten(),
      });

      return;
    }

    try {
      const translated =
        await translatePostWithAi(
          parsed.data,
        );

      response.status(200).json(
        translated,
      );
    } catch (error) {
      console.error(
        'Translate post failed:',
        error,
      );

      response.status(500).json({
        error:
          'TRANSLATION_FAILED',
        message:
          'Unable to translate post',
      });
    }
  },
);