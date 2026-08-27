# Flutter 功能與架構地圖

## 整體架構

`lib/main.dart` 初始化 Firebase、以 `MultiProvider` 注入語言、Auth、Chat、Friend、Discover、Feed、Post 狀態，並以 `FirebaseAuth.authStateChanges()` 在 Login 與主導航之間切換。整體是 feature-first UI + 共用 data/shared 分層：

1. `features/*/screens|widgets`：畫面、互動；部分功能直接操作 Firebase（帖子建立、評論、vocab、profile）。
2. `features/*/providers`：ChangeNotifier 狀態與 loading/error；轉呼叫 repository/service。
3. `data/repositories`：Auth/Post/Chat/Discover 的薄封裝。
4. `shared/services`：Firebase Auth/Firestore/Storage 核心操作。
5. `data/models` 與 feature models：Firestore/Realtime Database 讀取模型。
6. `core`：theme、routing/constants/extensions；`config`：語言與 l10n；`shared/widgets`：post/user/loading 等共用 UI。

注意：此專案並非所有 feature 都嚴格走同一層。RN 遷移必須追實際 writer，而不能只照 repository 名稱或 generated model。

## 主要功能模組

| 模組 | 功能 | 主要入口/原始檔 |
|---|---|---|
| Auth | email/password 登入、註冊、登出、auth state、改密碼、密保、封禁檢查、儲存最多 5 個帳號提示 | `features/auth/*`, `data/repositories/auth_repository.dart`, `shared/services/auth_service.dart` |
| Home/語言頻道 | 主導航、語言頻道、推薦帖子、使用者偏好 | `features/home/*`, `config/forum_languages.dart`, `shared/providers/app_language.dart` |
| Feed/Post | 分類/語言 feed、建帖、多圖、詳情、編輯、刪除、like、deep link | `features/feed/*`, `data/models/post_model.dart`, `post_repository.dart`, `shared/services/post_service.dart`, `deep_link_service.dart` |
| Comments | 文字/圖片評論、巢狀回覆、emoji | `features/feed/screens/comment_screen.dart`, `comment_sheet.dart` |
| Profile | 個人/他人 profile、作者帖子、avatar、username/nickname/bio/tags/languages/birthday/showAge | `features/profile/*`, `profile_provider.dart`, `storage_service.dart` |
| Discover | 搜尋/列出其他使用者、開始私聊、發好友請求 | `features/discover/*`, `discover_repository.dart`, `discover_service.dart` |
| Social/Friends | 好友列表、邀請接受/拒絕、關係判斷 | `features/social/*`, `friend_provider.dart`, `friend_service.dart` |
| Chat | 私聊列表、未讀數、文字/圖片/詞彙訊息、翻譯 map、編輯、對自己/所有人刪除、emoji | `features/chat/*`, `chat_repository.dart`, `chat_service.dart` |
| Live draft | Realtime Database 輸入預覽、150ms debounce、onDisconnect 清理、member opt-in | `features/chat/services/live_draft_service.dart`, `models/live_draft.dart`, `chat_provider.dart` |
| Notes | 私人/共享 Quill 筆記、編輯權限、分享名單、inline 圖片、刪除 | `features/notes/*` |
| Admin | role 判斷、帖子/使用者統計、刪帖、封禁使用者 | `features/admin/*` |
| Localization | UI locale、語言 channel 清單、Glyphora language config | `config/l10n/*`, `config/forum_languages.dart`, `shared/providers/app_language.dart` |

## Model 清單

- `UserModel`：`id`, `username`, `email`, `displayName`, `photoUrl`, `nickname`, `avatar`, `bio`, `friends`, `friendRequests`, `tags`, `languages`, `birthday`, `showAge`, `createdAt`, `lastActive`。id 讀 `uid|id`，avatar 讀 `avatar|avatarUrl|photoUrl`；日期兼容 Timestamp/DateTime/string。
- `PostModel`：`id`, `userId`, `title`, `content`, `category`, `languageCode`, `imageUrls`, `likes`, `likeCount`, `commentCount`, `createdAt`, `updatedAt`。映射到 Firestore `uid`, `images`, `timestamp`。
- `CommentModel`：檔案存在但為空；實際字段由兩個 comment UI writer 定義。
- `ChatRoomModel`：`id`, `participants`, `lastMessage`, `lastMessageTime`, `createdAt`；generated JSON 使用 ISO string。這是舊/未對齊模型，實際 Firestore chat 使用 `users`, `updatedAt` 等。
- `ChatMessageModel`：`id`, `roomId`, `senderId`, `content`, `sentAt`, `read`；generated JSON 使用 ISO string。這是舊/未對齊模型，實際 messages schema 不同。
- `NoteModel`：`id`, `ownerId`, `participantIds`, `sharedUserIds`, `title`, `content`, `bodyDelta`, `allowOthersEdit`, `createdAt`, `updatedAt`, `updatedBy`。
- `UploadedNoteImage`：非獨立 domain model；`imageId`, `imageUrl`, `storagePath`。
- `LiveDraft`：`userId`, `text`, `updatedAt`（epoch milliseconds）。

## Repository / Provider / Service 職責

| 層 | 類別 | 職責/注意事項 |
|---|---|---|
| repository | `AuthRepository` | 組合 AuthService；註冊 user doc、ban 檢查、profile、密碼/密保、logout |
| repository | `PostRepository` | PostService 薄封裝；watch/create/get/edit/like/delete/image |
| repository | `ChatRepository` | ChatService 薄封裝；chat/message/未讀/刪除 |
| repository | `DiscoverRepository` | users stream、create chat、friend request |
| repository | `FriendRepository` | 空檔；好友功能直接用 FriendService |
| provider | `AuthProvider` | user/loading，login/register/load/update/changePassword/logout |
| provider | `FeedProvider` | feed loading/error 與 watch/create/get |
| provider | `PostProvider` | 單篇 edit/like/delete/image |
| provider | `ChatProvider` | chat 狀態；另直接寫 vocab messages/memberSettings，並轉呼叫 repository |
| provider | `FriendProvider` | 好友 UID stream/首次 load |
| provider | `DiscoverProvider` | discover loading/error 與 friend request |
| provider | `ProfileProvider` | 直接讀寫 Firestore profile 與作者帖子、Storage avatar |
| service | `AuthService` | Firebase Auth email/password、reauth/update password、users CRUD |
| service | `PostService` | posts query/write、Storage post images |
| service | `ChatService` | chats/messages、unread、圖片、編輯/軟刪/cleanup marker/preview |
| service | `FriendService` | fixed-ID requests、接受/拒絕、動態 map friends |
| service | `DiscoverService` | users query、deterministic chat、auto-ID request、userFriends existence check |
| service | `StorageService` | avatar upload/delete |
| service | `NoteService` | notes + images metadata + Storage |
| service | `LiveDraftService` | Realtime Database ephemeral drafts |
| service | `DeepLinkService` | 解析/open post link，讀 `posts/{postId}` |

## Authentication 流程

1. App 啟動監聽 `authStateChanges()`；有 Firebase user 就顯示主導航並呼叫 `AuthProvider.loadUser()`，否則 Login。
2. 註冊前 UI query `users.username`；再 `createUserWithEmailAndPassword`，取得原始 Auth UID，以 `users/{uid}.set(...)` 建 user doc。UID 不可重建或映射。
3. 登入以 `signInWithEmailAndPassword`，讀 `users/{uid}`；資料缺失報錯，`banned == true` 時立即 signOut；成功後 merge `lastLogin = serverTimestamp()`，並在 local SharedPreferences 保存帳號提示（不是 Firebase 契約）。
4. 登出呼叫 `FirebaseAuth.signOut()` 並清 provider user。
5. 改密碼先以目前 email/password 建 credential reauthenticate，再 `updatePassword()`。
6. 密保找回僅查 Firestore email、明文比對 answer；程式未呼叫 Auth password reset，因此不可誤認為完整重設流程。

## Backend Cleanup Job

聊天延遲物理清理已遷移到 `apps/api/src/jobs/cleanup_expired_chat_messages.ts`。部署平台的 Cron / Scheduler 負責定期執行 Node job，清理符合聊天刪除語義且 `cleanupAt` 到期的 message 及其 Storage 圖片，並維護 chat preview。RN message writer 必須維持 `status`, `hiddenFor`, `cleanupAt`, `imagePath`, `timestamp`，否則 cleanup/query/preview 會失效。
