import type {NavigatorScreenParams} from '@react-navigation/native';

export type FeedStackParamList = {
  FeedHome: undefined;
  CreatePost: undefined;
  PostDetail: {postId: string};
};

export type RootTabParamList = {
  FeedTab: NavigatorScreenParams<FeedStackParamList> | undefined;
  MessagesTab: undefined;
  ProfileTab: undefined;
};
