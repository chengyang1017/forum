# 帖子系统

## 1. 功能定位

帖子是万文社主要的公开内容单位。

用户可以围绕：

- 语言
- 编程
- AI
- 科技
- 游戏
- 音乐
- 电影
- 校园
- 创业
- 交友
- 旅行
- 闲聊
- 恋爱
- 美食

等主题发布内容。

---

# 2. PostModel

帖子主要字段包括：

```text
id
userId / uid
title
content
category
languageCode
primaryLanguageCode
availableLanguageCodes
imageUrls
likes
likeCount
commentCount
createdAt
updatedAt
```

---

# 3. 分类

帖子分类使用稳定 ID。

例如：

```text
language_learning
programming
ai
technology
gaming
music
movies
campus
startup
friends
travel
chat
love
food
```

UI 根据当前语言显示本地化名称。

---

# 4. 语言

帖子可以记录：

```text
languageCode
primaryLanguageCode
availableLanguageCodes
```

语言数据应该来自统一语言库。

页面不应该维护独立语言表。

---

# 5. 创建帖子

流程：

```text
CreatePostScreen
↓
标题
↓
正文
↓
分类
↓
语言
↓
图片
↓
上传 Storage
↓
获得 URL
↓
写入 Firestore posts
```

---

# 6. 图片限制

当前发帖图片限制：

```text
最多 9 张
```

单张图片限制：

```text
最大 10 MB
```

正文最大长度：

```text
1000 字
```

---

# 7. 帖子列表

帖子列表从 Firestore 读取。

基本查询方向：

```text
createdAt DESC
```

并限制单次加载数量。

---

# 8. 帖子详情

帖子详情显示：

- 作者
- 标题
- 内容
- 图片
- 时间
- 点赞
- 评论

---

# 9. 点赞

点赞使用：

```text
posts/{postId}/likes/{uid}
```

同时维护：

```text
likeCount
```

操作建议通过 transaction 保证一致性。

---

# 10. 通知

如果：

```text
点赞者 != 作者
```

则可以创建通知。

取消点赞时删除对应点赞状态。

---

# 11. 翻译

帖子支持翻译。

翻译结果可以：

```text
直接发布
```

或者：

```text
保存到笔记
```

保存到笔记以后，用户可以继续修改。

---

# 12. 笔记发布帖子

笔记也可以成为 CreatePostScreen 的来源。

流程：

```text
Note
↓
准备 category
↓
准备 languageCode
↓
准备 title
↓
准备 bodyDelta
↓
CreatePostScreen
```

这样帖子系统和笔记系统形成内容复用。

---

# 13. 长期方向

帖子未来可以继续扩展：

- 多语言版本
- 语音帖子
- 翻译版本
- 收藏
- 订阅
- 语言频道
- 推荐
- 搜索
- 分享
- 草稿关联
