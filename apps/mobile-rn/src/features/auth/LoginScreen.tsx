import {AuthForm} from './AuthForm';

type LoginScreenProps = {
  busy: boolean;
  errorMessage: string | null;
  onLogin(email: string, password: string): Promise<void>;
  onShowRegister(): void;
};

export function LoginScreen({
  busy,
  errorMessage,
  onLogin,
  onShowRegister,
}: LoginScreenProps) {
  return (
    <AuthForm
      busy={busy}
      errorMessage={errorMessage}
      mode="login"
      onSubmit={({email, password}) => onLogin(email, password)}
      onSwitchMode={onShowRegister}
    />
  );
}
