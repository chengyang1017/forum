# 万文社整体架构

## 1. 项目定位

万文社是一个以语言交流为核心，同时结合社区、聊天、笔记、翻译等功能的 Flutter 应用。

英文名称：

```text
Glyphora
```

中文名称：

```text
万文社
```

越南语名称：

```text
Vạn Văn Xã
```

项目目前主要使用：

```text
Flutter
Firebase Authentication
Cloud Firestore
Firebase Realtime Database
Firebase Storage
Cloud Functions
```

同时逐渐将可以复用的数据和能力拆分为独立底层库。

---

# 2. 总体分层

当前项目整体遵循 Feature First 思路。

大致结构：

```text
lib/
├─ app/
│
├─ core/
│
└─ features/
   ├─ auth/
   ├─ post/
   ├─ chat/
   ├─ notes/
   ├─ profile/
   ├─ language/
   ├─ translation/
   └─ ...
```

不同业务功能放入不同 feature。

一个 feature 内部根据复杂度进一步划分：

```text
feature/
├─ data/
├─ domain/
└─ presentation/
```

---

# 3. 各层职责

## presentation

负责：

- 页面
- Widget
- 用户交互
- UI 状态展示
- 调用业务层

例如：

```text
AllNotesScreen
NoteEditorScreen
CreatePostScreen
ChatRoomScreen
```

---

## domain

负责业务模型和领域规则。

例如：

```text
NoteModel
PostModel
```

Domain 不应该负责具体 UI。

---

## data

负责：

- Firebase
- API
- Repository
- Service
- 数据转换

例如：

```text
NoteService
ChatService
```

---

# 4. 推荐调用方向

页面不要直接承担全部数据逻辑。

推荐：

```text
UI
↓
Provider / Controller
↓
Repository
↓
Service
↓
Firebase / API
```

简单功能目前可以：

```text
UI
↓
Service
↓
Firebase
```

当功能复杂度增加时，再逐渐抽出 Provider 和 Repository。

---

# 5. 语言数据架构

语言相关数据不应该散落在各个业务页面中。

统一方向：

```text
glyphora_language_core
        ↓
ForumLanguages
        ↓
论坛业务
```

其中：

## glyphora_language_core

负责通用语言知识：

- language code
- language names
- country
- flag
- script
- variant
- language-country relationship

不包含论坛业务逻辑。

---

## ForumLanguages

负责万文社实际支持的语言集合。

例如：

```dart
ForumLanguages.supportedLanguages
```

页面不应该再次建立自己的：

```dart
Map<String, String> languageFlags
```

或：

```dart
Map<String, String> languageNames
```

---

# 6. 帖子架构

基本流程：

```text
CreatePostScreen
↓
Post data
↓
Firestore posts
↓
Post list
↓
Post detail
```

帖子拥有：

- 作者
- 标题
- 内容
- 分类
- 主语言
- 可用语言
- 图片
- 点赞
- 评论
- 创建时间

帖子是万文社主要公开内容。

---

# 7. 聊天架构

聊天主要数据：

```text
chats
└─ messages
```

聊天房间保存：

- participantIds
- participantNames
- lastMessage
- lastMessageAt
- lastSenderId
- updatedAt

消息保存在：

```text
chats/{chatId}/messages
```

---

# 8. 笔记架构

笔记是当前项目中连接多个功能的重要中间层。

```text
聊天
  ↓
笔记
  ↓
整理内容
  ↓
翻译
  ↓
帖子
```

笔记可以：

- 私人使用
- 与其他用户共享
- 允许其他参与者编辑
- 保存富文本
- 保存图片
- 保存翻译结果
- 设置语言
- 设置帖子分类
- 发布为帖子

---

# 9. 翻译架构

翻译不是独立于内容系统之外的功能。

目标关系：

```text
原帖子
↓
翻译
├─ 直接发布
└─ 保存笔记
      ↓
   继续修改
      ↓
   发布帖子
```

因此翻译保存到笔记时需要保存来源信息：

```text
sourceType
sourceId
```

---

# 10. Firebase 当前角色

Firebase 当前主要负责：

## Authentication

用户身份。

## Firestore

主要业务数据：

```text
users
posts
chats
notes
notifications
```

## Realtime Database

适合高频临时状态。

当前例如：

```text
chatDrafts
```

## Storage

图片等文件。

## Cloud Functions

服务端任务。

例如：

```text
聊天消息延迟清理
```

---

# 11. 长期架构方向

当前 Firebase 是主要后端。

但是业务层应该尽量避免把 Firebase API 深度写死到所有 UI 中。

理想方向：

```text
UI
↓
业务接口
↓
Repository
↓
Firebase Repository
```

未来如果迁移后端：

```text
Firebase Repository
```

可以逐步替换为：

```text
REST Repository
Serverpod Repository
自建 Backend Repository
```

而不是重新修改整个 UI。

---

# 12. 架构原则

项目长期遵循以下原则：

### 单一数据源

语言、分类等公共数据尽量只有一个正式来源。

### Feature First

业务按照功能划分，而不是把所有 screen、model、service 混在一起。

### UI 不承担数据库职责

页面只负责使用数据，而不是成为整个业务系统。

### 公共能力逐渐抽离

例如：

```text
glyphora_language_core
```

可以同时供：

```text
Flutter
React Native
Kotlin
Web
```

使用。

### 保持可迁移性

Firebase 是实现方式，而不是业务模型本身。
