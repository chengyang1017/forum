CREATE TABLE "post_edit_history" (
    "id" UUID NOT NULL,
    "firestorePath" VARCHAR(512),
    "postId" UUID NOT NULL,
    "editedById" UUID,
    "languageCode" VARCHAR(32) NOT NULL,
    "type" VARCHAR(32) NOT NULL DEFAULT 'edit',
    "title" TEXT NOT NULL DEFAULT '',
    "content" TEXT NOT NULL DEFAULT '',
    "bodyDelta" JSONB NOT NULL,
    "imageUrls" JSONB NOT NULL,
    "editedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "post_edit_history_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "post_edit_history_firestorePath_key"
ON "post_edit_history"("firestorePath");

CREATE INDEX "post_edit_history_postId_languageCode_editedAt_idx"
ON "post_edit_history"("postId", "languageCode", "editedAt");

CREATE INDEX "post_edit_history_editedById_idx"
ON "post_edit_history"("editedById");

ALTER TABLE "post_edit_history"
ADD CONSTRAINT "post_edit_history_postId_fkey"
FOREIGN KEY ("postId") REFERENCES "posts"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "post_edit_history"
ADD CONSTRAINT "post_edit_history_editedById_fkey"
FOREIGN KEY ("editedById") REFERENCES "users"("id")
ON DELETE SET NULL ON UPDATE CASCADE;
