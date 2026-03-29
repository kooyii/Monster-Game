import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models.dart';
import '../../theme.dart';
import '../lottery_screen.dart';

class LotteryTab extends StatefulWidget {
  const LotteryTab({super.key});
  @override
  State<LotteryTab> createState() => _LotteryTabState();
}

class _LotteryTabState extends State<LotteryTab> {
  List<Child> _children = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final c = await ApiService().getChildren();
      setState(() => _children = c);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载失败: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0533),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                      child: Column(
                        children: [
                          const Text('🎰', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 8),
                          const Text('幸运抽奖', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 6),
                          const Text('选择一个孩子开始抽奖', style: TextStyle(color: Colors.white60, fontSize: 14)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('每次消耗 2 积分 · 积分越高中奖概率越低',
                                style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  if (_children.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('👶', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 12),
                            Text('还没有孩子账号', style: TextStyle(color: Colors.white54, fontSize: 16)),
                            Text('请先在「孩子」标签添加', style: TextStyle(color: Colors.white38, fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _ChildLotteryCard(child: _children[i], onReturn: _load),
                          childCount: _children.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _ChildLotteryCard extends StatelessWidget {
  final Child child;
  final VoidCallback onReturn;
  const _ChildLotteryCard({required this.child, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    final canPlay = child.points >= 2;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: canPlay
            ? const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: canPlay ? null : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        boxShadow: canPlay
            ? [BoxShadow(color: kPurple.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: canPlay
              ? () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => LotteryScreen(child: child)));
                  onReturn();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Text(child.avatarEmoji, style: const TextStyle(fontSize: 44)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        canPlay ? '⭐ ${child.points} 积分  · 可以抽奖' : '⭐ ${child.points} 积分  · 积分不足',
                        style: TextStyle(fontSize: 13, color: canPlay ? Colors.white70 : Colors.white38),
                      ),
                    ],
                  ),
                ),
                Icon(
                  canPlay ? Icons.casino_rounded : Icons.lock_outline,
                  color: canPlay ? Colors.yellow : Colors.white24,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
