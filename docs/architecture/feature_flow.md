# 核心功能流程

本文记录万文社主要功能之间的数据流。

重点不是具体每一行代码，而是整个功能链。

---

# 1. 发帖

```text
用户点击发帖
↓
CreatePostScreen
↓
填写标题
↓
填写正文
↓
选择分类
↓
选择语言
↓
选择图片
↓
上传图片到 Storage
↓
获得 imageUrls
↓
创建 PostModel / 数据
↓
写入 Firestore posts
↓
帖子列表实时显示
```

---

# 2. 浏览帖子

```text
进入帖子列表
↓
监听 posts
↓
QuerySnapshot
↓
DocumentSnapshot
↓
PostModel
↓
List<PostModel>
↓
PostList UI
```

---

# 3. 点赞

```text
用户点击点赞
↓
检查 likes/{uid}
↓
事务
├─ 未点赞 → 创建 like
└─ 已点赞 → 删除 like
↓
更新 likeCount
↓
如果作者不是自己
↓
写入通知
```

---

# 4. 私信聊天

```text
用户列表 / 好友列表
↓
选择用户
↓
createOrGetChat
↓
获得 chatId
↓
ChatRoom
↓
监听 messages
↓
发送消息
↓
写入 messages
↓
更新 chats.lastMessage
↓
ChatList 实时更新
```

---

# 5. 消息删除

## 仅对自己删除

```text
用户删除
↓
当前 uid 加入 hiddenFor
↓
当前用户不显示
↓
其他参与者仍然可见
```

## 双方删除

```text
status = deleted
↓
deletedAt = now
↓
cleanupAt = now + 7 days
↓
Node cleanup job
↓
到期物理删除
```

---

# 6. 聊天草稿

```text
用户输入聊天内容
↓
Realtime Database
↓
chatDrafts/{chatId}/{userId}
↓
实时保存
↓
离开 / disconnect
↓
onDisconnect().remove()
```

---

# 7. 新建笔记

```text
用户点击“新建笔记”
↓
弹出笔记配置
↓
此时尚未创建 Firestore 文档
↓
用户可以选择
├─ 语言
├─ 分类
└─ 共享成员
↓
用户点击“创建笔记”
↓
NoteService.createNote()
↓
写入 notes
↓
获得 noteId
↓
进入 NoteEditorScreen
```

如果用户关闭配置：

```text
config = null
↓
return
↓
不创建笔记
```

---

# 8. 编辑笔记

```text
NoteEditorScreen
↓
监听 note
↓
NoteModel
↓
加载
├─ title
├─ bodyDelta
├─ category
├─ languageCode
├─ sharedUserIds
└─ allowOthersEdit
↓
用户编辑
↓
NoteService.updateNote
↓
Firestore
```

---

# 9. 笔记筛选

```text
所有笔记
↓
选择语言
↓
matchesLanguage
↓
选择分类
↓
matchesCategory
↓
matchesLanguage && matchesCategory
↓
显示结果
```

例如：

```text
语言 = 越南语
分类 = 语言学习
```

只显示同时满足两者的笔记。

---

# 10. 帖子翻译

```text
原帖子
↓
选择目标语言
↓
AI 翻译
↓
翻译结果
├─ 修改
├─ 保存到笔记
└─ 发布翻译
```

---

# 11. 翻译保存笔记

```text
原帖子
↓
翻译为目标语言
↓
保存笔记
↓
NoteService.createNote
↓
sourceType = translation
sourceId = 原 postId
category = 原帖子 category
languageCode = 目标语言
↓
Note
```

---

# 12. 笔记发布帖子

```text
Note
↓
用户点击“发布为帖子”
↓
保存当前笔记
↓
检查 category
├─ 已存在 → 直接使用
└─ 缺失 → 选择 → 保存回 Note
↓
检查 languageCode
├─ 已存在 → 直接使用
└─ 缺失 → 选择 → 保存回 Note
↓
CreatePostScreen
↓
带入标题和正文
↓
用户确认
↓
发布帖子
```

---

# 13. 当前内容闭环

目前正在形成：

```text
帖子
↓
翻译
↓
笔记
↓
编辑
↓
共享
↓
学习
↓
重新发布
↓
帖子
```

笔记因此成为不同内容功能之间的重要中间层。
