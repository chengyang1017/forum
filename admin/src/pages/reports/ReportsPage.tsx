import {
  CheckCircleOutlined,
  CloseCircleOutlined,
  EyeOutlined,
} from '@ant-design/icons';
import {
  Alert,
  Avatar,
  Button,
  Card,
  Descriptions,
  Drawer,
  Empty,
  Flex,
  Space,
  Table,
  Tabs,
  Tag,
  Typography,
  message,
  type TableProps,
} from 'antd';
import { useMemo, useState } from 'react';
import {
  useMutation,
  useQuery,
  useQueryClient,
} from '@tanstack/react-query';

import {
  getAdminReports,
  updateAdminReport,
} from '../../api/adminApi';
import type {
  AdminReport,
  ReportStatus,
} from '../../types/report';

const PAGE_SIZE = 20;

const statusOptions: Array<{
  key: ReportStatus;
  label: string;
}> = [
  {
    key: 'pending',
    label: 'Pending',
  },
  {
    key: 'reviewed',
    label: 'Reviewed',
  },
  {
    key: 'dismissed',
    label: 'Dismissed',
  },
  {
    key: 'actioned',
    label: 'Actioned',
  },
];

function displayName(
  actor: {
    username: string;
    nickname: string | null;
  } | null,
) {
  if (actor == null) {
    return 'Unknown';
  }

  return (
    actor.nickname?.trim() ||
    actor.username
  );
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat(
    undefined,
    {
      dateStyle: 'medium',
      timeStyle: 'short',
    },
  ).format(new Date(value));
}

function statusColor(
  status: ReportStatus,
) {
  switch (status) {
    case 'pending':
      return 'orange';

    case 'reviewed':
      return 'blue';

    case 'dismissed':
      return 'default';

    case 'actioned':
      return 'red';
  }
}

function reasonColor(reason: string) {
  switch (reason) {
    case 'spam':
      return 'gold';

    case 'harassment':
    case 'hate':
    case 'violence':
      return 'red';

    case 'sexual':
      return 'magenta';

    case 'misinformation':
      return 'purple';

    case 'copyright':
      return 'blue';

    default:
      return 'default';
  }
}

export function ReportsPage() {
  const queryClient =
    useQueryClient();

  const [messageApi, contextHolder] =
    message.useMessage();

  const [
    status,
    setStatus,
  ] = useState<ReportStatus>(
    'pending',
  );

  const [
    cursor,
    setCursor,
  ] = useState<string | null>(
    null,
  );

  const [
    cursorHistory,
    setCursorHistory,
  ] = useState<
    Array<string | null>
  >([]);

  const [
    selectedReport,
    setSelectedReport,
  ] = useState<AdminReport | null>(
    null,
  );

  const [
    adminNote,
    setAdminNote,
  ] = useState('');

  const reportsQuery = useQuery({
    queryKey: [
      'admin',
      'reports',
      status,
      cursor,
    ],
    queryFn: () =>
      getAdminReports({
        status,
        limit: PAGE_SIZE,
        cursor,
      }),
  });

  const updateMutation =
    useMutation({
      mutationFn: updateAdminReport,

      onSuccess: async (
        updatedReport,
      ) => {
        setSelectedReport(
          updatedReport,
        );

        await queryClient.invalidateQueries({
          queryKey: [
            'admin',
            'reports',
          ],
        });

        messageApi.success(
          'Report updated',
        );

        setSelectedReport(null);
      },

      onError: () => {
        messageApi.error(
          'Failed to update report',
        );
      },
    });

  const reports =
    reportsQuery.data?.reports ?? [];

  const nextCursor =
    reportsQuery.data
      ?.pagination
      .nextCursor ?? null;

  const openReport = (
    report: AdminReport,
  ) => {
    setSelectedReport(report);
    setAdminNote(
      report.adminNote ?? '',
    );
  };

  const changeStatus = (
    nextStatus: ReportStatus,
  ) => {
    setStatus(nextStatus);
    setCursor(null);
    setCursorHistory([]);
    setSelectedReport(null);
  };

  const goNext = () => {
    if (nextCursor == null) {
      return;
    }

    setCursorHistory(
      (history) => [
        ...history,
        cursor,
      ],
    );

    setCursor(nextCursor);
  };

  const goPrevious = () => {
    setCursorHistory(
      (history) => {
        if (history.length === 0) {
          return history;
        }

        const previousCursor =
          history[
            history.length - 1
          ];

        setCursor(
          previousCursor ?? null,
        );

        return history.slice(
          0,
          -1,
        );
      },
    );
  };

  const submitStatus = (
    nextStatus:
      | 'reviewed'
      | 'dismissed'
      | 'actioned',
  ) => {
    if (selectedReport == null) {
      return;
    }

    updateMutation.mutate({
      reportId:
        selectedReport.id,
      status: nextStatus,
      note: adminNote,
    });
  };

  const columns =
    useMemo<
      TableProps<AdminReport>[
        'columns'
      ]
    >(
      () => [
        {
          title: 'Reason',
          dataIndex: 'reason',
          width: 140,
          render: (
            reason: string,
          ) => (
            <Tag
              color={reasonColor(
                reason,
              )}
            >
              {reason}
            </Tag>
          ),
        },
        {
          title: 'Reporter',
          width: 200,
          render: (
            _,
            report,
          ) => (
            <Space>
              <Avatar
                src={
                  report.reporter
                    .avatarUrl
                }
              >
                {displayName(
                  report.reporter,
                )
                  .charAt(0)
                  .toUpperCase()}
              </Avatar>

              <div>
                <Typography.Text>
                  {displayName(
                    report.reporter,
                  )}
                </Typography.Text>

                <br />

                <Typography.Text
                  type="secondary"
                >
                  @
                  {
                    report
                      .reporter
                      .username
                  }
                </Typography.Text>
              </div>
            </Space>
          ),
        },
        {
          title: 'Post',
          render: (
            _,
            report,
          ) => (
            <div className="report-post-cell">
              <Typography.Text
                strong
                ellipsis
              >
                {report.post.title ||
                  'Untitled post'}
              </Typography.Text>

              <Typography.Paragraph
                type="secondary"
                ellipsis={{
                  rows: 2,
                }}
              >
                {report.post.content}
              </Typography.Paragraph>
            </div>
          ),
        },
        {
          title: 'Author',
          width: 180,
          render: (
            _,
            report,
          ) => (
            <Typography.Text>
              {displayName(
                report.post.author,
              )}
            </Typography.Text>
          ),
        },
        {
          title: 'Created',
          width: 190,
          render: (
            _,
            report,
          ) =>
            formatDate(
              report.createdAt,
            ),
        },
        {
          title: 'Status',
          width: 130,
          render: (
            _,
            report,
          ) => (
            <Tag
              color={statusColor(
                report.status,
              )}
            >
              {report.status}
            </Tag>
          ),
        },
        {
          title: '',
          width: 60,
          align: 'right',
          render: (
            _,
            report,
          ) => (
            <Button
              type="text"
              icon={
                <EyeOutlined />
              }
              onClick={(event) => {
                event.stopPropagation();
                openReport(
                  report,
                );
              }}
            />
          ),
        },
      ],
      [],
    );

  return (
    <>
      {contextHolder}

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
            Reports
          </Typography.Title>

          <Typography.Paragraph
            type="secondary"
          >
            Review reported posts
            and record moderation
            decisions.
          </Typography.Paragraph>
        </div>
      </Flex>

      <Card>
        <Tabs
          activeKey={status}
          onChange={(key) =>
            changeStatus(
              key as ReportStatus,
            )
          }
          items={statusOptions}
        />

        {reportsQuery.isError && (
          <Alert
            type="error"
            showIcon
            message="Unable to load reports"
            description="Check the API server and try again."
            action={
              <Button
                onClick={() => {
                  void reportsQuery.refetch();
                }}
              >
                Retry
              </Button>
            }
            className="report-alert"
          />
        )}

        {!reportsQuery.isError && (
          <Table<AdminReport>
            rowKey="id"
            columns={columns}
            dataSource={reports}
            loading={
              reportsQuery.isLoading ||
              reportsQuery.isFetching
            }
            pagination={false}
            locale={{
              emptyText: (
                <Empty
                  description={`No ${status} reports`}
                />
              ),
            }}
            scroll={{
              x: 1100,
            }}
            onRow={(report) => ({
              onClick: () =>
                openReport(report),
              className:
                'report-table-row',
            })}
          />
        )}

        <Flex
          justify="flex-end"
          gap={8}
          className="report-pagination"
        >
          <Button
            disabled={
              cursorHistory.length ===
                0 ||
              reportsQuery.isFetching
            }
            onClick={goPrevious}
          >
            Previous
          </Button>

          <Button
            disabled={
              nextCursor == null ||
              reportsQuery.isFetching
            }
            onClick={goNext}
          >
            Next
          </Button>
        </Flex>
      </Card>

      <Drawer
        title="Report review"
        width={560}
        open={
          selectedReport != null
        }
        onClose={() =>
          setSelectedReport(null)
        }
      >
        {selectedReport != null && (
          <Space
            direction="vertical"
            size="large"
            className="report-drawer-content"
          >
            <Flex
              justify="space-between"
              align="center"
              wrap
              gap={8}
            >
              <Space>
                <Tag
                  color={reasonColor(
                    selectedReport.reason,
                  )}
                >
                  {
                    selectedReport.reason
                  }
                </Tag>

                <Tag
                  color={statusColor(
                    selectedReport.status,
                  )}
                >
                  {
                    selectedReport.status
                  }
                </Tag>
              </Space>

              <Typography.Text
                type="secondary"
              >
                {formatDate(
                  selectedReport.createdAt,
                )}
              </Typography.Text>
            </Flex>

            <Card
              size="small"
              title="Reported post"
            >
              <Typography.Title
                level={5}
              >
                {selectedReport.post
                  .title ||
                  'Untitled post'}
              </Typography.Title>

              <Typography.Paragraph
                className="report-post-content"
              >
                {
                  selectedReport.post
                    .content
                }
              </Typography.Paragraph>
            </Card>

            <Descriptions
              column={1}
              size="small"
              bordered
              items={[
                {
                  key: 'reporter',
                  label: 'Reporter',
                  children: `${displayName(
                    selectedReport.reporter,
                  )} (@${selectedReport.reporter.username})`,
                },
                {
                  key: 'author',
                  label: 'Post author',
                  children:
                    displayName(
                      selectedReport.post
                        .author,
                    ),
                },
                {
                  key: 'language',
                  label: 'Language',
                  children:
                    selectedReport.post
                      .languageCode,
                },
              ]}
            />

            <div>
              <Typography.Text
                strong
              >
                Report details
              </Typography.Text>

              <Typography.Paragraph
                className="report-detail-box"
              >
                {selectedReport.details ??
                  'No additional details.'}
              </Typography.Paragraph>
            </div>

            {selectedReport
              .handledBy != null && (
              <Alert
                type="info"
                showIcon
                message={`Last handled by ${displayName(
                  selectedReport.handledBy,
                )}`}
                description={
                  selectedReport.handledAt ==
                  null
                    ? undefined
                    : formatDate(
                        selectedReport.handledAt,
                      )
                }
              />
            )}

            <div>
              <Typography.Text
                strong
              >
                Admin note
              </Typography.Text>

              <textarea
                className="report-note"
                maxLength={2000}
                value={adminNote}
                onChange={(event) =>
                  setAdminNote(
                    event.target.value,
                  )
                }
                placeholder="Optional moderation note"
              />
            </div>

            <Alert
              type="warning"
              showIcon
              message="Actioned records a moderation decision only."
              description="It does not delete or hide the post."
            />

            <Flex
              wrap
              gap={8}
            >
              <Button
                icon={
                  <CheckCircleOutlined />
                }
                loading={
                  updateMutation.isPending
                }
                onClick={() =>
                  submitStatus(
                    'reviewed',
                  )
                }
              >
                Mark reviewed
              </Button>

              <Button
                icon={
                  <CloseCircleOutlined />
                }
                loading={
                  updateMutation.isPending
                }
                onClick={() =>
                  submitStatus(
                    'dismissed',
                  )
                }
              >
                Dismiss
              </Button>

              <Button
                danger
                type="primary"
                loading={
                  updateMutation.isPending
                }
                onClick={() =>
                  submitStatus(
                    'actioned',
                  )
                }
              >
                Mark actioned
              </Button>
            </Flex>
          </Space>
        )}
      </Drawer>
    </>
  );
}
