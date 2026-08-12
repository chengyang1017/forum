class ForumCategory {
  final String id;
  final String? parentId;

  const ForumCategory({
    required this.id,
    this.parentId,
  });

  bool get isRoot => parentId == null;
}

class ForumCategories {
  const ForumCategories._();

  static const List<ForumCategory> all = [
    ForumCategory(id: 'language_learning'),
    ForumCategory(id: 'programming'),
    ForumCategory(id: 'ai'),
    ForumCategory(id: 'technology'),
    ForumCategory(id: 'gaming'),
    ForumCategory(id: 'music'),
    ForumCategory(id: 'movies'),
    ForumCategory(id: 'campus'),
    ForumCategory(id: 'startup'),
    ForumCategory(id: 'friends'),
    ForumCategory(id: 'travel'),
    ForumCategory(id: 'chat'),
    ForumCategory(id: 'love'),
    ForumCategory(id: 'food'),

    // 新一级分类。
    ForumCategory(id: 'medicine'),
  ];

  static List<ForumCategory> get roots {
    return all.where((category) => category.isRoot).toList(growable: false);
  }

  static ForumCategory? findById(String id) {
    for (final category in all) {
      if (category.id == id) {
        return category;
      }
    }

    return null;
  }

  static List<ForumCategory> childrenOf(String parentId) {
    return all
        .where((category) => category.parentId == parentId)
        .toList(growable: false);
  }

  static List<String> pathOf(String categoryId) {
    final path = <String>[];
    final visited = <String>{};

    ForumCategory? current = findById(categoryId);

    while (current != null && visited.add(current.id)) {
      path.add(current.id);

      final parentId = current.parentId;
      if (parentId == null) {
        break;
      }

      current = findById(parentId);
    }

    return path.reversed.toList(growable: false);
  }

  static String rootIdOf(String categoryId) {
    final path = pathOf(categoryId);

    if (path.isEmpty) {
      return categoryId;
    }

    return path.first;
  }
}
