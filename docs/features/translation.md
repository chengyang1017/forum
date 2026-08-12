# 翻译系统

## 1. 功能定位

翻译功能负责把论坛内容转换为其他语言。

但翻译结果不是一次性文本。

它可以继续进入：

```text
翻译
↓
笔记
↓
修改
↓
发布
```

---

# 2. 基本流程

```text
帖子
↓
选择目标语言
↓
翻译
↓
生成翻译结果
↓
用户检查 / 修改
↓
选择下一步
```

---

# 3. 翻译结果操作

目前设计包含两个主要方向：

```text
保存到笔记
```

和：

```text
发布翻译
```

---

# 4. 保存到笔记

翻译保存到笔记时：

```dart
sourceType: 'translation'
sourceId: post.id
category: post.category
languageCode: targetLanguageCode
```

---

# 5. 为什么保存 targetLanguageCode

例如：

```text
原帖：中文
↓
目标语言：越南语
↓
翻译结果：越南语
```

保存成笔记后：

```text
languageCode = vi
```

因为笔记正文现在实际上是越南语。

这样：

```text
按越南语筛选笔记
```

可以找到它。

---

# 6. category

翻译内容默认可以继承原帖 category。

例如：

```text
原帖 category = programming
```

翻译保存后：

```text
Note.category = programming
```

以后再次发布时不需要重新选择。

---

# 7. sourceType

使用：

```text
translation
```

标记来源。

这样未来可以区分：

```text
手动笔记
翻译笔记
帖子笔记
聊天笔记
```

---

# 8. sourceId

保存：

```text
原帖子 ID
```

以后可以用于：

- 找回来源帖子
- 显示来源
- 防止重复翻译
- 维护翻译关系
- 建立多语言版本关系

---

# 9. 发布翻译

用户检查翻译以后，也可以直接发布。

长期可以建立：

```text
originalPostId
translationPostIds
languageCode
```

把多个语言版本正式关联起来。

---

# 10. 与语言库关系

目标语言必须来自统一语言体系：

```text
glyphora_language_core
↓
ForumLanguages
↓
Translation
```

翻译页面不应该再次维护独立语言表。

---

# 11. 长期方向

翻译系统未来可以扩展：

- 多个翻译版本
- 人工修改历史
- AI 翻译
- 用户翻译
- 原文 / 译文对照
- 翻译质量评价
- 多语言帖子关系
- 词典辅助翻译
- 直接保存单词到学习笔记
