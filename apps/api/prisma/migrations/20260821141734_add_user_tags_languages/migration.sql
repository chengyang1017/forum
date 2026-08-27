-- CreateTable
CREATE TABLE "user_tags" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "value" VARCHAR(50) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_tags_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_languages" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "languageCode" VARCHAR(32) NOT NULL,
    "scriptCode" VARCHAR(32) NOT NULL DEFAULT '',
    "level" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_languages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "user_tags_value_idx" ON "user_tags"("value");

-- CreateIndex
CREATE UNIQUE INDEX "user_tags_userId_value_key" ON "user_tags"("userId", "value");

-- CreateIndex
CREATE INDEX "user_languages_languageCode_idx" ON "user_languages"("languageCode");

-- CreateIndex
CREATE UNIQUE INDEX "user_languages_userId_languageCode_scriptCode_key" ON "user_languages"("userId", "languageCode", "scriptCode");

-- AddForeignKey
ALTER TABLE "user_tags" ADD CONSTRAINT "user_tags_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_languages" ADD CONSTRAINT "user_languages_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
