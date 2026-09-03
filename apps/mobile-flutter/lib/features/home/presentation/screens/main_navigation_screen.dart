import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart' as auth_cubit;
import '../../../chat/presentation/cubit/chat_cubit.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../profile/presentation/screens/my_profile_screen.dart';
import 'home_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    HomeTab(),
    ChatListScreen(),
    MyProfileScreen(),
  ];

  void _selectPage(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  void _openDiscoverPage() {
    context.push(AppRoutes.discover);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final currentUserId = context.select<auth_cubit.AuthCubit, String?>(
      (provider) => provider.user?.id,
    );

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: _openDiscoverPage,
        tooltip: l10n.discover,
        child: const Icon(Icons.person_search),
      ),
      bottomNavigationBar: _MainBottomNavigationBar(
        currentIndex: _currentIndex,
        currentUserId: currentUserId,
        l10n: l10n,
        onDestinationSelected: _selectPage,
      ),
    );
  }
}

class _MainBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final String? currentUserId;
  final AppLocalizations l10n;
  final ValueChanged<int> onDestinationSelected;

  const _MainBottomNavigationBar({
    required this.currentIndex,
    required this.currentUserId,
    required this.l10n,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onDestinationSelected,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: l10n.home,
        ),
        BottomNavigationBarItem(
          icon: _buildChatIcon(selected: false),
          activeIcon: _buildChatIcon(selected: true),
          label: l10n.messages,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: l10n.profile,
        ),
      ],
    );
  }

  Widget _buildChatIcon({required bool selected}) {
    final userId = currentUserId;

    if (userId == null) {
      return Icon(selected ? Icons.chat : Icons.chat_outlined);
    }

    return _UnreadChatIcon(userId: userId, selected: selected);
  }
}

class _UnreadChatIcon extends StatefulWidget {
  final String userId;
  final bool selected;

  const _UnreadChatIcon({required this.userId, required this.selected});

  @override
  State<_UnreadChatIcon> createState() => _UnreadChatIconState();
}

class _UnreadChatIconState extends State<_UnreadChatIcon> {
  late Stream<int> _unreadStream;

  @override
  void initState() {
    super.initState();
    _createUnreadStream();
  }

  @override
  void didUpdateWidget(covariant _UnreadChatIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userId != widget.userId) {
      _createUnreadStream();
    }
  }

  void _createUnreadStream() {
    _unreadStream = context.read<ChatCubit>().watchTotalUnread(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _unreadStream,
      initialData: 0,
      builder: (context, snapshot) {
        final totalUnread = snapshot.data ?? 0;

        return Badge(
          isLabelVisible: totalUnread > 0,
          label: Text(totalUnread > 99 ? '99+' : '$totalUnread'),
          child: Icon(widget.selected ? Icons.chat : Icons.chat_outlined),
        );
      },
    );
  }
}
