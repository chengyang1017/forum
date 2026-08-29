import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import {
  QueryClient,
  QueryClientProvider,
} from '@tanstack/react-query';
import { ConfigProvider } from 'antd';

import App from './App';
import { AdminAuthProvider } from './auth/AdminAuthProvider';
import './index.css';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

createRoot(
  document.getElementById('root')!,
).render(
  <StrictMode>
    <ConfigProvider>
      <QueryClientProvider client={queryClient}>
        <AdminAuthProvider>
          <App />
        </AdminAuthProvider>
      </QueryClientProvider>
    </ConfigProvider>
  </StrictMode>,
);
