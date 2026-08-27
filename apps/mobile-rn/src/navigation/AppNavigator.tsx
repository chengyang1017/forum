import {NavigationContainer} from '@react-navigation/native';
import {createBottomTabNavigator} from '@react-navigation/bottom-tabs';
import {createNativeStackNavigator} from '@react-navigation/native-stack';
import {StyleSheet, Text} from 'react-native';

import {CreatePostScreen} from '../features/feed/CreatePostScreen';
import {FeedScreen} from '../features/feed/FeedScreen';
import {PostDetailScreen} from '../features/feed/PostDetailScreen';
import {MessagesPlaceholderScreen} from '../features/messages/MessagesPlaceholderScreen';
import {ProfilePlaceholderScreen} from '../features/profile/ProfilePlaceholderScreen';
import type {FeedStackParamList, RootTabParamList} from './types';

const Tab = createBottomTabNavigator<RootTabParamList>();
const FeedStack = createNativeStackNavigator<FeedStackParamList>();

function FeedNavigator() {
  return (
    <FeedStack.Navigator
      screenOptions={{
        contentStyle: {backgroundColor: '#F8FAFC'},
        headerShadowVisible: false,
        headerTintColor: '#1E293B',
        headerTitleStyle: {fontWeight: '700'},
      }}>
      <FeedStack.Screen component={FeedScreen} name="FeedHome" options={{headerShown: false}} />
      <FeedStack.Screen component={CreatePostScreen} name="CreatePost" options={{title: '发帖'}} />
      <FeedStack.Screen component={PostDetailScreen} name="PostDetail" options={{title: '帖子详情'}} />
    </FeedStack.Navigator>
  );
}

function TabIcon({symbol, focused}: {symbol: string; focused: boolean}) {
  return <Text style={[styles.tabIcon, focused && styles.tabIconActive]}>{symbol}</Text>;
}

export function AppNavigator() {
  return (
    <NavigationContainer>
      <Tab.Navigator
        screenOptions={{
          headerShown: false,
          tabBarActiveTintColor: '#2196F3',
          tabBarInactiveTintColor: '#64748B',
          tabBarLabelStyle: {fontSize: 11, fontWeight: '600'},
          tabBarStyle: {height: 66, paddingBottom: 7, paddingTop: 6},
        }}>
        <Tab.Screen
          component={FeedNavigator}
          name="FeedTab"
          options={{tabBarIcon: ({focused}) => <TabIcon focused={focused} symbol="⌂" />, title: '首页'}}
        />
        <Tab.Screen
          component={MessagesPlaceholderScreen}
          name="MessagesTab"
          options={{tabBarIcon: ({focused}) => <TabIcon focused={focused} symbol="◱" />, title: '消息'}}
        />
        <Tab.Screen
          component={ProfilePlaceholderScreen}
          name="ProfileTab"
          options={{tabBarIcon: ({focused}) => <TabIcon focused={focused} symbol="♙" />, title: '我的'}}
        />
      </Tab.Navigator>
    </NavigationContainer>
  );
}

const styles = StyleSheet.create({
  tabIcon: {color: '#64748B', fontSize: 23, lineHeight: 25},
  tabIconActive: {color: '#2196F3'},
});
