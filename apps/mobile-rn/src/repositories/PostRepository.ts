import {
  collection,
  doc,
  getDoc,
  getFirestore,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
} from '@react-native-firebase/firestore';

import {decodePost, Post} from '../models/Post';

export type PostsListener = (posts: Post[]) => void;
export type PostsErrorListener = (error: Error) => void;

export type CreatePostInput = {
  uid: string;
  username: string;
  nickname: string;
  title: string;
  content: string;
  category: string;
  languageCode: string;
  languageName: string;
};

export class PostRepository {
  watchPosts(
    onNext: PostsListener,
    onError: PostsErrorListener,
  ): () => void {
    const postsQuery = query(
      collection(getFirestore(), 'posts'),
      orderBy('timestamp', 'desc'),
    );

    return onSnapshot(
      postsQuery,
      snapshot => {
        const posts = snapshot.docs.map(document =>
          decodePost(
            document.id,
            document.data() as Record<string, unknown>,
          ),
        );
        onNext(posts);
      },
      error => onError(error),
    );
  }

  async createPost(input: CreatePostInput): Promise<string> {
    const reference = doc(collection(getFirestore(), 'posts'));
    await setDoc(reference, {
      title: input.title,
      content: input.content,
      category: input.category,
      languageCode: input.languageCode,
      languageName: input.languageName,
      uid: input.uid,
      username: input.username,
      nickname: input.nickname,
      images: [],
      likes: [],
      timestamp: serverTimestamp(),
    });
    return reference.id;
  }

  async getPost(postId: string): Promise<Post> {
    const snapshot = await getDoc(doc(getFirestore(), 'posts', postId));
    if (!snapshot.exists()) {
      throw new Error('帖子不存在或已被删除');
    }
    return decodePost(
      snapshot.id,
      snapshot.data() as Record<string, unknown>,
    );
  }
}

export const postRepository = new PostRepository();
