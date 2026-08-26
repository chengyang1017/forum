import {
  Empty,
  Typography,
} from 'antd';

export function ReportsPage() {
  return (
    <>
      <Typography.Title level={2}>
        Reports
      </Typography.Title>

      <Typography.Paragraph type="secondary">
        Review and manage reported posts.
      </Typography.Paragraph>

      <Empty
        description="Report table will be connected next."
      />
    </>
  );
}
