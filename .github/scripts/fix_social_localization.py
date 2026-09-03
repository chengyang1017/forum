from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

users = ROOT / 'apps/mobile-flutter/lib/features/profile/presentation/screens/users_screen.dart'
text = users.read_text(encoding='utf-8')
text = text.replace(
    "    final l10n = AppLocalizations.of(context)!;\n    final l10n = AppLocalizations.of(context)!;\n",
    "    final l10n = AppLocalizations.of(context)!;\n",
)
marker = "class _UsersErrorState extends StatelessWidget {\n  const _UsersErrorState({required this.error});\n\n  final Object? error;\n\n  @override\n  Widget build(BuildContext context) {\n    return Center("
replacement = "class _UsersErrorState extends StatelessWidget {\n  const _UsersErrorState({required this.error});\n\n  final Object? error;\n\n  @override\n  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n    return Center("
if marker not in text:
    raise RuntimeError('missing users error-state marker')
text = text.replace(marker, replacement, 1)
users.write_text(text, encoding='utf-8')

friends = ROOT / 'apps/mobile-flutter/lib/features/social/presentation/screens/friends_list_screen.dart'
text = friends.read_text(encoding='utf-8')
text = text.replace('if (!mounted) return;', 'if (!context.mounted) return;')
friends.write_text(text, encoding='utf-8')

print('Fixed social localization analyzer issues.')
