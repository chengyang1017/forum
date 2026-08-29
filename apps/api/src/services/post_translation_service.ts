import OpenAI from 'openai';
import { zodTextFormat } from 'openai/helpers/zod';
import { z } from 'zod';

export type PostTranslationInput = {
  title: string;
  content: string;
  sourceLanguageCode: string;
  targetLanguageCode: string;
  targetLanguageName: string;
};

const postTranslationOutputSchema = z.object({
  title: z.string(),
  content: z.string(),
});

let openaiClient: OpenAI | null = null;

function getOpenAiClient(): OpenAI {
  const apiKey =
    process.env.OPENAI_API_KEY?.trim();

  if (!apiKey) {
    throw new Error(
      'OPENAI_API_KEY is not configured',
    );
  }

  openaiClient ??= new OpenAI({
    apiKey,
    timeout: 60_000,
  });

  return openaiClient;
}

export async function translatePostWithAi(
  input: PostTranslationInput,
): Promise<{
  title: string;
  content: string;
}> {
  const openai = getOpenAiClient();

  const response =
    await openai.responses.parse({
      model: 'gpt-5-mini',

      store: false,

      instructions: [
        'You are a professional translation engine',
        'for a multilingual social platform.',
        '',
        'Translate the supplied post into',
        'the requested target language.',
        '',
        'Requirements:',
        '- Preserve the original meaning and tone.',
        '- Write naturally for native speakers.',
        '- Do not summarize.',
        '- Do not add explanations.',
        '- Do not add new information.',
        '- Preserve URLs, usernames, mentions,',
        '  hashtags, emojis, numbers, and formatting.',
        '- If the title is empty,',
        '  return an empty title.',
      ].join('\n'),

      input: JSON.stringify(input),

      text: {
        format: zodTextFormat(
          postTranslationOutputSchema,
          'post_translation',
        ),
      },
    });

  const translated =
    response.output_parsed;

  if (translated == null) {
    throw new Error(
      'OpenAI returned no parsed translation',
    );
  }

  return translated;
}