import { Router } from 'express';

import { requireAuth } from '../middleware/require_auth.js';
import { requireAdmin } from '../middleware/require_admin.js';

export const adminRouter = Router();

adminRouter.use(
  requireAuth,
  requireAdmin,
);

adminRouter.get('/me', (_request, response) => {
  response.status(200).json({
    admin: response.locals.admin,
  });
});
