export interface AdminDashboard {
  reports: {
    total: number;
    pending: number;
    reviewed: number;
    dismissed: number;
    actioned: number;
  };
}
