import type {
  NextFunction,
  Request,
  Response,
} from 'express';

import { prisma } from '../lib/prisma.js';

export async function requireAdmin(
  _request: Request,
  response: Response,
  next: NextFunction,
): Promise<void> {
  const firebaseUid =
    response.locals.auth?.firebaseUid;

  if (
    typeof firebaseUid !== 'string' ||
    firebaseUid.length === 0
  ) {
    response.status(401).json({
      error: 'UNAUTHORIZED',
      message: 'Authentication required',
    });

    return;
  }

  try {
    const user = await prisma.user.findUnique({
      where: {
        firebaseUid,
      },
      select: {
        id: true,
        firebaseUid: true,
        role: true,
      },
    });

    if (user?.role !== 'admin') {
      response.status(403).json({
        error: 'ADMIN_REQUIRED',
        message: 'Administrator permission required',
      });

      return;
    }

    response.locals.admin = {
      id: user.id,
      firebaseUid: user.firebaseUid,
      role: user.role,
    };

    next();
  } catch (error) {
    console.error(
      'Admin authorization failed:',
      error,
    );

    response.status(500).json({
      error: 'ADMIN_AUTH_FAILED',
      message: 'Failed to verify administrator permission',
    });
  }
}
