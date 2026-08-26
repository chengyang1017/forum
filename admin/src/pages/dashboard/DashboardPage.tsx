import {
  ReloadOutlined,
} from '@ant-design/icons';
import {
  Alert,
  Button,
  Card,
  Col,
  Flex,
  Row,
  Statistic,
  Typography,
} from 'antd';
import {
  useQuery,
} from '@tanstack/react-query';

import {
  getAdminDashboard,
} from '../../api/adminApi';

export function DashboardPage() {
  const dashboardQuery = useQuery({
    queryKey: [
      'admin',
      'dashboard',
    ],
    queryFn:
      getAdminDashboard,

    refetchOnMount:
      'always',

    refetchInterval:
      30_000,
  });

  const reports =
    dashboardQuery.data?.reports;

  return (
    <>
      <Flex
        justify="space-between"
        align="flex-start"
        wrap
        gap={16}
      >
        <div>
          <Typography.Title
            level={2}
          >
            Dashboard
          </Typography.Title>

          <Typography.Paragraph
            type="secondary"
          >
            Glyphora moderation overview.
            {reports != null &&
              ` Total reports: ${reports.total}.`}
          </Typography.Paragraph>
        </div>

        <Button
          icon={<ReloadOutlined />}
          loading={
            dashboardQuery.isFetching
          }
          onClick={() => {
            void dashboardQuery.refetch();
          }}
        >
          Refresh
        </Button>
      </Flex>

      {dashboardQuery.isError && (
        <Alert
          type="error"
          showIcon
          message="Unable to load dashboard"
          description="Check the API server and try again."
          action={
            <Button
              onClick={() => {
                void dashboardQuery.refetch();
              }}
            >
              Retry
            </Button>
          }
          style={{
            marginBottom: 16,
          }}
        />
      )}

      <Row gutter={[16, 16]}>
        <Col
          xs={24}
          sm={12}
          lg={8}
          xl={6}
        >
          <Card
            loading={
              dashboardQuery.isLoading
            }
          >
            <Statistic
              title="Pending reports"
              value={
                reports?.pending ?? 0
              }
            />
          </Card>
        </Col>

        <Col
          xs={24}
          sm={12}
          lg={8}
          xl={6}
        >
          <Card
            loading={
              dashboardQuery.isLoading
            }
          >
            <Statistic
              title="Reviewed"
              value={
                reports?.reviewed ?? 0
              }
            />
          </Card>
        </Col>

        <Col
          xs={24}
          sm={12}
          lg={8}
          xl={6}
        >
          <Card
            loading={
              dashboardQuery.isLoading
            }
          >
            <Statistic
              title="Dismissed"
              value={
                reports?.dismissed ?? 0
              }
            />
          </Card>
        </Col>

        <Col
          xs={24}
          sm={12}
          lg={8}
          xl={6}
        >
          <Card
            loading={
              dashboardQuery.isLoading
            }
          >
            <Statistic
              title="Actioned"
              value={
                reports?.actioned ?? 0
              }
            />
          </Card>
        </Col>
      </Row>
    </>
  );
}
