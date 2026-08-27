const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  defineSecret,
} = require("firebase-functions/params");

const {
  OpenAI,
} = require("openai");

const openaiApiKey =
  defineSecret("OPENAI_API_KEY");

const translatePost = onCall(
    {
      region: "asia-southeast1",
      secrets: [openaiApiKey],
      timeoutSeconds: 60,
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "请先登录",
        );
      }

      const data = request.data || {};

      const title =
        typeof data.title === "string" ?
          data.title.trim() :
          "";

      const content =
        typeof data.content === "string" ?
          data.content.trim() :
          "";

      const sourceLanguageCode =
        typeof data.sourceLanguageCode === "string" ?
          data.sourceLanguageCode.trim() :
          "";

      const targetLanguageCode =
        typeof data.targetLanguageCode === "string" ?
          data.targetLanguageCode.trim() :
          "";

      const targetLanguageName =
        typeof data.targetLanguageName === "string" ?
          data.targetLanguageName.trim() :
          "";

      if (
        content.length === 0 ||
        targetLanguageCode.length === 0
      ) {
        throw new HttpsError(
            "invalid-argument",
            "翻译参数不完整",
        );
      }

      try {
        const openai = new OpenAI({
          apiKey: openaiApiKey.value(),
        });

        const response =
          await openai.responses.create({
            model: "gpt-5-mini",

            store: false,

            instructions: [
              "You are a professional translation engine",
              "for a multilingual social platform.",
              "",
              "Translate the supplied post into",
              "the requested target language.",
              "",
              "Requirements:",
              "- Preserve the original meaning and tone.",
              "- Write naturally for native speakers.",
              "- Do not summarize.",
              "- Do not add explanations.",
              "- Do not add new information.",
              "- Preserve URLs, usernames, mentions,",
              "  hashtags, emojis, numbers, and formatting.",
              "- If the title is empty,",
              "  return an empty title.",
            ].join("\n"),

            input: JSON.stringify({
              sourceLanguageCode,
              targetLanguageCode,
              targetLanguageName,
              title,
              content,
            }),

            text: {
              format: {
                type: "json_schema",
                name: "post_translation",
                strict: true,
                schema: {
                  type: "object",
                  properties: {
                    title: {
                      type: "string",
                    },
                    content: {
                      type: "string",
                    },
                  },
                  required: [
                    "title",
                    "content",
                  ],
                  additionalProperties: false,
                },
              },
            },
          });

        const output =
          response.output_text.trim();

        if (output.length === 0) {
          throw new Error(
              "OpenAI returned empty output",
          );
        }

        const translated =
          JSON.parse(output);

        return {
          title:
            typeof translated.title === "string" ?
              translated.title :
              "",

          content:
            typeof translated.content === "string" ?
              translated.content :
              "",
        };
      } catch (error) {
        console.error(
            "translatePost failed",
            error,
        );

        throw new HttpsError(
            "internal",
            "AI 翻译失败",
        );
      }
    },
);

module.exports = {
  translatePost,
};
