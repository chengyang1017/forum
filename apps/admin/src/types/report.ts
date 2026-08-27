export type ReportStatus =
  | 'pending'
  | 'reviewed'
  | 'dismissed'
  | 'actioned';

export interface AdminReportActor {
  username: string;
  nickname: string | null;
}

export interface AdminReportReporter
  extends AdminReportActor {
  avatarUrl: string | null;
}

export interface AdminReportPostAuthor
  extends AdminReportActor {
  firebaseUid: string;
}

export interface AdminReportPost {
  databaseId: string;
  id: string;
  title: string;
  content: string;
  languageCode: string;
  primaryLanguageCode: string;
  author: AdminReportPostAuthor | null;
  createdAt: string;
  updatedAt: string;
}

export interface AdminReport {
  id: string;
  reason: string;
  details: string | null;
  status: ReportStatus;
  adminNote: string | null;
  handledAt: string | null;
  handledBy: AdminReportActor | null;
  createdAt: string;
  updatedAt: string;
  reporter: AdminReportReporter;
  post: AdminReportPost;
}

export interface AdminReportPage {
  reports: AdminReport[];
  pagination: {
    limit: number;
    nextCursor: string | null;
  };
}

export interface GetAdminReportsParams {
  status: ReportStatus;
  limit?: number;
  cursor?: string | null;
}

export interface UpdateAdminReportInput {
  reportId: string;
  status: Exclude<
    ReportStatus,
    'pending'
  >;
  note?: string | null;
}
