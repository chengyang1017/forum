import {
  Alert,
  Button,
  Card,
  Form,
  Input,
  Typography,
} from 'antd';
import { useState } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';

import { useAdminAuth } from '../../auth/adminAuthContext';

interface LoginFormValues {
  email: string;
  password: string;
}

export function LoginPage() {
  const navigate = useNavigate();
  const {
    admin,
    loading,
    login,
  } = useAdminAuth();

  const [error, setError] = useState<string | null>(null);

  if (admin != null) {
    return <Navigate to="/" replace />;
  }

  const handleFinish = async (
    values: LoginFormValues,
  ) => {
    setError(null);

    try {
      await login(
        values.email.trim(),
        values.password,
      );

      navigate('/', { replace: true });
    } catch (loginError) {
      setError(
        loginError instanceof Error
          ? loginError.message
          : 'Login failed',
      );
    }
  };

  return (
    <main className="login-page">
      <Card className="login-card">
        <Typography.Title level={2}>
          Glyphora Admin
        </Typography.Title>

        <Typography.Paragraph type="secondary">
          Sign in with an administrator account.
        </Typography.Paragraph>

        {error != null && (
          <Alert
            type="error"
            showIcon
            message={error}
            className="login-error"
          />
        )}

        <Form<LoginFormValues>
          layout="vertical"
          onFinish={handleFinish}
          autoComplete="on"
        >
          <Form.Item
            name="email"
            label="Email"
            rules={[
              {
                required: true,
                message: 'Email is required',
              },
            ]}
          >
            <Input
              type="email"
              autoComplete="email"
            />
          </Form.Item>

          <Form.Item
            name="password"
            label="Password"
            rules={[
              {
                required: true,
                message: 'Password is required',
              },
            ]}
          >
            <Input.Password
              autoComplete="current-password"
            />
          </Form.Item>

          <Button
            type="primary"
            htmlType="submit"
            loading={loading}
            block
          >
            Sign in
          </Button>
        </Form>
      </Card>
    </main>
  );
}
