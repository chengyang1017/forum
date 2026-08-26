import {
  Card,
  Col,
  Row,
  Statistic,
  Typography,
} from 'antd';

export function DashboardPage() {
  return (
    <>
      <Typography.Title level={2}>
        Dashboard
      </Typography.Title>

      <Typography.Paragraph type="secondary">
        Glyphora moderation overview.
      </Typography.Paragraph>

      <Row gutter={[16, 16]}>
        <Col xs={24} sm={12} lg={8}>
          <Card>
            <Statistic
              title="Pending reports"
              value={0}
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={8}>
          <Card>
            <Statistic
              title="Reviewed"
              value={0}
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={8}>
          <Card>
            <Statistic
              title="Actioned"
              value={0}
            />
          </Card>
        </Col>
      </Row>
    </>
  );
}
