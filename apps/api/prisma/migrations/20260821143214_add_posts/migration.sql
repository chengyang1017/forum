-- CreateTable
CREATE TABLE "posts" (
    "id" UUID NOT NULL,
    "firestoreId" VARCHAR(128),
    "authorId" UUID NOT NULL,
    "category" VARCHAR(100),
    "primaryLanguageCode" VARCHAR(32) NOT NULL,
    "likeCount" INTEGER NOT NULL DEFAULT 0,
    "commentCount" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "posts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "post_versions" (
    "id" UUID NOT NULL,
    "postId" UUID NOT NULL,
    "languageCode" VARCHAR(32) NOT NULL,
    "title" TEXT NOT NULL DEFAULT '',
    "content" TEXT NOT NULL DEFAULT '',
    "bodyDelta" JSONB NOT NULL,
    "type" VARCHAR(32) NOT NULL DEFAULT 'original',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "post_versions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "post_images" (
    "id" UUID NOT NULL,
    "postId" UUID NOT NULL,
    "url" TEXT NOT NULL,
    "position" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "post_images_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "posts_firestoreId_key" ON "posts"("firestoreId");

-- CreateIndex
CREATE INDEX "posts_authorId_idx" ON "posts"("authorId");

-- CreateIndex
CREATE INDEX "posts_category_createdAt_idx" ON "posts"("category", "createdAt");

-- CreateIndex
CREATE INDEX "posts_primaryLanguageCode_createdAt_idx" ON "posts"("primaryLanguageCode", "createdAt");

-- CreateIndex
CREATE INDEX "post_versions_languageCode_idx" ON "post_versions"("languageCode");

-- CreateIndex
CREATE UNIQUE INDEX "post_versions_postId_languageCode_key" ON "post_versions"("postId", "languageCode");

-- CreateIndex
CREATE INDEX "post_images_postId_idx" ON "post_images"("postId");

-- CreateIndex
CREATE UNIQUE INDEX "post_images_postId_position_key" ON "post_images"("postId", "position");

-- AddForeignKey
ALTER TABLE "posts" ADD CONSTRAINT "posts_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_versions" ADD CONSTRAINT "post_versions_postId_fkey" FOREIGN KEY ("postId") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_images" ADD CONSTRAINT "post_images_postId_fkey" FOREIGN KEY ("postId") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;
