import 'dotenv/config';

import { prisma } from '../lib/prisma.js';

function readArgument(name: string): string | null {
  const index = process.argv.indexOf(name);

  if (index === -1) {
    return null;
  }

  const value = process.argv[index + 1];

  if (!value || value.startsWith('--')) {
    return null;
  }

  return value.trim();
}

async function main(): Promise<void> {
  const email = readArgument('--email');
  const role = readArgument('--role');

  if (!email) {
    throw new Error(
      'Missing --email. Example: --email user@example.com --role admin',
    );
  }

  if (role !== 'user' && role !== 'admin') {
    throw new Error(
      'Invalid --role. Allowed values: user, admin',
    );
  }

  const user = await prisma.user.findUnique({
    where: {
      email,
    },
    select: {
      id: true,
      email: true,
      username: true,
      role: true,
    },
  });

  if (!user) {
    throw new Error(
      `User not found: ${email}`,
    );
  }

  if (user.role === role) {
    console.log(
      `${user.email} already has role: ${role}`,
    );
    return;
  }

  const updated = await prisma.user.update({
    where: {
      id: user.id,
    },
    data: {
      role,
    },
    select: {
      email: true,
      username: true,
      role: true,
    },
  });

  console.log(
    `Updated ${updated.email} (${updated.username}): role=${updated.role}`,
  );
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
