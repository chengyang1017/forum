import { http } from './http';

import type {
  AdminReport,
  AdminReportPage,
  GetAdminReportsParams,
  UpdateAdminReportInput,
} from '../types/report';

export interface AdminIdentity {
  id: string;
  firebaseUid: string;
  role: 'admin';
}

interface AdminMeResponse {
  admin: AdminIdentity;
}

interface UpdateAdminReportResponse {
  report: AdminReport;
}

export async function getAdminMe(): Promise<AdminIdentity> {
  const response =
    await http.get<AdminMeResponse>(
      '/admin/me',
    );

  return response.data.admin;
}

export async function getAdminReports({
  status,
  limit = 20,
  cursor,
}: GetAdminReportsParams): Promise<AdminReportPage> {
  const response =
    await http.get<AdminReportPage>(
      '/admin/reports',
      {
        params: {
          status,
          limit,
          ...(cursor == null
            ? {}
            : { cursor }),
        },
      },
    );

  return response.data;
}

export async function updateAdminReport({
  reportId,
  status,
  note,
}: UpdateAdminReportInput): Promise<AdminReport> {
  const response =
    await http.patch<UpdateAdminReportResponse>(
      `/admin/reports/${reportId}/status`,
      {
        status,
        note:
          note?.trim().length
            ? note.trim()
            : null,
      },
    );

  return response.data.report;
}
