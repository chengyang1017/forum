# 笔记系统

## 1. 功能定位

万文社的笔记并不是单纯的私人记事本。

它同时承担：

- 学习记录
- 聊天内容整理
- 翻译结果保存
- 帖子草稿
- 多人协作
- 内容再发布

因此笔记是多个功能之间的中间内容层。

---

# 2. NoteModel

当前核心字段：

```dart
id
ownerId
participantIds
sharedUserIds
title
content
bodyDelta
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

# 3. 私人笔记

如果：

```text
sharedUserIds = []
```

则笔记只有 owner。

---

# 4. 共享笔记

用户可以把笔记共享给其他用户。

例如：

```text
owner = A

sharedUserIds =
[B, C]

participantIds =
[A, B, C]
```

---

# 5. 编辑权限

默认：

```text
allowOthersEdit = false
```

只有 owner 可以编辑。

如果 owner 开启：

```text
allowOthersEdit = true
```

共享参与者可以编辑。

---

# 6. 富文本

笔记正文使用 Flutter Quill。

主要保存：

```text
bodyDelta
```

同时保存：

```text
content
```

作为纯文本内容。

`bodyDelta` 用于恢复格式。

`content` 方便：

- 列表预览
- 搜索
- 简单文本处理
- 后续索引

---

# 7. 语言

笔记支持：

```dart
String? languageCode;
```

语言不是必填。

示例：

```text
vi
zh
en
```

显示名称和国旗统一从语言库读取。

---

# 8. 分类

笔记支持：

```dart
String? category;
```

笔记分类直接复用帖子分类。

原因：

```text
笔记可能最终发布成帖子
```

因此不建立重复的 noteCategories。

---

# 9. 语言和分类独立

允许：

```text
只有语言
```

```text
只有分类
```

```text
语言 + 分类
```

```text
两者都没有
```

只有真正进入需要这些字段的流程时才要求补充。

例如：

```text
发布帖子
```

---

# 10. 新建笔记

用户点击：

```text
新建笔记
```

先打开配置窗口：

```text
新建笔记

语言              未选择 >
分类              未选择 >
共享                仅自己 >

            创建笔记
```

---

# 11. 创建配置全部可选

用户不需要提前填写任何东西。

如果直接点击创建：

```text
languageCode = null
category = null
sharedUserIds = []
```

仍然正常创建。

因此不需要额外：

```text
跳过
```

按钮。

---

# 12. 创建时机

打开配置窗口：

```text
不会创建笔记
```

只有点击：

```text
创建笔记
```

才执行：

```dart
NoteService.createNote(...)
```

这样可以避免：

```text
打开新建
↓
用户取消
↓
数据库留下空白笔记
```

---

# 13. 笔记列表筛选

列表顶部：

```text
语言                  全部语言 >
分类                  全部分类 >
```

没有使用 Tab。

没有把所有选项直接铺开。

---

# 14. 语言筛选

支持：

```text
全部语言
未指定语言
具体语言
```

---

# 15. 分类筛选

支持：

```text
全部分类
未分类
具体分类
```

---

# 16. 联合筛选

语言和分类：

```text
AND
```

例如：

```text
语言 = vi
分类 = language_learning
```

只显示同时满足两个条件的 Note。

---

# 17. 笔记卡片

笔记卡片主要显示：

- 标题
- 正文预览
- 是否可编辑
- 语言
- 分类
- 共享信息
- 更新时间

例如：

```text
越南语学习

今天学习了……

🇻🇳 越南语
语言学习

与 Nguyen 共享        13:20
```

---

# 18. 来源

通过：

```text
sourceType
sourceId
```

记录笔记来源。

例如：

```text
manual
translation
```

以后可以扩展：

```text
post
chat
import
```

---

# 19. 发布帖子

笔记可以作为帖子草稿。

如果已有：

```text
category
languageCode
```

发布时直接使用。

如果缺少：

```text
发布阶段再让用户选择
```

选择完成以后，还会保存回 Note。

---

# 20. 后续方向

笔记系统后续可以继续扩展：

- 公开笔记
- 用户主页展示公开笔记
- 标签
- 文件夹
- 笔记搜索
- 全文搜索
- 收藏
- 历史版本
- 多人实时编辑
- 翻译版本管理

这些功能不应该改变当前：

```text
languageCode
category
```

的含义。

个人整理需求以后应该单独使用：

```text
folder
tags
```

而不是滥用 category。
