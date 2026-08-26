import {
  DashboardOutlined,
  FlagOutlined,
  LogoutOutlined,
} from '@ant-design/icons';
import {
  Button,
  Layout,
  Menu,
  Space,
  Typography,
} from 'antd';
import { Outlet, useLocation, useNavigate } from 'react-router-dom';

import { useAdminAuth } from '../auth/adminAuthContext';

const { Header, Sider, Content } = Layout;

export function AdminLayout() {
  const navigate = useNavigate();
  const location = useLocation();
  const { admin, logout } = useAdminAuth();

  const selectedKey = location.pathname.startsWith('/reports')
    ? '/reports'
    : '/';

  const handleLogout = async () => {
    await logout();
    navigate('/login', { replace: true });
  };

  return (
    <Layout className="admin-shell">
      <Sider
        breakpoint="lg"
        collapsedWidth="0"
        width={240}
      >
        <div className="admin-brand">
          Glyphora Admin
        </div>

        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[selectedKey]}
          items={[
            {
              key: '/',
              icon: <DashboardOutlined />,
              label: 'Dashboard',
              onClick: () => navigate('/'),
            },
            {
              key: '/reports',
              icon: <FlagOutlined />,
              label: 'Reports',
              onClick: () => navigate('/reports'),
            },
          ]}
        />
      </Sider>

      <Layout>
        <Header className="admin-header">
          <Typography.Text strong>
            Moderation Console
          </Typography.Text>

          <Space>
            <Typography.Text type="secondary">
              {admin?.role ?? 'admin'}
            </Typography.Text>

            <Button
              type="text"
              icon={<LogoutOutlined />}
              onClick={handleLogout}
            >
              Sign out
            </Button>
          </Space>
        </Header>

        <Content className="admin-content">
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  );
}
