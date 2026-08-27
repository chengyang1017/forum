import { Spin } from 'antd';
import {
  Navigate,
  Outlet,
} from 'react-router-dom';

import { useAdminAuth } from '../auth/adminAuthContext';

export function ProtectedRoute() {
  const {
    user,
    admin,
    loading,
  } = useAdminAuth();

  if (loading) {
    return (
      <div className="route-loading">
        <Spin size="large" />
      </div>
    );
  }

  if (
    user == null ||
    admin == null
  ) {
    return (
      <Navigate
        to="/login"
        replace
      />
    );
  }

  return <Outlet />;
}
