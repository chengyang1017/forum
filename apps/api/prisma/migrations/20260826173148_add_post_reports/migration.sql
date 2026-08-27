-- CreateTable
CREATE TABLE "post_reports" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "postId" UUID NOT NULL,
    "reason" VARCHAR(32) NOT NULL,
    "details" TEXT,
    "status" VARCHAR(32) NOT NULL DEFAULT 'pending',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "post_reports_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "post_reports_userId_createdAt_idx" ON "post_reports"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "post_reports_postId_createdAt_idx" ON "post_reports"("postId", "createdAt");

-- CreateIndex
CREATE INDEX "post_reports_status_createdAt_idx" ON "post_reports"("status", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "post_reports_userId_postId_key" ON "post_reports"("userId", "postId");

-- AddForeignKey
ALTER TABLE "post_reports" ADD CONSTRAINT "post_reports_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_reports" ADD CONSTRAINT "post_reports_postId_fkey" FOREIGN KEY ("postId") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;
