import express from 'express';
import cors from 'cors';
import helmet from 'helmet';

import { prisma } from './lib/prisma.js';

import { authRouter } from './routes/auth_route.js';

import { userRouter } from './routes/user_route.js';

import { postRouter } from './routes/post_route.js';
import { commentRouter } from './routes/comment_route.js';

export const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

app.use('/api/v1/auth', authRouter);
app.use('/api/v1/users', userRouter);
app.use(
  '/api/v1/posts',
  postRouter,
);
app.use(
  '/api/v1/posts',
  commentRouter,
);

app.get('/health', async (_request, response) => {
  try {
    await prisma.$queryRaw`SELECT 1`;

    response.status(200).json({
      status: 'ok',
      database: 'connected',
    });
  } catch (error) {
    console.error('Database health check failed:', error);

    response.status(503).json({
      status: 'error',
      database: 'disconnected',
    });
  }
});