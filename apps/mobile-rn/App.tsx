import {StatusBar} from 'expo-status-bar';

import {AuthGate} from './src/features/auth/AuthGate';

export default function App() {
  return (
    <>
      <StatusBar style="dark" />
      <AuthGate />
    </>
  );
}
