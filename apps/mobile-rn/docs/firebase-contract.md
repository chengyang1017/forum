# 萬文社 Firebase 資料契約（Flutter 現況）

> 分析基準：`forum-flutter/lib` 與 `forum-flutter/functions`。本文件描述既有資料，不是新 schema。RN 必須連接既有 Firebase project `forum-3b899`，不得建立新 project、改名字段或搬移路徑。Firestore 文件 ID 在下表獨立列出，不可誤寫成普通字段。

## 共通序列化規則

- Authentication UID 是身份主鍵：`users/{uid}` 的 document ID、`users.uid`、帖子/評論的 `uid`、聊天的 `users[]`/`senderId`、好友字段、筆記 owner/participant 字段均使用相同 UID。
- Firestore `Timestamp` 必須在 RN 保持為 Firebase Timestamp；新建/更新時間使用 `serverTimestamp()`，不要寫 JS `Date`、ISO string 或毫秒 number（Realtime Database 草稿例外）。
- `serverTimestamp()` 在本地 pending snapshot 可能暫時為 `null`；reader 必須容許 `null`、缺失字段及舊資料 fallback。
- Flutter 沒有把任何 `DocumentReference` 存入字段。`DocumentReference` 僅用於操作 `notes/{noteId}` 等路徑；RN 不得把 path string 或 reference 新增為持久字段。
- `null` 與字段缺失不同：聊天訊息刻意建立多個 `null` 字段；profile 的 `birthday`、空 nickname 會用 `FieldValue.delete()` 移除字段。RN 更新時需維持各操作的原語義。

## Collection / path 索引

- Top-level Firestore collections：`users`、`posts`、`friend_requests`、`friends`、`chats`、`notes`。
- Firestore subcollections：`posts/{postId}/comments`、`posts/{postId}/comments/{commentId}/replies`、`friends/{uid}/userFriends`、`chats/{chatId}/messages`、`chats/{chatId}/memberSettings`、`notes/{noteId}/images`。
- Realtime Database root：`chatDrafts/{chatId}/{uid}`。
- Functions 另以 collection group `messages` 查詢，但只處理父文件位於 `chats` 的訊息。

## `users`

路徑：`users/{uid}`；`{uid}` 必須等於 Firebase Authentication UID。

| 字段 | Firestore 類型 | 必填性/預設 | 說明 |
|---|---|---|---|
| `uid` | string | 新註冊必填；舊文件可能缺失 | 等於 doc ID/Auth UID |
| `username` | string | 新註冊必填；reader 預設 `''` | 唯一性由客戶端 query 檢查 |
| `email` | string | 新註冊必填；舊資料可選 | Auth email 的鏡像 |
| `displayName` | string | 新註冊必填；可選/舊字段 | 初始為 username |
| `photoUrl` | string 或 null | 新註冊寫 null；可選/舊字段 | avatar fallback |
| `nickname` | string | 可選；空值更新時可刪除字段 | 顯示名優先級最高 |
| `avatar` | string | 可選 | Storage download URL；reader 亦兼容 `avatarUrl`/`photoUrl` |
| `avatarUrl` | string | 僅舊資料兼容，可選 | reader alias，不是目前 writer 字段 |
| `bio` | string 或 null | 新註冊寫 null；可選 | profile 更新通常寫 string |
| `friends` | array<string> | 新註冊寫 `[]`；可選 | UserModel 舊式字段；主要好友服務另用 `friends` collection |
| `friendRequests` | array<string> | 新註冊寫 `[]`；可選 | UserModel 舊式字段 |
| `interests` | array<string> | 可選，初始可能缺失 | 推薦偏好；元素格式 `{languageCode}::{categoryId}`，以 arrayUnion/arrayRemove 更新 |
| `tags` | array<string> | 可選 | 個人標籤 |
| `languages` | array<map> | 可選 | 每項通常 `{name: string, level: number}`；舊資料可為 string，Flutter reader 轉成 level 70 |
| `birthday` | Timestamp | 可選/可缺失 | 清除生日使用 field delete |
| `showAge` | boolean | 可選，reader 預設 true | 年齡顯示設定 |
| `createdAt` | Timestamp | 新註冊必填（server timestamp） | reader 兼容 DateTime/string，但 RN 不應製造異型 |
| `lastActive` | Timestamp | 新註冊必填（server timestamp） | 活躍時間 |
| `lastLogin` | Timestamp | 可選 | 每次成功登入後 merge 寫入 |
| `banned` | boolean | 新註冊必填，false | true 時 login/getCurrentUser 會登出 |
| `role` | string | 新註冊必填，`user` | `admin` 啟用管理功能 |
| `securityQuestion` | string | 可選 | 密保問題 |
| `securityAnswer` | string | 可選 | 目前以明文比較，屬既有高風險設計 |

來源：`lib/data/models/user_model.dart`、`user_model.g.dart`、`lib/data/repositories/auth_repository.dart`、`lib/shared/services/auth_service.dart`、`lib/features/profile/providers/profile_provider.dart`、`lib/features/profile/screens/security_settings_screen.dart`、`lib/features/auth/screens/login_screen.dart`、`lib/features/admin/admin_service.dart`、`lib/features/home/screens/home_tab.dart`、`recommended_posts_view.dart`。

## `posts`

路徑：`posts/{postId}`；`postId` 為 auto ID。建立畫面先取 doc ID，以上傳同 ID 路徑的圖片。

| 字段 | 類型 | 必填性/預設 | 說明 |
|---|---|---|---|
| `uid` | string | 必填 | 作者 Auth UID；舊 reader 兼容 `userId` |
| `title` | string | UI 建立流程必填；service 建立流程可能缺失 | 標題 |
| `content` | string | 必填 | 內容 |
| `category` | string | 必填 | 頻道分類 |
| `languageCode` | string | 現行必填；舊文可能缺失 | 如 `zh`, `en`, `vi`；一次性 updater 為舊文補 `zh` |
| `languageName` | string | UI 建立流程必填；service 流程可能缺失 | 顯示語言名；updater 可補中文名 |
| `username` | string | UI 建立流程寫入；可選 | 作者名稱快照，profile 更新時會同步 |
| `nickname` | string | UI 建立流程寫入；可選/可刪除 | 作者暱稱快照 |
| `images` | array<string> | 現行 writer 寫 array；可為 `[]` | Storage download URLs |
| `likes` | array<string> | 現行 writer 寫 `[]` | 點讚者 UID；arrayUnion/arrayRemove |
| `likeCount` | number (integer) | service 流程寫 0；UI 流程可能缺失 | model 預設 0；現行 toggleLike 不同步此字段 |
| `commentCount` | number (integer) | service 流程寫 0；UI 流程可能缺失 | model 預設 0；評論 writer 未同步此字段 |
| `timestamp` | Timestamp | 必填（server timestamp） | 主要建立/排序時間；model 的 `createdAt` 映射到此字段 |
| `createdAt` | Timestamp | 僅 reader fallback，可選/舊字段 | `timestamp` 缺失時讀取 |
| `updatedAt` | Timestamp | 可選 | model 支援；現行 content edit 不寫它 |
| `editedAt` | Timestamp | 可選 | 編輯 content 時 server timestamp |

來源：`lib/data/models/post_model.dart`、`lib/shared/services/post_service.dart`、`lib/features/feed/screens/create_post_screen.dart`、`lib/features/profile/providers/profile_provider.dart`、`lib/shared/utils/post_updater.dart`。

### 評論與回覆

評論路徑：`posts/{postId}/comments/{commentId}`；回覆路徑：`posts/{postId}/comments/{commentId}/replies/{replyId}`；皆為 auto ID。

| 文件 | 字段 | 類型 | 必填性/說明 |
|---|---|---|---|
| comment | `text` | string | 必填，可為 `''`（圖片評論） |
| comment | `uid` | string | writer 一律寫入；未登入時現有程式會寫 `''` |
| comment | `user` | string | 必填；不同 UI 分別寫完整 email、email 前綴或 `Guest` |
| comment | `imageUrl` | string | 僅圖片評論，可選 |
| comment | `timestamp` | Timestamp | server timestamp，必填 |
| reply | `text` | string | 必填 |
| reply | `uid` | string | writer 一律寫入 |
| reply | `user` | string | 必填 |
| reply | `replyTo` | string | 必填但可為 `''`；存顯示名，不是 UID/reference |
| reply | `timestamp` | Timestamp | server timestamp，必填 |

`comment_model.dart` 是空檔，實際契約來自 `lib/features/feed/screens/comment_screen.dart` 與 `comment_sheet.dart`。

## 好友

### `friend_requests/{requestId}`

存在兩種既有 ID/時間契約，RN 必須兼讀，且選定操作時重現相應流程，不能合併 schema：

| 字段 | 類型 | 必填性/說明 |
|---|---|---|
| `from` | string | 必填，發送者 UID |
| `to` | string | 必填，接收者 UID |
| `status` | string | 必填：`pending` / `accepted` / `rejected` |
| `timestamp` | Timestamp | `FriendService` 固定 ID 流程使用 |
| `createdAt` | Timestamp | `DiscoverService` auto ID 流程使用 |
| `updatedAt` | Timestamp | `DiscoverService` auto ID 流程使用 |

固定 ID 是 `{fromUid}_{toUid}`；另一流程使用 auto ID。來源：`lib/shared/services/friend_service.dart`、`discover_service.dart`。

### `friends/{uid}` 與舊/替代子集合

- 主要 `FriendService` 使用 `friends/{uid}`，document 是動態 map：每個 key 是好友 UID、value 是 boolean `true`。不存在固定字段清單。
- `DiscoverService` 的好友存在檢查使用 `friends/{currentUid}/userFriends/{targetUid}`，但在分析範圍內沒有建立此子集合的 writer；必須視為既有/外部流程，不能自行改成另一形式。
- `users/{uid}.friends` 另有 array<string> 舊字段。三者不可互相覆寫或自動遷移。

## 聊天與訊息

聊天路徑：`chats/{chatId}`；私聊 ID 為兩個 UID 字典排序後以 `_` 連接：`{lowerUid}_{higherUid}`。

| 聊天字段 | 類型 | 必填性/說明 |
|---|---|---|
| `users` | array<string> | 必填，兩位參與者 UID；舊 `ChatRoomModel.participants` 不符合實際 writer |
| `createdAt` | Timestamp | 建立時 server timestamp |
| `updatedAt` | Timestamp | 建立及每次預覽更新時 server timestamp/訊息 timestamp |
| `lastMessage` | string | 必填，可為 `''`；文字、`[圖片]`、`[單詞] word` 或刪除預覽 |
| `lastMessageId` | string 或 null | 現行 ChatService 建立時 null；DiscoverService 舊流程可能缺失 |
| `lastSenderId` | string 或 null | 現行建立時 null；vocab/訊息更新寫 sender UID |
| `lastMessageAt` | Timestamp | vocab provider 使用；與主要 `updatedAt` 並存的可選字段 |
| `unreadCount` | map<string, number> | UID 為動態 key，值為 integer；發送者 0、其他人 increment |

訊息路徑：`chats/{chatId}/messages/{messageId}`，auto ID。

| 訊息字段 | 類型 | 必填性/說明 |
|---|---|---|
| `type` | string | 一般必填：`text` / `image`；另有 `vocab` |
| `senderId` | string | 必填 Auth UID |
| `content` | string | text/image writer 必填（image 為 `''`）；vocab 可能缺失 |
| `imageUrl` | string 或 null | text 為 null，image 為 download URL；vocab 可能缺失 |
| `imagePath` | string 或 null | Storage full path；text 為 null；舊圖片可能缺失 |
| `timestamp` | Timestamp | text/image 的 server timestamp；主要排序字段 |
| `createdAt` | Timestamp | vocab 使用的 server timestamp；與 `timestamp` 不同 |
| `editedAt` | Timestamp 或 null | text/image 初始 null；編輯時 server timestamp |
| `hiddenFor` | array<string> | text/image 初始 `[]`；每位隱藏者 UID；vocab 可能缺失 |
| `status` | string | `active` / `deleted`；vocab 可能缺失，reader 預設 active |
| `deletedBy` | string 或 null | 全部刪除時 sender UID |
| `deletedAt` | Timestamp 或 null | 全部刪除時 server timestamp |
| `cleanupAt` | Timestamp 或 null/缺失 | 物理清理排程；全部隱藏或全部刪除後設為 UTC now+7 天 |
| `word` | string | vocab 必填 |
| `languageCode` | string 或 null/缺失 | vocab 可選 |
| `translations` | map<string,string> | vocab 必填 map；動態 UID key 對應翻譯 |

member 設定路徑：`chats/{chatId}/memberSettings/{uid}`，字段 `shareLiveDraft: boolean`，merge 寫入。

來源：`lib/shared/services/chat_service.dart`、`lib/features/chat/providers/chat_provider.dart`、`lib/features/chat/screens/chat_screen.dart`、`functions/index.js`。`data/models/chat_model*.dart` 與 `chat_message_model*.dart` 使用 `participants`、ISO string 日期、`roomId/content/sentAt/read`，未被目前 ChatService writer 採用，不能作為實際 Firestore 契約。

## 筆記

路徑：`notes/{noteId}`，auto ID。

| 字段 | 類型 | 必填性/說明 |
|---|---|---|
| `ownerId` | string | 必填，建立者 Auth UID |
| `participantIds` | array<string> | 必填，owner + shared users；查詢使用 arrayContains |
| `sharedUserIds` | array<string> | 必填，可 `[]`，不包含 owner |
| `title` | string | 必填，可 `''` |
| `content` | string | 必填，可 `''`，純文字表示 |
| `bodyDelta` | array<map> | 必填，Flutter Quill delta ops；初始為 `[{insert: '\n'}]`，map 內可含 `insert` 及格式 attributes |
| `allowOthersEdit` | boolean | 必填，初始 false |
| `createdAt` | Timestamp | server timestamp，必填 |
| `updatedAt` | Timestamp | server timestamp，必填；reader 可 fallback createdAt |
| `updatedBy` | string | 必填，最後修改者 UID |

圖片 metadata 路徑：`notes/{noteId}/images/{imageId}`，auto ID。

| 字段 | 類型 | 必填性 |
|---|---|---|
| `url` | string | 必填，download URL |
| `storagePath` | string | 必填，對應 Storage object |
| `uploaderId` | string | 必填，Auth UID |
| `createdAt` | Timestamp | server timestamp，必填 |

來源：`lib/features/notes/models/note_model.dart`、`lib/features/notes/services/note_service.dart`、`lib/features/notes/screens/note_editor_screen.dart`。

## Realtime Database：即時草稿

路徑：`chatDrafts/{chatId}/{uid}`。值為 map：`text: string`、`updatedAt: number`（Realtime Database `ServerValue.timestamp` 的 epoch milliseconds）。`uid` 來自 Auth；onDisconnect/remove 與輸入清空都會刪除此節點。這不是 Firestore Timestamp。

來源：`lib/features/chat/services/live_draft_service.dart`、`models/live_draft.dart`。

## Firebase Storage 路徑

| 功能 | 精確路徑規則 | Firestore 關聯 |
|---|---|---|
| avatar | `avatars/{uid}.jpg` | `users/{uid}.avatar` download URL |
| 建帖畫面圖片 | `posts/{postId}/{index}.jpg` | `posts/{postId}.images[]` |
| PostService 圖片 | `posts/{postId}/{epochMs}_{originalName}` | `posts/{postId}.images[]` |
| 圖片評論 | `comment_images/{epochMs}.jpg` | comment `imageUrl`；路徑不含 UID/post ID |
| 聊天圖片 | `chat_images/{senderUid}/{epochMs}.jpg` | message `imageUrl` + `imagePath` |
| 筆記圖片 | `note_images/{noteId}/{imageId}.{jpg|jpeg|png|webp}` | note image metadata `url` + `storagePath` |

刪除策略：post 刪除/移圖以 download URL `refFromURL` 刪 object；avatar 更新先刪舊 URL；note 刪除先 batch 刪 metadata/note 再逐個刪 Storage；chat 圖片由排程依 `imagePath` 或從 URL 解析後刪除。

## Rules 與 Functions 邊界

- repository 中沒有 `.rules` 檔案；`firebase.json` 沒有 `firestore.rules`/`storage.rules` 宣告。既有部署端 Firestore Rules、Storage Rules 必須原封不動沿用，但本地分析無法確認其內容。
- 唯一 Cloud Function 是 v2 scheduled `cleanupExpiredChatMessages`：region `asia-southeast1`、timezone `Asia/Kuala_Lumpur`、每 60 分鐘、每批 200。以 collection group `messages` 查 `cleanupAt <= Timestamp.now()`，只接受父路徑為 `chats/{chatId}`；僅在 `status == deleted` 或所有 chat users 都在 `hiddenFor` 時物理刪除，先刪圖片，再刪 message，必要時重算 chat preview；偽造 cleanupAt 會被移除。
