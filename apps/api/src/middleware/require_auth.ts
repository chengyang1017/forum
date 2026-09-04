import type {
  NextFunction,
  Request,
  Response,
} from 'express';

import { firebaseAuth } from '../lib/firebase_admin.js';

export async function requireAuth(
  request: Request,
  response: Response,
  next: NextFunction,
): Promise<void> {
  const authorization = request.header('authorization');

  if (!authorization?.startsWith('Bearer ')) {
    response.status(401).json({
      error: 'UNAUTHORIZED',
      message: 'Missing bearer token',
    });

    return;
  }

  const idToken = authorization
    .slice('Bearer '.length)
    .trim();

  if (!idToken) {
    response.status(401).json({
      error: 'UNAUTHORIZED',
      message: 'Missing Firebase ID token',
    });

    return;
  }

  try {
    // checkRevoked=true is required for moderation/account enforcement. A
    // disabled or explicitly revoked account must not keep API access through
    // an ID token that was issued before the enforcement action.
    const decodedToken =
      await firebaseAuth.verifyIdToken(idToken, true);

    response.locals.auth = {
      firebaseUid: decodedToken.uid,
      email: decodedToken.email ?? null,
    };

    next();
  } catch {
    response.status(401).json({
      error: 'UNAUTHORIZED',
      message: 'Invalid, expired or revoked Firebase ID token',
    });
  }
}
