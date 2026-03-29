import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models.dart';
import '../theme.dart';
import 'lottery_screen.dart';

class ChildViewScreen extends StatefulWidget {
  final Child child;
  const ChildViewScreen({super.key, required this.child});

  @override
  State<ChildViewScreen> createState() => _ChildViewScreenState();
}

class _ChildViewScreenState extends State<ChildViewScreen> {
  late Child _child;
  List<PointTransaction> _transactions = [];
  List<Reward> _rewards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _child = widget.child;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getPublicChild(_child.id);
      final rewards = await ApiService().getPublicRewards();
      final txList = (data['transactions'] as List)
          .map((e) => PointTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _child = Child(id: _child.id, name: data['name'], avatarEmoji: data['avatar_emoji'], points: data['points']);
        _transactions = txList;
        _rewards = rewards;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载失败: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final affordable = _rewards.where((r) => r.pointsCost <= _child.points).toList();
    final notYet = _rewards.where((r) => r.pointsCost > _child.points).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: Text('${_child.avatarEmoji} ${_child.name}'),
        actions: [
          IconButton(
            icon: const Text('🎰', style: TextStyle(fontSize: 22)),
            tooltip: '幸运抽奖',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => LotteryScreen(child: _child)));
              _load();
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Points card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: gradientDecoration(borderRadius: 24),
                      child: Column(
                        children: [
                          Text(_child.avatarEmoji, style: const TextStyle(fontSize: 56)),
                          const SizedBox(height: 8),
                          Text(_child.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 12),
                          Text('${_child.points}', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white)),
                          const Text('积分', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Affordable rewards
                    if (affordable.isNotEmpty) ...[
                      _sectionTitle('🎁 现在可以兑换'),
                      const SizedBox(height: 8),
                      ...affordable.map((r) => _RewardTile(reward: r, canAfford: true, childPoints: _child.points)),
                      const SizedBox(height: 16),
                    ],

                    // Not yet affordable
                    if (notYet.isNotEmpty) ...[
                      _sectionTitle('🎯 继续加油'),
                      const SizedBox(height: 8),
                      ...notYet.map((r) => _RewardTile(reward: r, canAfford: false, childPoints: _child.points)),
                      const SizedBox(height: 16),
                    ],

                    // Transaction history
                    _sectionTitle('📊 最近积分记录'),
                    const SizedBox(height: 8),
                    if (_transactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('暂无记录', style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ...(_transactions.take(15).map((t) => _TransactionTile(tx: t))),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) =>
      Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4C1D95)));
}

class _RewardTile extends StatelessWidget {
  final Reward reward;
  final bool canAfford;
  final int childPoints;
  const _RewardTile({required this.reward, required this.canAfford, required this.childPoints});

  @override
  Widget build(BuildContext context) {
    final need = reward.pointsCost - childPoints;
    return Card(
      color: canAfford ? const Color(0xFFECFDF5) : Colors.grey.shade50,
      child: ListTile(
        leading: Text(reward.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(reward.name, style: TextStyle(fontWeight: FontWeight.bold, color: canAfford ? Colors.black87 : Colors.grey)),
        subtitle: Text(
          canAfford ? '${reward.pointsCost} 积分 ✅' : '还差 $need 积分',
          style: TextStyle(color: canAfford ? kGreen : Colors.orange, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        trailing: Text('${reward.pointsCost}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: canAfford ? kGreen : Colors.grey)),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final PointTransaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isEarn = tx.points > 0;
    return Card(
      color: isEarn ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
      child: ListTile(
        leading: Text(isEarn ? '⭐' : '🎁', style: const TextStyle(fontSize: 22)),
        title: Text(tx.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: Text(
          isEarn ? '+${tx.points}' : '${tx.points}',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isEarn ? kGreen : Colors.redAccent),
        ),
      ),
    );
  }
}
