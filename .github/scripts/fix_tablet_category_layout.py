from pathlib import Path

path = Path('apps/mobile-flutter/lib/features/home/presentation/screens/home_tab.dart')
text = path.read_text(encoding='utf-8')

old_grid = '''  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 720 ? 4 : 2;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];

            final categoryName = index < categoryNames.length
                ? categoryNames[index]
                : ForumCategories.nameOf(
                    category.id,
                    Localizations.localeOf(context).languageCode,
                  );

            final key = '$channelKey::${category.id}';

            final isInterested = interests.contains(key);

            return _CategoryCard(
              index: index,
              icon: category.icon,
              name: categoryName,
              isInterested: isInterested,
              onTap: () {
                onCategorySelected(category);
              },
              onInterestPressed: () {
                onInterestPressed(category, isInterested);
              },
            );
          },
        );
      },
    );
  }
}'''

new_grid = '''  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= 600;
        final crossAxisCount = width >= 1100
            ? 6
            : width >= 760
            ? 5
            : width >= 600
            ? 4
            : 2;
        final horizontalPadding = isTablet ? 24.0 : 16.0;
        final spacing = isTablet ? 10.0 : 12.0;
        final childAspectRatio = isTablet ? 1.6 : 1.35;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                20,
              ),
              itemCount: categories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];

                final categoryName = index < categoryNames.length
                    ? categoryNames[index]
                    : ForumCategories.nameOf(
                        category.id,
                        Localizations.localeOf(context).languageCode,
                      );

                final key = '$channelKey::${category.id}';

                final isInterested = interests.contains(key);

                return _CategoryCard(
                  index: index,
                  icon: category.icon,
                  name: categoryName,
                  isInterested: isInterested,
                  onTap: () {
                    onCategorySelected(category);
                  },
                  onInterestPressed: () {
                    onInterestPressed(category, isInterested);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}'''

if old_grid not in text:
    raise SystemExit('Category grid block did not match current main')
text = text.replace(old_grid, new_grid, 1)

old_card_start = '''  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _accentColor(colorScheme, index);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),'''

new_card_start = '''  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _accentColor(colorScheme, index);
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final radius = isTablet ? 16.0 : 20.0;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),'''

if old_card_start not in text:
    raise SystemExit('Category card start did not match current main')
text = text.replace(old_card_start, new_card_start, 1)

replacements = {
    '''          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),''': '''          child: Padding(
            padding: isTablet
                ? const EdgeInsets.fromLTRB(10, 8, 5, 8)
                : const EdgeInsets.fromLTRB(14, 12, 8, 12),''',
    '''                Container(
                  width: 45,
                  height: 45,''': '''                Container(
                  width: isTablet ? 38 : 45,
                  height: isTablet ? 38 : 45,''',
    '''                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 11),''': '''                    borderRadius: BorderRadius.circular(isTablet ? 12 : 14),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: isTablet ? 21 : 24,
                  ),
                ),
                SizedBox(width: isTablet ? 8 : 11),''',
    '''                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),''': '''                    style: TextStyle(
                      fontSize: isTablet ? 13 : 14,
                      fontWeight: FontWeight.w700,
                    ),''',
    '''                IconButton(
                  tooltip: isInterested ? '取消感兴趣' : '设为感兴趣',
                  onPressed: onInterestPressed,
                  icon: Icon(''': '''                IconButton(
                  tooltip: isInterested ? '取消感兴趣' : '设为感兴趣',
                  onPressed: onInterestPressed,
                  visualDensity: isTablet
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                  constraints: isTablet
                      ? const BoxConstraints.tightFor(width: 36, height: 36)
                      : null,
                  iconSize: isTablet ? 20 : 24,
                  icon: Icon(''',
}

for old, new in replacements.items():
    if old not in text:
        raise SystemExit(f'Expected card snippet missing: {old[:50]!r}')
    text = text.replace(old, new, 1)

path.write_text(text, encoding='utf-8')
