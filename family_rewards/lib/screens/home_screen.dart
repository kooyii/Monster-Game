import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../theme.dart';
import 'child_view_screen.dart';
import 'pin_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(publicChildrenProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3), Color(0xFFDBEAFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    const Text('家庭积分', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF4C1D95))),
                    const Spacer(),
                    _ParentButton(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text('积分排行榜', style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Children list
              Expanded(
                child: childrenAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('😵', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('加载失败', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text('$e', style: TextStyle(color: Colors.red.shade400, fontSize: 11), textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(publicChildrenProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                  data: (children) {
                    if (children.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('👶', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 12),
                            Text('还没有孩子账号', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            Text('请家长登录后添加', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(publicChildrenProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: children.length,
                        itemBuilder: (ctx, i) => _ChildCard(child: children[i], rank: i + 1),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Child child;
  final int rank;
  const _ChildCard({required this.child, required this.rank});

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    final medal = rank <= 3 ? medals[rank - 1] : '$rank';
    final colors = [
      const Color(0xFFFFFBEB), const Color(0xFFF9FAFB), const Color(0xFFFFFBEB)
    ];
    final bg = rank <= 3 ? colors[rank - 1] : Colors.white;

    return Card(
      color: bg,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildViewScreen(child: child))),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(medal, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Text(child.avatarEmoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(child.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${child.points}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kPurple)),
                  const Text('积分', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider);
    return ElevatedButton.icon(
      onPressed: () {
        if (isLoggedIn) {
          Navigator.pushNamed(context, '/parent');
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PinScreen()));
        }
      },
      icon: const Text('👨‍👩‍👧', style: TextStyle(fontSize: 16)),
      label: Text(isLoggedIn ? '家长控制台' : '家长登录'),
      style: ElevatedButton.styleFrom(
        backgroundColor: kPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }
}
