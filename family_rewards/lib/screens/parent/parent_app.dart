import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../theme.dart';
import 'dashboard.dart';
import 'children.dart';
import 'rewards.dart';
import 'history.dart';

class ParentApp extends ConsumerStatefulWidget {
  const ParentApp({super.key});
  @override
  ConsumerState<ParentApp> createState() => _ParentAppState();
}

class _ParentAppState extends ConsumerState<ParentApp> {
  int _index = 0;

  final _screens = const [
    ParentDashboard(),
    ChildrenScreen(),
    RewardsScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: kGradient)),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text('⭐', style: TextStyle(fontSize: 20)), SizedBox(width: 6), Text('家长控制台')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '退出家长模式',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: '孩子'),
          NavigationDestination(icon: Icon(Icons.card_giftcard_outlined), selectedIcon: Icon(Icons.card_giftcard), label: '奖励'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: '记录'),
        ],
      ),
    );
  }
}
