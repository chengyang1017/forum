# Firestore 数据结构

本文记录万文社当前主要 Firestore 数据结构。

实际字段以后可能继续扩展。

---

# 1. users

```text
users/{uid}
```

主要字段：

```text
uid
username
nickname
avatar
bio
tags[]
languages[]
email
```

示例：

```json
{
  "uid": "user_001",
  "username": "chengyang",
  "nickname": "Cheng Yang",
  "avatar": "https://...",
  "bio": "",
  "tags": [],
  "languages": ["zh", "vi"],
  "email": "example@example.com"
}
```

---

# 2. posts

```text
posts/{postId}
```

主要字段：

```text
id
uid
title
content
category
languageCode
primaryLanguageCode
availableLanguageCodes[]
imageUrls[]
likeCount
commentCount
createdAt
updatedAt
```

帖子代表公开社区内容。

---

# 3. likes

点赞数据可以放在：

```text
posts/{postId}/likes/{uid}
```

文档存在：

```text
用户已点赞
```

文档不存在：

```text
用户未点赞
```

同时帖子保存：

```text
likeCount
```

用于快速显示点赞数量。

---

# 4. chats

```text
chats/{chatId}
```

主要字段：

```text
participantIds[]
participantNames{}
lastMessage
lastMessageAt
lastSenderId
updatedAt
```

---

# 5. chat messages

```text
chats/{chatId}/messages/{messageId}
```

字段：

```text
senderId
text
createdAt
status
deletedAt
cleanupAt
hiddenFor[]
```

---

## hiddenFor

用于：

```text
仅对自己隐藏消息
```

例如：

```json
{
  "hiddenFor": [
    "user_a"
  ]
}
```

表示：

```text
user_a 看不到
其他参与者仍然可以看到
```

---

## status

例如：

```text
normal
deleted
```

双方删除时：

```text
status = deleted
deletedAt = 当前时间
cleanupAt = 当前时间 + 7 天
```

之后由服务端清理。

---

# 6. notes

```text
notes/{noteId}
```

主要字段：

```text
ownerId
participantIds[]
sharedUserIds[]
title
content
bodyDelta[]
sourceType
sourceId
category
languageCode
allowOthersEdit
createdAt
updatedAt
updatedBy
```

---

## ownerId

笔记所有者。

---

## participantIds

所有参与这条笔记的用户。

通常：

```text
ownerId
+
sharedUserIds
```

---

## sharedUserIds

被共享笔记的其他用户。

不包含 owner。

---

## bodyDelta

保存 Quill 富文本 Delta。

示例：

```json
[
  {
    "insert": "Hello world\n"
  }
]
```

---

## sourceType

笔记来源。

例如：

```text
manual
translation
```

未来可以继续增加：

```text
chat
post
import
```

---

## sourceId

来源 ID。

例如翻译帖子保存到笔记：

```text
sourceType = translation
sourceId = postId
```

---

## category

可选。

直接复用论坛帖子分类 ID。

例如：

```text
language_learning
programming
ai
```

---

## languageCode

可选。

例如：

```text
zh
vi
en
```

语言与分类相互独立。

---

## allowOthersEdit

```text
false
```

只有 owner 可以编辑。

```text
true
```

参与者可以编辑。

---

# 7. notifications

通知用于：

- 点赞
- 评论
- 其他用户互动

具体结构随着通知系统继续开发更新。

---

# 8. 数据设计原则

## 不把显示文本当作核心 ID

例如分类：

```text
language_learning
```

是稳定 ID。

UI 再根据当前语言显示：

```text
语言学习
Language Learning
Học ngôn ngữ
```

---

## languageCode 使用稳定语言代码

例如：

```text
vi
zh
en
```

显示名称通过语言库获得。

---

## 可选字段使用 null

例如没有分类：

```text
category = null
```

而不是：

```text
category = ""
```

没有语言：

```text
languageCode = null
```

而不是：

```text
languageCode = ""
```

---

# 9. Firestore 与 Storage 的关系

Firestore 文档 ID 和 Storage 文件路径不是自动关联。

例如：

```text
Firestore
posts/post_001
```

和：

```text
Storage
posts/post_001/image_01.jpg
```

之所以有关联，是应用主动使用相同 ID 组织数据。

Firebase 不会自动把两者绑定。
