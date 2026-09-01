# 万文社 / Glyphora

> A multilingual social community built with Flutter, Node.js, PostgreSQL, and Firebase services.

**万文社（Glyphora）** 是一个以语言、文化和交流为核心的多语言社区应用。

项目使用 **Flutter** 构建跨平台客户端，以 **Node.js / Express、Prisma 和 PostgreSQL** 承载服务器端业务，并继续使用 **Firebase Authentication、Cloud Firestore、Realtime Database 和 Cloud Storage** 等 Firebase 服务。

它并不只是一个简单的帖子列表，而是在逐步建立完整的社区系统，包括：

* 帖子发布与浏览
* 分类内容
* 点赞与评论
* 用户资料
* 好友与私信
* 实时聊天
* 聊天共享笔记
* 富文本编辑
* 多语言界面
* 发现页
* 管理后台

---

## Features

### 📝 Posts

* 发布文字帖子
* 图片帖子
* 多图片上传
* 帖子详情
* 点赞
* 评论
* 删除帖子
* 内容分类
* 推荐 / Feed
* 公开内容浏览

---

### 🔍 Discover

独立的 Discover 模块用于探索社区中的内容和用户。

```text
features/discover/
```

Discover 与 Feed 分开管理，使首页内容流与主动探索功能保持独立。

---

### 💬 Real-time Chat

项目包含完整的聊天功能模块：

```text
features/chat/
├── domain/
├── data/
├── presentation/
│   ├── cubit/
│   ├── screens/
│   └── widgets/
└── services/
```

主要页面包括：

```text
chat_list_screen.dart
chat_screen.dart
```

聊天系统支持：

* 聊天室列表
* 私信
* 实时消息
* 聊天预览
* 消息图片
* 消息状态
* 用户隐藏消息
* 双方删除
* 延迟物理清理

---

## Message Lifecycle

聊天消息不会在所有情况下立即从数据库物理删除。

项目使用类似以下生命周期：

```text
Active Message
      │
      ▼
User deletes / hides
      │
      ▼
Logical deletion
      │
      ▼
cleanupAt
      │
      ▼
Node cleanup job
      │
      ▼
Physical deletion
```

Node.js 独立清理任务会定期扫描需要清理的聊天消息。

如果消息包含 Storage 图片，也会同时处理对应媒体文件。

删除最后一条聊天消息时，后台会重新寻找上一条有效消息，并刷新聊天室预览。

---

## 🗒️ Shared Notes

```text
features/notes/
├── models/
├── screens/
└── services/
```

万文社不仅提供即时聊天，也在尝试把聊天扩展成长期协作空间。

聊天成员可以建立共享笔记，用于整理：

* 对话内容
* 学习资料
* 想法
* 共同记录
* 帖子草稿

富文本编辑基于：

```text
flutter_quill
flutter_quill_extensions
```

因此笔记可以拥有比普通聊天消息更完整的内容结构。

---

## 👥 Social

```text
features/social/
```

Social 模块负责社区中的用户关系。

包括好友相关状态与用户之间的社交连接。

整体关系可以理解为：

```text
User
 │
 ├── Profile
 │
 ├── Friends
 │
 ├── Posts
 │
 ├── Chats
 │
 └── Notes
```

---

## 👤 Profile

```text
features/profile/
```

用户资料系统用于展示个人信息以及与社区身份相关的数据。

个人资料可以进一步与：

```text
Posts
Friends
Languages
Chat
```

等功能连接。

---

## 🌍 Multilingual UI

万文社从项目结构上就考虑了多语言使用场景。

当前应用入口配置的语言包括：

```text
中文
English
日本語
한국어
Bahasa Melayu
Tiếng Việt
ไทย
```

同时还包含越南语的汉字 / 喃字脚本 Locale：

```text
vi-Hani
```

应用使用 Flutter Localization：

```text
flutter_localizations
intl
```

并拥有自己的：

```text
config/l10n/
assets/l10n/
```

本地化体系。

---

## Vietnamese Chữ Nôm Support

项目包含：

```text
NomNaTong
```

字体，并为越南语汉字 / 喃字显示提供独立的 script locale 支持。

例如：

```dart
Locale.fromSubtags(
  languageCode: 'vi',
  scriptCode: 'Hani',
)
```

这使应用的语言系统不只是：

```text
languageCode
```

还可以进一步区分：

```text
language
+
script
```

---

# Admin

项目包含独立管理模块：

```text
features/admin/
```

目前结构包括：

```text
admin_dashboard.dart
admin_posts.dart
admin_service.dart
admin_stats.dart
admin_users.dart
```

用于管理：

* 用户
* 帖子
* 平台统计
* 管理后台数据

---

# Architecture

当前 Flutter 代码主要按照 Feature 组织：

```text
lib/
│
├── app/
│   ├── cubit/
│   ├── di/
│   ├── l10n/
│   └── router/
│
├── core/
│
├── data/
│
├── features/
│   ├── admin/
│   ├── auth/
│   ├── chat/
│   ├── discover/
│   ├── feed/
│   ├── home/
│   ├── notes/
│   ├── post/
│   ├── profile/
│   └── social/
│
├── shared/
├── firebase_options.dart
│
└── main.dart
```

相比把所有页面、Service 和 Model 放在同一个目录中，这种结构更接近：

```text
Feature-oriented Architecture
```

核心业务 Feature 逐步按照以下边界组织：

```text
domain
application
data
presentation
  ├── cubit
  ├── screens
  └── widgets
```

其中 domain 定义模型与 repository contract，data 提供 Firebase / HTTP 等 adapter，presentation 负责界面与 Cubit 状态。

---

# State Management

项目当前以 **BLoC / Cubit** 管理 UI 可变状态，并继续使用 **Provider** 注入 Repository 等长生命周期依赖。

主要 UI 状态包括：

```text
AppLanguageCubit
AuthCubit
ChatCubit
FriendCubit
DiscoverCubit
FeedCubit
PostCubit
ProfileCubit
```

应用入口的职责可以概括为：

```text
MaterialApp
    │
    ▼
Composition Root
    │
    ├── Provider<Repository>
    │     ├── AuthRepository
    │     ├── PostRepository
    │     ├── ChatRepository
    │     └── ...
    │
    └── BlocProvider<Cubit>
          ├── AppLanguageCubit
          ├── AuthCubit
          ├── ChatCubit
          ├── FriendCubit
          ├── DiscoverCubit
          ├── FeedCubit
          ├── PostCubit
          └── ProfileCubit
```

因此，代码中仍然出现的 `package:provider/provider.dart` 不等于继续使用旧的 ChangeNotifier 状态管理；部分页面使用它读取 Repository，而 UI 状态由 Cubit/BLoC 负责。

---

# Authentication Flow

应用启动后：

```text
Firebase.initializeApp()
        │
        ▼
FirebaseAuth.authStateChanges()
        │
        ▼
   User logged in?
       /      \
     Yes       No
      │         │
      ▼         ▼
MainNavigation LoginScreen
```

Firebase Authentication 负责维持用户登录状态。

---

# Firebase Architecture

万文社目前主要使用以下 Firebase 服务。

### Firebase Authentication

负责：

```text
Registration
Login
Session
User identity
```

### Cloud Firestore

用于保存社区主要结构化数据，例如：

```text
Users
Posts
Chats
Messages
Social data
Notes metadata
```

### Firebase Storage

用于媒体文件，例如：

```text
Post images
Avatar images
Chat images
```

### Realtime Database

用于需要更高实时性的临时状态和实时数据。

### Node Backend Jobs

服务器端定时任务已经迁移到 Node.js API。

聊天消息清理任务位于 apps/api/src/jobs/：

- cleanup_expired_chat_messages.ts
- run_cleanup_expired_chat_messages.ts

任务负责：

- 清理达到 cleanupAt 的聊天消息
- 删除关联的 Firebase Storage 图片
- 维护聊天列表预览
- 清除不合法的 cleanupAt

生产环境应由部署平台的 Cron / Scheduler 定期执行：

npm run job:cleanup-chat-messages

---

# Deep Links

项目使用：

```text
app_links
```

并拥有：

```text
shared/services/deep_link_service.dart
```

处理应用 Deep Link。

这样未来可以支持从 App 外部链接直接进入：

```text
Post
Profile
Chat
Other content
```

等指定页面。

---

# Tech Stack

## Client

* Flutter
* Dart
* Material 3

## State Management & Dependency Injection

* flutter_bloc / Cubit — UI state and orchestration
* Provider — Repository dependency injection

## Backend

* Firebase Authentication
* Cloud Firestore
* Firebase Realtime Database
* Firebase Storage
* Node.js / Express
* Prisma / PostgreSQL

## Rich Text

* Flutter Quill
* Flutter Quill Extensions

## Media

* Image Picker
* Cached Network Image

## Localization

* Flutter Localizations
* Intl
* Custom JSON localization resources

## Sharing & Navigation

* Share Plus
* App Links

---

# Project Structure

```text
forum/
│
├── android/
├── ios/
├── linux/
├── macos/
├── web/
├── windows/
│
├── assets/
│   ├── l10n/
│   └── fonts/
│
├── functions/
│   ├── index.js
│   ├── package.json
│   └── ...
│
├── lib/
│   │
│   ├── config/
│   ├── core/
│   ├── data/
│   │
│   ├── features/
│   │   ├── admin/
│   │   ├── auth/
│   │   ├── chat/
│   │   ├── discover/
│   │   ├── feed/
│   │   ├── home/
│   │   ├── notes/
│   │   ├── profile/
│   │   └── social/
│   │
│   ├── shared/
│   ├── firebase_options.dart
│   └── main.dart
│
├── firebase.json
├── pubspec.yaml
└── README.md
```

---

# Getting Started

## 1. Clone

```bash
git clone https://github.com/chengyang1017/forum.git
cd forum
```

---

## 2. Flutter Dependencies

```bash
flutter pub get
```

---

## 3. Firebase

该项目依赖 Firebase。

你需要配置对应的 Firebase 项目，包括：

```text
Authentication
Cloud Firestore
Realtime Database
Storage
```

如果使用自己的 Firebase 项目，可以使用 FlutterFire CLI 重新生成 Firebase 配置。

---

## 4. Local Packages

当前 `pubspec.yaml` 包含两个本地路径依赖：

```yaml
glyphora_ui:
  path: C:/Users/USER/Documents/服务/glyphora_ui

glyphora_language_core:
  path: C:/Users/USER/Documents/服务/glyphora_language_core
```

因此单独 Clone 此仓库后，这两个路径在其他电脑上通常不存在。

运行项目之前需要：

1. 获取对应 package
2. 修改成本机路径
或者将这些 package 改为 Git / pub dependency。

---

## 5. Run

```bash
flutter run
```

---

# Main Application Flow

```text
Launch
  │
  ▼
Firebase Init
  │
  ▼
Authentication
  │
  ▼
Main Navigation
  │
  ├── Feed
  │
  ├── Discover
  │
  ├── Social
  │
  ├── Messages
  │
  └── Profile
  │
  ▼
Community
  │
  ├── Posts
  ├── Likes
  ├── Comments
  ├── Friends
  ├── Chats
  └── Shared Notes
```

---

# Design Philosophy

万文社并不是把“论坛”和“聊天”作为两个完全独立的功能。

项目希望把不同形式的交流连接起来：

```text
短期交流
   │
   ▼
Chat
   │
   ▼
Shared Notes
   │
   ▼
整理内容
   │
   ▼
Community Post
```

聊天适合即时交流。

笔记适合整理长期内容。

帖子适合公开表达和社区传播。

最终它们组成的是一个完整的交流体系：

```text
People
  +
Languages
  +
Conversation
  +
Knowledge
  +
Community
```

---

# Project Goals

万文社关注的不只是传统论坛中的：

```text
发帖 → 回复
```

而是尝试建立一个更加完整的多语言社区：

```text
Discover people
       │
       ▼
Communicate
       │
       ▼
Build relationships
       │
       ▼
Organize knowledge
       │
       ▼
Share with community
```

语言不仅是 UI 的翻译选项，也可以成为用户之间连接和交流的一部分。

---

# Roadmap

* [x] 用户认证
* [x] 帖子 Feed
* [x] 帖子详情
* [x] 图片上传
* [x] 点赞
* [x] 评论
* [x] 好友系统
* [x] 私信聊天
* [x] 聊天消息管理
* [x] 聊天图片
* [x] Shared Notes
* [x] 富文本编辑
* [x] 多语言 UI
* [x] Discover
* [x] 用户资料
* [x] 管理后台基础结构
* [x] Node.js 后端
* [x] 聊天消息定时清理
* [ ] 继续完善通知系统
* [ ] 完善聊天已读状态
* [ ] 完善 Shared Notes → Post 工作流
* [ ] 增强语言社区与语言频道
* [ ] 增强搜索与发现
* [ ] 完善生产环境权限与安全规则

---

# Status

**Under active development**

万文社目前仍在持续开发中。

项目中的部分架构、数据库结构和交互流程仍可能随着功能扩展继续调整。

---

# Author

**Cheng Yang**

A multilingual social platform experiment built around communication, language, shared knowledge and community.

> Different languages. One place to communicate.