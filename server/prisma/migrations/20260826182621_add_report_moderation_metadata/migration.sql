-- AlterTable
ALTER TABLE "post_reports" ADD COLUMN     "adminNote" TEXT,
ADD COLUMN     "handledAt" TIMESTAMP(3),
ADD COLUMN     "handledById" UUID;

-- CreateIndex
CREATE INDEX "post_reports_handledById_handledAt_idx" ON "post_reports"("handledById", "handledAt");

-- AddForeignKey
ALTER TABLE "post_reports" ADD CONSTRAINT "post_reports_handledById_fkey" FOREIGN KEY ("handledById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
