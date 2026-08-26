import {
  createBrowserRouter,
} from 'react-router-dom';

import { AdminLayout } from '../layouts/AdminLayout';
import { DashboardPage } from '../pages/dashboard/DashboardPage';
import { LoginPage } from '../pages/login/LoginPage';
import { ReportsPage } from '../pages/reports/ReportsPage';
import { ProtectedRoute } from './ProtectedRoute';

export const router =
  createBrowserRouter([
    {
      path: '/login',
      element: <LoginPage />,
    },
    {
      element: <ProtectedRoute />,
      children: [
        {
          element: <AdminLayout />,
          children: [
            {
              path: '/',
              element: <DashboardPage />,
            },
            {
              path: '/reports',
              element: <ReportsPage />,
            },
          ],
        },
      ],
    },
  ]);
