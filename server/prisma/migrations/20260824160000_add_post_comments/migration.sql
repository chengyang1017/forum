-- CreateTable
CREATE TABLE "post_comments" (
    "id" UUID NOT NULL,
    "firestorePath" VARCHAR(512),
    "postId" UUID NOT NULL,
    "authorId" UUID,
    "parentId" UUID,
    "authorName" VARCHAR(100) NOT NULL DEFAULT 'Guest',
    "text" TEXT NOT NULL DEFAULT '',
    "imageUrl" TEXT,
    "replyTo" VARCHAR(100),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "post_comments_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "post_comments_postId_parentId_createdAt_idx"
ON "post_comments"("postId", "parentId", "createdAt");

-- CreateIndex
CREATE INDEX "post_comments_authorId_idx"
ON "post_comments"("authorId");

-- CreateIndex
CREATE UNIQUE INDEX "post_comments_firestorePath_key"
ON "post_comments"("firestorePath");

-- AddForeignKey
ALTER TABLE "post_comments"
ADD CONSTRAINT "post_comments_postId_fkey"
FOREIGN KEY ("postId")
REFERENCES "posts"("id")
ON DELETE CASCADE
ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_comments"
ADD CONSTRAINT "post_comments_authorId_fkey"
FOREIGN KEY ("authorId")
REFERENCES "users"("id")
ON DELETE SET NULL
ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_comments"
ADD CONSTRAINT "post_comments_parentId_fkey"
FOREIGN KEY ("parentId")
REFERENCES "post_comments"("id")
ON DELETE CASCADE
ON UPDATE CASCADE;
