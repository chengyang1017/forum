# Flutter 功能與架構地圖

## 整體架構

`lib/main.dart` 初始化 Firebase、建立 `AppDependencies`，再以 `MultiProvider` 注入語言、Auth、Chat、Friend、Discover、Feed、Post 等狀態與 repository。整體仍是 feature-first，但 Post、Profile、Social、Chat 等核心功能已逐步改成由 application composition root 注入抽象依賴，而不是讓 presentation 直接依賴 Firebase 型別。

1. `features/*/presentation`：畫面、互動與狀態。
2. `features/*/domain`：domain model 與 repository contract。
3. `features/*/application`：跨資料來源或平台能力的 port，例如 media storage。
4. `features/*/data`：Firebase/HTTP 等具體 adapter 與 service。
5. `app/di/app_dependencies.dart`：組合長生命週期依賴並注入 feature。
6. `core` 與 `app`：routing、l10n、共用 service/widget 等。

注意：此專案仍在漸進式重構中，不是所有 feature 都已完全切到同一架構。RN 遷移必須追實際 writer 與 repository contract，不能只照舊 generated model。

## 主要功能模組

| 模組 | 功能 | 主要入口/原始檔 |
|---|---|---|
| Auth | email/password 登入、註冊、登出、auth state、改密碼、密保、封禁檢查、儲存最多 5 個帳號提示 | `features/auth/*` |
| Home/語言頻道 | 主導航、語言頻道、推薦帖子、使用者偏好 | `features/home/*`, `features/language/*`, `app/providers/app_language.dart` |
| Feed/Post | 分類/語言 feed、建帖、多圖、詳情、編輯、刪除、like、deep link | `features/feed/*`, `features/post/*`, `core/services/deep_link_service.dart` |
| Comments | 文字/圖片評論、巢狀回覆、emoji | `features/post/*` |
| Profile | 個人/他人 profile、作者帖子、avatar、username/nickname/bio/tags/languages/birthday/showAge | `features/profile/*` |
| Discover | 搜尋/列出其他使用者、開始私聊、發好友請求 | `features/discover/*` |
| Social/Friends | 好友列表、邀請接受/拒絕、關係判斷 | `features/social/*` |
| Chat | 私聊列表、未讀數、文字/圖片/詞彙訊息、翻譯 map、編輯、對自己/所有人刪除、emoji | `features/chat/domain/repositories/chat_repository.dart`, `features/chat/data/repositories/chat_repository_impl.dart`, `features/chat/presentation/*` |
| Live draft | Realtime Database 輸入預覽、150ms debounce、onDisconnect 清理、member opt-in | `features/chat/domain/repositories/live_draft_repository.dart`, `features/chat/data/repositories/firebase_live_draft_repository.dart`, `features/chat/domain/models/live_draft.dart` |
| Notes | 私人/共享 Quill 筆記、編輯權限、分享名單、inline 圖片、刪除 | `features/notes/*` |
| Admin | role 判斷、帖子/使用者統計、刪帖、封禁使用者 | `features/admin/*` |
| Localization | UI locale、語言 channel 清單、Glyphora language config | `app/l10n/*`, `features/language/*`, `app/providers/app_language.dart` |

## Model 清單

- `UserModel`：使用者基本資料與 profile 資訊。
- `PostModel`：帖子內容、語言、圖片、互動計數與時間資訊。
- `CommentModel`：目前仍有舊空檔；實際評論資料由現行 comment writer/reader 決定。
- `ChatThread`：聊天室 domain model；使用 `participantIds`, `lastMessage`, `updatedAt`, `unreadCountByUser`，不暴露 Firestore snapshot。
- `ChatMessage`：訊息 domain model；包含 `type`, `senderId`, `content`, `imageUrl`, `word`, `timestamp`, `editedAt`, `hiddenFor`, `status` 等目前 UI 所需欄位。
- `NoteModel`：筆記 owner、共享使用者、Quill delta、權限與時間資訊。
- `UploadedNoteImage`：非獨立 domain model；保存 image metadata。
- `LiveDraft`：`userId`, `text`, `updatedAt`（epoch milliseconds）。

## Repository / Provider / Service 職責

| 層 | 類別 | 職責/注意事項 |
|---|---|---|
| repository | `AuthRepository` | 組合 AuthService；註冊 user doc、ban 檢查、profile、密碼/密保、logout |
| repository | `PostRepository` | Post domain contract；具體 Firebase/Node 存取由 data adapter 處理 |
| repository | `ChatRepository` | typed chat contract；聊天室、訊息、未讀、詞彙訊息、member settings；Firebase snapshot/timestamp 不越過此 boundary |
| repository | `LiveDraftRepository` | realtime draft contract；prepare/watch/update/clear，不暴露 Firebase Database 型別 |
| repository | `FriendRepository` | 好友關係 contract；presentation/provider 依賴抽象 |
| provider | `FeedProvider` | feed loading/error 與帖子 stream |
| provider | `PostProvider` | 單篇 edit/like/delete/image 等 UI 狀態 |
| provider | `ChatProvider` | chat UI state 與 orchestration；透過 `ChatRepository` / `ChatMediaRepository` 工作 |
| provider | `FriendProvider` | 好友 UID stream/首次 load |
| provider | `DiscoverProvider` | discover loading/error 與 friend request |
| provider | `ProfileProvider` | profile UI 狀態；逐步改由 repository/media port 提供資料 |
| data | `ChatRepositoryImpl` | 把 ChatService/Firestore 資料轉成 `ChatThread`、`ChatMessage`，並實作 vocab/member-setting 寫入 |
| data | `FirebaseLiveDraftRepository` | Realtime Database adapter；維持 150ms debounce、onDisconnect/remove 與 draft sorting |
| service | `ChatService` | Firestore chats/messages、unread、編輯/軟刪/cleanup marker/preview 等底層操作 |
| service | `DeepLinkService` | 解析/open post link |

## Authentication 流程

1. App 啟動後載入 Auth state；有 Firebase user 就進入主導航，否則顯示 Login。
2. 註冊建立 Firebase Auth user，再以 Auth UID 建立 `users/{uid}` 文件。
3. 登入後讀取 user profile；若封禁則登出。
4. 登出呼叫 Firebase Auth sign out 並清除本地狀態。
5. 改密碼需要 reauthenticate 後再 update password。
6. 密保流程與 Firebase Auth password reset 是不同機制，不可混為一談。

## Backend Cleanup Job

聊天延遲物理清理位於 `apps/api/src/jobs/cleanup_expired_chat_messages.ts`。部署平台的 Cron / Scheduler 負責定期執行 Node job，清理符合聊天刪除語義且 `cleanupAt` 到期的 message 及其 Storage 圖片，並維護 chat preview。RN message writer 必須維持 `status`, `hiddenFor`, `cleanupAt`, `imagePath`, `timestamp` 等契約，否則 cleanup/query/preview 會失效。
