import { Router } from 'express';

import { requireAuth } from '../middleware/require_auth.js';

export const authRouter = Router();

authRouter.get(
  '/session',
  requireAuth,
  (_request, response) => {
    response.status(200).json({
      authenticated: true,
      user: response.locals.auth,
    });
  },
);