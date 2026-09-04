#!/usr/bin/env python3
from pathlib import Path

PATH = Path(__file__).resolve().parents[1] / 'src' / 'pages' / 'reports' / 'ReportsPage.tsx'
text = PATH.read_text(encoding='utf-8')


def replace_once(old: str, new: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'Expected one match, found {count}: {old[:80]!r}')
    text = text.replace(old, new)


replace_once(
    """import {\n  CheckCircleOutlined,\n  CloseCircleOutlined,\n  EyeOutlined,\n} from '@ant-design/icons';\n""",
    """import {\n  CheckCircleOutlined,\n  CloseCircleOutlined,\n  DeleteOutlined,\n  EyeInvisibleOutlined,\n  EyeOutlined,\n  StopOutlined,\n  UndoOutlined,\n} from '@ant-design/icons';\n""",
)
replace_once(
    """  Flex,\n  Space,\n  Table,\n""",
    """  Flex,\n  Modal,\n  Space,\n  Table,\n""",
)
replace_once(
    """import {\n  getAdminReports,\n  updateAdminReport,\n} from '../../api/adminApi';\n""",
    """import {\n  banReportedPostAuthor,\n  deleteReportedPost,\n  getAdminReports,\n  hideReportedPost,\n  restoreReportedPost,\n  updateAdminReport,\n} from '../../api/adminApi';\n""",
)

marker = """  const reports =\n    reportsQuery.data?.reports ?? [];\n"""
insert = """  const moderationMutation =\n    useMutation({\n      mutationFn: async ({\n        action,\n        reportId,\n      }: {\n        action:\n          | 'hide'\n          | 'restore'\n          | 'delete'\n          | 'ban';\n        reportId: string;\n      }) => {\n        switch (action) {\n          case 'hide':\n            await hideReportedPost(reportId);\n            return 'Post hidden';\n          case 'restore':\n            await restoreReportedPost(reportId);\n            return 'Post restored';\n          case 'delete':\n            await deleteReportedPost(reportId);\n            return 'Post permanently deleted';\n          case 'ban':\n            await banReportedPostAuthor(reportId);\n            return 'Author banned and post hidden';\n        }\n      },\n      onSuccess: async (successMessage) => {\n        await queryClient.invalidateQueries({\n          queryKey: ['admin', 'reports'],\n        });\n        messageApi.success(successMessage);\n        setSelectedReport(null);\n      },\n      onError: () => {\n        messageApi.error('Moderation action failed');\n      },\n    });\n\n  const runModerationAction = (\n    action: 'hide' | 'restore' | 'delete' | 'ban',\n  ) => {\n    if (selectedReport == null) {\n      return;\n    }\n\n    const execute = () =>\n      moderationMutation.mutate({\n        action,\n        reportId: selectedReport.id,\n      });\n\n    if (action === 'delete') {\n      Modal.confirm({\n        title: 'Permanently delete this post?',\n        content:\n          'The post, versions, comments, reports and database relations will be deleted. This cannot be undone.',\n        okText: 'Delete post',\n        okButtonProps: { danger: true },\n        onOk: execute,\n      });\n      return;\n    }\n\n    if (action === 'ban') {\n      Modal.confirm({\n        title: 'Ban this author?',\n        content:\n          'The Firebase account will be disabled, active sessions will be revoked and this reported post will be hidden.',\n        okText: 'Ban author',\n        okButtonProps: { danger: true },\n        onOk: execute,\n      });\n      return;\n    }\n\n    execute();\n  };\n\n""" + marker
replace_once(marker, insert)

replace_once(
    """            <Alert\n              type=\"warning\"\n              showIcon\n              message=\"Actioned records a moderation decision only.\"\n              description=\"It does not delete or hide the post.\"\n            />\n""",
    """            <Alert\n              type=\"warning\"\n              showIcon\n              message=\"Actioned posts are hidden from normal app reads.\"\n              description=\"Use Restore to publish the post again, Delete for permanent removal, or Ban author for account enforcement.\"\n            />\n""",
)

replace_once(
    """              <Button\n                danger\n                type=\"primary\"\n                loading={\n                  updateMutation.isPending\n                }\n                onClick={() =>\n                  submitStatus(\n                    'actioned',\n                  )\n                }\n              >\n                Mark actioned\n              </Button>\n""",
    """              {selectedReport.status === 'actioned' ? (\n                <Button\n                  icon={<UndoOutlined />}\n                  loading={moderationMutation.isPending}\n                  onClick={() => runModerationAction('restore')}\n                >\n                  Restore post\n                </Button>\n              ) : (\n                <Button\n                  danger\n                  icon={<EyeInvisibleOutlined />}\n                  loading={moderationMutation.isPending}\n                  onClick={() => runModerationAction('hide')}\n                >\n                  Hide post\n                </Button>\n              )}\n\n              <Button\n                danger\n                icon={<DeleteOutlined />}\n                loading={moderationMutation.isPending}\n                onClick={() => runModerationAction('delete')}\n              >\n                Delete post\n              </Button>\n\n              {selectedReport.post.author != null && (\n                <Button\n                  danger\n                  type=\"primary\"\n                  icon={<StopOutlined />}\n                  loading={moderationMutation.isPending}\n                  onClick={() => runModerationAction('ban')}\n                >\n                  Ban author\n                </Button>\n              )}\n""",
)

PATH.write_text(text, encoding='utf-8')
print('Admin report moderation UI patched.')
