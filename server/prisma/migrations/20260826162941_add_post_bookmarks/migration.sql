-- CreateTable
CREATE TABLE "post_bookmarks" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "postId" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "post_bookmarks_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "post_bookmarks_userId_createdAt_idx" ON "post_bookmarks"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "post_bookmarks_postId_idx" ON "post_bookmarks"("postId");

-- CreateIndex
CREATE UNIQUE INDEX "post_bookmarks_userId_postId_key" ON "post_bookmarks"("userId", "postId");

-- AddForeignKey
ALTER TABLE "post_bookmarks" ADD CONSTRAINT "post_bookmarks_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_bookmarks" ADD CONSTRAINT "post_bookmarks_postId_fkey" FOREIGN KEY ("postId") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;
