import {StyleSheet, Text, View} from 'react-native';

export function MessagesPlaceholderScreen() {
  return (
    <View style={styles.page}>
      <View style={styles.icon}><Text style={styles.iconText}>◱</Text></View>
      <Text style={styles.title}>消息</Text>
      <Text style={styles.description}>聊天功能不在本阶段实现。</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  page: {flex: 1, alignItems: 'center', justifyContent: 'center', padding: 24, backgroundColor: '#F8FAFC'},
  icon: {width: 68, height: 68, alignItems: 'center', justifyContent: 'center', borderRadius: 34, backgroundColor: '#E3F2FD'},
  iconText: {color: '#2196F3', fontSize: 30},
  title: {marginTop: 16, color: '#1E293B', fontSize: 21, fontWeight: '800'},
  description: {marginTop: 7, color: '#64748B', fontSize: 14},
});
