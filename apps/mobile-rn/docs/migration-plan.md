# Flutter → React Native 分階段遷移計畫

## 不可變條件

- Flutter 專案 `forum-flutter` 永遠只讀。
- RN 使用現有 project `forum-3b899` 與現有 Authentication UID。
- collection/document/subcollection、字段名稱/類型、Storage path、Rules、Functions 不變。
- 不做一次性全專案移植；每階段先讀 Flutter writer/reader，再做 TypeScript contract、最小功能、雙端互通驗證。

## Phase 1：分析與契約（本次）

- 完成架構/功能/model/repository/provider/service 盤點。
- 完成 Firestore、Realtime Database、Auth、Storage、Functions 路徑與字段契約。
- 記錄 legacy/雙 schema、null/missing、Timestamp、map/array 等風險。
- 本階段不實作大量 UI、不修改 Firebase 結構或 Flutter。

交付：`firebase-contract.md`、`flutter-feature-map.md`、`data-compatibility-risks.md`、本計畫。

## Phase 2：RN Firebase 基礎層

1. 確認 Android `google-services.json` 的 project/app 配置與 `forum-3b899` 一致；iOS 若開發再確認既有 app 配置，不建立新 project。
2. 建立 TypeScript Firebase data layer：path constants、document types、runtime decoders、create/update encoders、Timestamp helpers。
3. 建立 auth session 層，監聽 auth state；不得自製 UID。
4. 以唯讀 smoke tests 驗證 users/posts，確認現行 Rules/indexes，不先寫 UI。

完成條件：能安全讀取含 null/missing/legacy 字段的 user/post，且沒有寫入。

## Phase 3：Authentication + User profile（最小垂直切片）

- email/password login/register/logout；register 精確建立 `users/{auth.uid}`。
- ban/user-doc 缺失處理、lastLogin server timestamp。
- 最小 profile 顯示；之後逐項加入 avatar、nickname/bio/tags/languages/birthday。
- 雙端驗證：Flutter 建立的帳號可 RN 登入；RN 同一帳號在 Flutter 顯示相同 UID/profile；avatar object 路徑不變。

## Phase 4：帖子與評論

- 先唯讀 feed/detail，再 like；之後 create/edit/delete 與 Storage 多圖。
- 分別重現實際 create_post writer 與必要 PostService 更新語義，不合併字段。
- 加入 comments/replies，最後才加圖片評論。
- 雙端驗證所有 Timestamp、images URLs、likes arrays、legacy posts。

## Phase 5：好友與 Discover

- 先呈現 requests/friends，辨識線上資料實際使用 fixed-ID 或 auto-ID 流程。
- 逐一移植 send/accept/reject/isFriend；不遷移三種好友表示。
- 在確定線上 writer/Rules 前，不由 RN 自動雙寫任何 friends representation。

## Phase 6：聊天

- deterministic chat ID、chat list/unread。
- text/image messages；嚴格維持 null 字段、timestamp、imagePath。
- message edit、hide-for-me、delete-for-everyone 與 7-day cleanupAt。
- vocab message另做獨立 encoder，先驗證現有 `createdAt` vs `timestamp` 行為。
- memberSettings + Realtime Database live draft 最後加入。
- 雙端與 scheduled Function 驗證，避免測試資料觸發非預期物理刪除。

## Phase 7：共享筆記

- notes list/read → create/edit → permission/share → inline images/delete。
- 保留 Quill Delta array/map；RN editor 若不同，必須能無損 round-trip，而不是只保存 plain text。
- 驗證 Firestore metadata 與 Storage object 同步刪除行為。

## Phase 8：Admin、深連結與完整性

- role/banned admin 行為、stats、post/user 管理。
- post deep links、本地化與推薦/偏好。
- 全模組 contract regression、Rules denied cases、offline/pending timestamp、跨端 smoke suite。

## 每個階段的驗收模板

1. 列出該功能讀/寫的精確 path 與 payload。
2. 使用 Flutter 原始檔逐字段複核。
3. 測試 RN 讀 Flutter 資料、Flutter 讀 RN 資料。
4. 測試 missing、null、legacy alias、pending server timestamp。
5. 測試 Rules 拒絕未授權 UID/path；不修改 Rules 來讓測試通過。
6. 確認 Storage object path 與 Functions 依賴字段。
7. 僅在該垂直切片通過後進下一功能。

