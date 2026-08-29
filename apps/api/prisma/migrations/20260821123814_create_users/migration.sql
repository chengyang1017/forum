-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "firebaseUid" VARCHAR(128) NOT NULL,
    "username" VARCHAR(50) NOT NULL,
    "email" VARCHAR(320),
    "nickname" VARCHAR(100),
    "avatarUrl" TEXT,
    "bio" TEXT,
    "birthday" TIMESTAMP(3),
    "showAge" BOOLEAN NOT NULL DEFAULT true,
    "lastActiveAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_firebaseUid_key" ON "users"("firebaseUid");

-- CreateIndex
CREATE UNIQUE INDEX "users_username_key" ON "users"("username");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");
