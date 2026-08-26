import { lazy } from 'react';

export const LoginPage = lazy(
  async () => {
    const module =
      await import(
        '../pages/login/LoginPage'
      );

    return {
      default: module.LoginPage,
    };
  },
);

export const AdminLayout = lazy(
  async () => {
    const module =
      await import(
        '../layouts/AdminLayout'
      );

    return {
      default: module.AdminLayout,
    };
  },
);

export const DashboardPage = lazy(
  async () => {
    const module =
      await import(
        '../pages/dashboard/DashboardPage'
      );

    return {
      default: module.DashboardPage,
    };
  },
);

export const ReportsPage = lazy(
  async () => {
    const module =
      await import(
        '../pages/reports/ReportsPage'
      );

    return {
      default: module.ReportsPage,
    };
  },
);
