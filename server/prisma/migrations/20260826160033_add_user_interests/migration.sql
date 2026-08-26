-- AlterTable
ALTER TABLE "users" ADD COLUMN     "interests" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "interestsMigratedAt" TIMESTAMP(3);
