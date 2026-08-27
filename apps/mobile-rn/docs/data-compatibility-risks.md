# Flutter ↔ React Native 資料相容風險

## 最高優先級

1. **時間型別分裂**：Firestore 時間必須是 `Timestamp`/`serverTimestamp()`；舊 chat generated models 卻宣告 ISO string，而 Realtime Database draft 的 `updatedAt` 是 epoch milliseconds。RN 必須按資料庫/字段分開 converter，不能共用 `Date|string|number` writer。
2. **聊天有兩個訊息 shape**：text/image 用 `timestamp`，vocab 用 `createdAt`；目前 message query 只 orderBy `timestamp`，vocab 文件可能排序異常或被排除。遷移階段只能兼讀，不能擅自補/改 schema；應先以真實資料與 rules 驗證現況。
3. **舊 chat models 不代表實際資料**：`participants`, `lastMessageTime`, `roomId`, `sentAt`, `read` 與實際 `users`, `updatedAt`, `timestamp`, `status` 不一致。若 RN 照 generated models 寫入，Flutter 查詢與 Functions 會失效。
4. **好友存在三種表示**：`friends/{uid}` 動態 boolean map、`friends/{uid}/userFriends/{friendUid}` 子集合、`users/{uid}.friends[]`。不得統一、搬移或雙寫，需逐一確認畫面所依賴的表示。
5. **兩套 friend request ID/時間字段**：fixed `{from}_{to}` + `timestamp` 與 auto ID + `createdAt/updatedAt`。接受/拒絕流程假設 fixed ID，Discover 發送卻可建立 auto ID，可能造成更新不到文件或重複邀請。
6. **null 與缺失字段**：chat text/image 初始化明確寫 `imageUrl: null` 等；vocab 多數字段缺失；birthday/nickname 用 field delete。RN TypeScript interface 的 `foo?: T` 與 `foo: T|null` 必須區分，更新 payload 不可把 `undefined` 送進 Firestore。
7. **serverTimestamp pending 值**：立即讀回可能是 null。RN listener 應把 Timestamp 設為 nullable，並選定 snapshot server timestamp 行為；UI 不可直接呼叫 `.toDate()`。
8. **動態 map key**：`unreadCount.{uid}`, `translations.{uid}`, `friends/{uid}` 的 UID 是字段 key。RN 需用 `Record<string, number|string|boolean>`；更新 dot path 時需確認 UID 不含非法 path 語義，且不可把整張 map 誤覆蓋。

## 中高風險

- **帖子建立流程不同**：UI writer 寫 title/languageName/username/nickname 但不寫 count；PostService writer 寫 counts 但不寫 title/languageName/作者快照。RN reader 應容許缺失，writer 必須選定與要遷移的 Flutter 操作相同 payload。
- **字段 alias 只供讀取**：User `avatarUrl/photoUrl`、Post `userId/createdAt` 是 legacy fallback。RN 不應把 alias 當新主字段雙寫。
- **計數可能不可信**：likes 操作只更新 `likes[]`，沒有同步 `likeCount`；評論 writer沒有同步 `commentCount`。顯示時要遵循 Flutter fallback/現況，不可擅自建立 counter 邏輯。
- **Firestore number 在 TypeScript 都是 `number`**：`likeCount`, `commentCount`, `unreadCount` 語義是 integer；讀取需檢查 finite/integer 或採安全 fallback，避免字串/NaN。
- **arrays/maps 深層內容**：`languages` 是 array of map，舊項目可能只是 string；`bodyDelta` 是 Quill operation map array，可能含嵌套 attributes/embed。不得 JSON stringify 後存 string。
- **推薦 interest key 是複合字串**：`users.interests[]` 的元素是 `{languageCode}::{categoryId}`，不是 map；不得拆欄、改 delimiter 或只存 category。
- **DocumentReference**：現況未持久化 reference。RN SDK 的 DocumentReference 不能轉成 path string寫入；若遇到線上舊資料 reference，先記錄再決定兼容策略。
- **Storage URL 不是 path**：chat/note 同時保留 download URL 和 full path；Cloud Function 優先用 `imagePath`。不可將 URL 填到 `imagePath`，也不可自行 decode token 後改名 object。
- **Storage 命名碰撞**：comment image 只用 epoch ms；chat image只用 UID+epoch ms；avatar固定覆寫。RN 必須沿用精確路徑，但應避免同毫秒重複上傳。
- **副檔名/contentType**：avatar/post/comment/chat 固定 `.jpg`，但來源可能非 JPEG；notes 才根據 jpg/jpeg/png/webp 設 metadata。改變編碼或 suffix 可能影響 Rules/content rendering。
- **Auth UID 不可替代**：不要以 email、username、RN 本地 ID 取代 UID，也不要在 RN 重新註冊既有帳號；登入相同 project 才能取得相同 UID。
- **username 唯一性非 transaction/rule 證據**：目前先 query 再 create/update，有競態條件。RN 只能沿用行為，除非後續另有明確 schema/rules 變更授權。
- **securityAnswer 明文**：這是既有安全風險。RN 不應在 client log、analytics 或 error 中洩漏；本階段不改 schema。
- **Rules 不在 repo**：無法離線驗證 collection/Storage 權限。任何 RN 寫入前都應在同 project 的開發帳號上用最小操作驗證；不可部署新 rules 覆蓋現況。

## 建議的 RN 邊界（不改資料）

- 每個 document 建立 `decodeX(snapshot)` 與 `encodeXCreate/encodeXUpdate`，不要直接 spread domain object 進 Firestore。
- decode 明確處理：missing、null、Timestamp、array item type、map、legacy alias；保留 document ID 與 data 字段的區別。
- create/update payload 分離；使用 `serverTimestamp`, `arrayUnion`, `arrayRemove`, `increment`, `deleteField` 等 RN Firebase sentinel。
- 為每條 path 建 contract fixture：現行、缺失字段、明確 null、舊 alias、pending timestamp、錯誤型別。
- Storage 上傳回傳 `{downloadUrl, fullPath}`，由各功能按既有 schema 選擇保存字段。
- 在動工前從 Firebase Console/已授權環境取得現行 Rules 與必要 composite indexes 的唯讀副本比對；不可部署修改。
