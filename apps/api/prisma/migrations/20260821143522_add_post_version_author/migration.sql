-- AlterTable
ALTER TABLE "post_versions" ADD COLUMN     "authorId" UUID;

-- CreateIndex
CREATE INDEX "post_versions_authorId_idx" ON "post_versions"("authorId");

-- AddForeignKey
ALTER TABLE "post_versions" ADD CONSTRAINT "post_versions_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
