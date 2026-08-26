import { http } from './http';

export interface AdminIdentity {
  id: string;
  firebaseUid: string;
  role: 'admin';
}

interface AdminMeResponse {
  admin: AdminIdentity;
}

export async function getAdminMe(): Promise<AdminIdentity> {
  const response = await http.get<AdminMeResponse>('/admin/me');

  return response.data.admin;
}
