import {ActivityIndicator, Pressable, StyleSheet, Text, View} from 'react-native';

type ScreenStateProps = {
  kind: 'loading' | 'empty' | 'error';
  title: string;
  message?: string;
  actionLabel?: string;
  onAction?: () => void;
};

export function ScreenState({kind, title, message, actionLabel, onAction}: ScreenStateProps) {
  return (
    <View style={styles.container}>
      {kind === 'loading' ? (
        <ActivityIndicator color="#2196F3" size="large" />
      ) : (
        <View style={[styles.iconCircle, kind === 'error' && styles.errorCircle]}>
          <Text style={[styles.icon, kind === 'error' && styles.errorIcon]}>
            {kind === 'error' ? '!' : '▤'}
          </Text>
        </View>
      )}
      <Text style={[styles.title, kind === 'error' && styles.errorTitle]}>{title}</Text>
      {message ? <Text style={styles.message}>{message}</Text> : null}
      {actionLabel && onAction ? (
        <Pressable onPress={onAction} style={styles.action}>
          <Text style={styles.actionText}>{actionLabel}</Text>
        </Pressable>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {flex: 1, alignItems: 'center', justifyContent: 'center', padding: 28, backgroundColor: '#F8FAFC'},
  iconCircle: {width: 68, height: 68, alignItems: 'center', justifyContent: 'center', borderRadius: 34, backgroundColor: '#E2E8F0'},
  errorCircle: {backgroundColor: '#FEE2E2'},
  icon: {color: '#94A3B8', fontSize: 32, fontWeight: '700'},
  errorIcon: {color: '#EF4444'},
  title: {marginTop: 16, color: '#1E293B', fontSize: 17, fontWeight: '700', textAlign: 'center'},
  errorTitle: {color: '#DC2626'},
  message: {maxWidth: 340, marginTop: 7, color: '#64748B', fontSize: 13, lineHeight: 20, textAlign: 'center'},
  action: {marginTop: 18, paddingHorizontal: 18, paddingVertical: 10, borderRadius: 10, backgroundColor: '#2196F3'},
  actionText: {color: '#FFFFFF', fontWeight: '700'},
});
