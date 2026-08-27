import {useState} from 'react';
import {
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

type AuthFormProps = {
  mode: 'login' | 'register';
  busy: boolean;
  errorMessage: string | null;
  onSubmit(values: {email: string; password: string; username: string}): Promise<void>;
  onSwitchMode(): void;
};

type FieldProps = React.ComponentProps<typeof TextInput> & {
  symbol: string;
};

function FormField({symbol, style, ...props}: FieldProps) {
  return (
    <View style={styles.fieldShell}>
      <Text style={styles.fieldSymbol}>{symbol}</Text>
      <TextInput
        placeholderTextColor="#94A3B8"
        style={[styles.input, style]}
        {...props}
      />
    </View>
  );
}

export function AuthForm({mode, busy, errorMessage, onSubmit, onSwitchMode}: AuthFormProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [username, setUsername] = useState('');
  const [localError, setLocalError] = useState<string | null>(null);
  const isRegister = mode === 'register';

  const submit = async () => {
    if (isRegister && password !== confirmPassword) {
      setLocalError('两次输入的密码不一致');
      return;
    }
    setLocalError(null);
    await onSubmit({email: email.trim(), password, username: username.trim()});
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={styles.page}>
      <View style={styles.appBar}>
        {isRegister ? (
          <Pressable accessibilityLabel="返回登录" onPress={onSwitchMode} style={styles.backButton}>
            <Text style={styles.backIcon}>‹</Text>
          </Pressable>
        ) : <View style={styles.appBarSide} />}
        <Text style={styles.appBarTitle}>{isRegister ? '注册' : '登录'}</Text>
        <View style={styles.appBarSide} />
      </View>

      <ScrollView
        contentContainerStyle={[styles.content, isRegister && styles.registerContent]}
        keyboardShouldPersistTaps="handled">
        <View style={styles.heroIcon}>
          <Text style={styles.heroGlyph}>{isRegister ? '♙' : '▣'}</Text>
        </View>
        <Text style={styles.title}>{isRegister ? '创建新账号' : '万文社社区'}</Text>
        <Text style={styles.subtitle}>
          {isRegister ? '设置你的唯一身份，加入多语言交流社区' : '阅读、交流，遇见不同语言里的世界'}
        </Text>

        <View style={styles.form}>
          {isRegister ? (
            <FormField
              autoCapitalize="none"
              editable={!busy}
              onChangeText={setUsername}
              placeholder="用户名（唯一 ID）"
              symbol="●"
              value={username}
            />
          ) : null}
          <FormField
            autoCapitalize="none"
            autoComplete="email"
            editable={!busy}
            keyboardType="email-address"
            onChangeText={setEmail}
            placeholder="邮箱"
            symbol="✉"
            value={email}
          />
          <FormField
            autoCapitalize="none"
            autoComplete={isRegister ? 'new-password' : 'current-password'}
            editable={!busy}
            onChangeText={setPassword}
            placeholder="密码"
            secureTextEntry
            symbol="◆"
            value={password}
          />
          {isRegister ? (
            <FormField
              editable={!busy}
              onChangeText={setConfirmPassword}
              onSubmitEditing={() => void submit()}
              placeholder="确认密码"
              secureTextEntry
              symbol="◇"
              value={confirmPassword}
            />
          ) : (
            <Pressable disabled style={styles.forgotButton}>
              <Text style={styles.forgotText}>忘记密码？（尚未开放）</Text>
            </Pressable>
          )}

          {localError || errorMessage ? (
            <View style={styles.errorBox}>
              <Text accessibilityRole="alert" style={styles.errorText}>
                {localError ?? errorMessage}
              </Text>
            </View>
          ) : null}

          <Pressable
            disabled={busy}
            onPress={() => void submit()}
            style={({pressed}) => [styles.primaryButton, pressed && styles.pressed, busy && styles.disabled]}>
            {busy ? <ActivityIndicator color="#FFFFFF" /> : (
              <Text style={styles.primaryButtonText}>{isRegister ? '注册' : '登录'}</Text>
            )}
          </Pressable>

          <Pressable disabled={busy} onPress={onSwitchMode} style={styles.switchButton}>
            <Text style={styles.switchText}>
              {isRegister ? '已有账号？立即登录' : '没有账号？立即注册'}
            </Text>
          </Pressable>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  page: {flex: 1, backgroundColor: '#FFFFFF'},
  appBar: {height: 56, flexDirection: 'row', alignItems: 'center', borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: '#E5E7EB', backgroundColor: '#FFFFFF'},
  appBarSide: {width: 56},
  backButton: {width: 56, height: 56, alignItems: 'center', justifyContent: 'center'},
  backIcon: {marginTop: -4, color: '#1E293B', fontSize: 38, fontWeight: '300'},
  appBarTitle: {flex: 1, color: '#1E293B', fontSize: 18, fontWeight: '700', textAlign: 'center'},
  content: {flexGrow: 1, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 24, paddingVertical: 36},
  registerContent: {justifyContent: 'flex-start', paddingTop: 28},
  heroIcon: {width: 82, height: 82, alignItems: 'center', justifyContent: 'center', borderRadius: 24, backgroundColor: '#EFF6FF'},
  heroGlyph: {color: '#2196F3', fontSize: 46, fontWeight: '800'},
  title: {marginTop: 18, color: '#0F172A', fontSize: 28, fontWeight: '800', textAlign: 'center'},
  subtitle: {maxWidth: 360, marginTop: 8, color: '#64748B', fontSize: 14, lineHeight: 21, textAlign: 'center'},
  form: {width: '100%', maxWidth: 440, marginTop: 30},
  fieldShell: {height: 54, flexDirection: 'row', alignItems: 'center', marginBottom: 15, paddingHorizontal: 14, borderWidth: 1, borderColor: '#CBD5E1', borderRadius: 12, backgroundColor: '#FFFFFF'},
  fieldSymbol: {width: 28, color: '#64748B', fontSize: 16, textAlign: 'center'},
  input: {flex: 1, height: '100%', paddingHorizontal: 10, color: '#0F172A', fontSize: 16},
  forgotButton: {alignSelf: 'flex-end', marginTop: -4, marginBottom: 12, paddingVertical: 6},
  forgotText: {color: '#94A3B8', fontSize: 13},
  errorBox: {marginBottom: 14, padding: 11, borderRadius: 8, backgroundColor: '#FEF2F2'},
  errorText: {color: '#DC2626', fontSize: 13, lineHeight: 19},
  primaryButton: {height: 52, alignItems: 'center', justifyContent: 'center', borderRadius: 12, backgroundColor: '#2196F3'},
  primaryButtonText: {color: '#FFFFFF', fontSize: 17, fontWeight: '700'},
  switchButton: {alignItems: 'center', paddingVertical: 18},
  switchText: {color: '#1976D2', fontSize: 14, fontWeight: '600'},
  pressed: {opacity: 0.82},
  disabled: {opacity: 0.62},
});
