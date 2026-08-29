import {
  Suspense,
  type ReactNode,
} from 'react';
import { Spin } from 'antd';
import {
  createBrowserRouter,
} from 'react-router-dom';

import {
  AdminLayout,
  DashboardPage,
  LoginPage,
  ReportsPage,
} from './lazyRoutes';
import { ProtectedRoute } from './ProtectedRoute';

function suspense(
  element: ReactNode,
) {
  return (
    <Suspense
      fallback={
        <div className="route-loading">
          <Spin size="large" />
        </div>
      }
    >
      {element}
    </Suspense>
  );
}

export const router =
  createBrowserRouter([
    {
      path: '/login',
      element: suspense(
        <LoginPage />,
      ),
    },
    {
      element: <ProtectedRoute />,
      children: [
        {
          element: suspense(
            <AdminLayout />,
          ),
          children: [
            {
              path: '/',
              element: suspense(
                <DashboardPage />,
              ),
            },
            {
              path: '/reports',
              element: suspense(
                <ReportsPage />,
              ),
            },
          ],
        },
      ],
    },
  ]);
