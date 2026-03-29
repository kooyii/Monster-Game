import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api_service.dart';
import '../../local_db.dart';
import '../../models.dart';
import '../../theme.dart';

class ParentDashboard extends ConsumerStatefulWidget {
  const ParentDashboard({super.key});
  @override
  ConsumerState<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends ConsumerState<ParentDashboard> {
  List<Child> _children = [];
  List<Reward> _rewards = [];
  List<PointTransaction> _recentTx = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService().getChildren(),
        ApiService().getRewards(),
        ApiService().getTransactions(limit: 8),
      ]);
      setState(() {
        _children = results[0] as List<Child>;
        _rewards = results[1] as List<Reward>;
        _recentTx = results[2] as List<PointTransaction>;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载失败: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    // Weekly points
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekPts = _recentTx
        .where((t) => t.points > 0 && DateTime.tryParse(t.createdAt)?.isAfter(weekAgo) == true)
        .fold(0, (s, t) => s + t.points);

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            Row(children: [
              _StatCard(emoji: '👶', value: '${_children.length}', label: '孩子', color: kPurple),
              const SizedBox(width: 10),
              _StatCard(emoji: '⭐', value: '$weekPts', label: '本周积分', color: kYellow),
              const SizedBox(width: 10),
              _StatCard(emoji: '🎁', value: '${_rewards.length}', label: '奖励项目', color: kGreen),
            ]),
            const SizedBox(height: 20),

            // Quick award
            _SectionCard(
              title: '🎯 快速发放积分',
              child: _AwardWidget(children: _children, onDone: _load),
            ),
            const SizedBox(height: 16),

            // Redeem for child
            _SectionCard(
              title: '🎁 帮孩子兑换奖励',
              child: _RedeemWidget(children: _children, rewards: _rewards, onDone: _load),
            ),
            const SizedBox(height: 16),

            // Recent transactions
            _SectionCard(
              title: '📊 最近积分记录',
              child: _recentTx.isEmpty
                  ? const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('暂无记录', style: TextStyle(color: Colors.grey))))
                  : Column(
                      children: _recentTx.map((t) => _TxRow(tx: t)).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _StatCard({required this.emoji, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Award Widget ────────────────────────────────────────────────────────────
class _AwardWidget extends StatefulWidget {
  final List<Child> children;
  final VoidCallback onDone;
  const _AwardWidget({required this.children, required this.onDone});
  @override
  State<_AwardWidget> createState() => _AwardWidgetState();
}

class _AwardWidgetState extends State<_AwardWidget> {
  Child? _selectedChild;
  final _pointsCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;
  List<QuickReason> _quickReasons = [];

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  Future<void> _loadReasons() async {
    final r = await LocalDb().getQuickReasons();
    if (mounted) setState(() => _quickReasons = r);
  }

  Future<void> _award() async {
    final child = _selectedChild;
    final pts = int.tryParse(_pointsCtrl.text);
    final desc = _descCtrl.text.trim();
    if (child == null || pts == null || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写所有字段')));
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiService().awardPoints(child.id, pts, desc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('积分已${pts > 0 ? '发放' : '扣除'}！余额: ${res['new_balance']}'),
          backgroundColor: kGreen,
        ));
        _pointsCtrl.clear(); _descCtrl.clear();
        widget.onDone();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('失败: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<Child>(
          initialValue: _selectedChild,
          hint: const Text('选择孩子'),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.person)),
          items: widget.children.map((c) => DropdownMenuItem(value: c, child: Text('${c.avatarEmoji} ${c.name} (${c.points} 积分)'))).toList(),
          onChanged: (v) => setState(() => _selectedChild = v),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _pointsCtrl,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: const InputDecoration(labelText: '积分数量（负数为扣除）', prefixIcon: Icon(Icons.star)),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _descCtrl,
          decoration: const InputDecoration(labelText: '原因', prefixIcon: Icon(Icons.edit_note)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 6,
          children: _quickReasons.map((r) => ActionChip(
            label: Text('${r.emoji} ${r.label}', style: const TextStyle(fontSize: 12)),
            onPressed: () { _descCtrl.text = r.label; _pointsCtrl.text = '${r.points}'; },
            backgroundColor: r.points > 0 ? Colors.green.shade50 : Colors.red.shade50,
          )).toList(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _award,
            child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('🎯 发放积分'),
          ),
        ),
      ],
    );
  }
}

// ── Redeem Widget ───────────────────────────────────────────────────────────
class _RedeemWidget extends StatefulWidget {
  final List<Child> children;
  final List<Reward> rewards;
  final VoidCallback onDone;
  const _RedeemWidget({required this.children, required this.rewards, required this.onDone});
  @override
  State<_RedeemWidget> createState() => _RedeemWidgetState();
}

class _RedeemWidgetState extends State<_RedeemWidget> {
  Child? _selectedChild;

  Future<void> _redeem(Reward reward) async {
    final child = _selectedChild!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('确认兑换 ${reward.emoji}'),
        content: Text('为 ${child.name} 兑换「${reward.name}」\n消耗 ${reward.pointsCost} 积分，当前 ${child.points} 积分'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('确认兑换')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await ApiService().directRedeem(child.id, reward.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('兑换成功！${reward.name} ✅ 剩余积分: ${res['new_balance']}'),
          backgroundColor: kGreen,
        ));
        widget.onDone();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('兑换失败: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<Child>(
          initialValue: _selectedChild,
          hint: const Text('选择孩子'),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.person)),
          items: widget.children.map((c) => DropdownMenuItem(value: c, child: Text('${c.avatarEmoji} ${c.name} (${c.points} 积分)'))).toList(),
          onChanged: (v) => setState(() => _selectedChild = v),
        ),
        if (_selectedChild != null) ...[
          const SizedBox(height: 12),
          ...widget.rewards.map((r) {
            final canAfford = _selectedChild!.points >= r.pointsCost;
            return Opacity(
              opacity: canAfford ? 1.0 : 0.5,
              child: Card(
                color: canAfford ? const Color(0xFFECFDF5) : Colors.grey.shade50,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(r.emoji, style: const TextStyle(fontSize: 28)),
                  title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    canAfford ? '${r.pointsCost} 积分' : '差 ${r.pointsCost - _selectedChild!.points} 积分',
                    style: TextStyle(color: canAfford ? kGreen : Colors.orange, fontWeight: FontWeight.w600),
                  ),
                  trailing: ElevatedButton(
                    onPressed: canAfford ? () => _redeem(r) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford ? kGreen : Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text('兑换'),
                  ),
                ),
              ),
            );
          }),
        ] else
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('请先选择孩子', style: TextStyle(color: Colors.grey))),
          ),
      ],
    );
  }
}

class _TxRow extends StatelessWidget {
  final PointTransaction tx;
  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isEarn = tx.points > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isEarn ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(tx.avatarEmoji ?? '🧒', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.childName ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(tx.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            isEarn ? '+${tx.points}' : '${tx.points}',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isEarn ? kGreen : Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
