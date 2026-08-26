import axios from 'axios';

import { auth } from '../auth/firebase';

export const http = axios.create({
  baseURL:
    import.meta.env.VITE_API_BASE_URL ??
    'http://127.0.0.1:3000/api/v1',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

http.interceptors.request.use(async (config) => {
  const user = auth.currentUser;

  if (user != null) {
    const token = await user.getIdToken();

    config.headers.Authorization = `Bearer ${token}`;
  }

  return config;
});
