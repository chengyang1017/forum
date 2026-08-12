# 聊天系统

## 1. 功能定位

聊天系统提供用户之间的私人交流。

同时聊天并不只是消息功能。

聊天内容未来可以进一步进入：

```text
聊天
↓
笔记
↓
学习整理
↓
帖子
```

---

# 2. ChatList

ChatList 监听聊天房间。

主要排序：

```text
lastMessageAt DESC
```

展示：

- 对方头像
- 对方名称
- 最后一条消息
- 最后消息时间

---

# 3. FriendList

FriendList 从用户数据中显示可以进入聊天的用户。

点击用户：

```text
FriendList
↓
createOrGetChat
↓
chatId
↓
ChatRoom
```

---

# 4. chats

结构：

```text
chats/{chatId}
```

字段：

```text
participantIds
participantNames
lastMessage
lastMessageAt
lastSenderId
updatedAt
```

---

# 5. messages

结构：

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
hiddenFor
```

---

# 6. 发送消息

```text
用户输入
↓
发送
↓
messages.add
↓
更新 chat room
├─ lastMessage
├─ lastMessageAt
├─ lastSenderId
└─ updatedAt
↓
ChatList 更新
```

---

# 7. 仅自己删除

消息保留在数据库。

当前用户加入：

```text
hiddenFor[]
```

例如：

```text
hiddenFor = [userA]
```

则只有 A 不再看到。

---

# 8. 双方删除

消息：

```text
status = deleted
```

同时：

```text
deletedAt = now
cleanupAt = now + 7 days
```

Cloud Function 在到期后进行物理清理。

---

# 9. 实时草稿

聊天输入草稿保存在 Realtime Database：

```text
chatDrafts/{chatId}/{userId}
```

使用：

```text
onDisconnect().remove()
```

处理断线后的临时数据。

---

# 10. 聊天和笔记

聊天可以关联笔记。

但笔记本身不应该永久绑定某个 chatId。

更灵活的方式是：

```text
Note
↓
participantIds
↓
包含某个聊天对象
↓
聊天入口显示相关笔记
```

这样同一条笔记可以：

- 属于自己
- 与一个用户共享
- 与多个用户共享
- 从聊天入口访问
- 从全部笔记入口访问

---

# 11. 后续方向

聊天系统未来可能加入：

- 已读回执
- APP 外通知
- 语音消息
- 图片消息
- 回复
- 消息引用
- 搜索
- 多人聊天
- 笔记快捷入口
