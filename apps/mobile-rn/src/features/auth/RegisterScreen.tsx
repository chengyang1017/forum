import {AuthForm} from './AuthForm';

type RegisterScreenProps = {
  busy: boolean;
  errorMessage: string | null;
  onRegister(
    email: string,
    password: string,
    username: string,
  ): Promise<void>;
  onShowLogin(): void;
};

export function RegisterScreen({
  busy,
  errorMessage,
  onRegister,
  onShowLogin,
}: RegisterScreenProps) {
  return (
    <AuthForm
      busy={busy}
      errorMessage={errorMessage}
      mode="register"
      onSubmit={({email, password, username}) =>
        onRegister(email, password, username)
      }
      onSwitchMode={onShowLogin}
    />
  );
}
