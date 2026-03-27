import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models.dart';
import '../../theme.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});
  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  List<Reward> _rewards = [];
  bool _loading = true;

  final _emojis = ['🎬', '⚽', '🎱', '🍜', '🎁', '🎮', '🧸', '🍦', '📚', '🎵', '🚗', '✈️', '🎂', '🛍️', '🎡'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ApiService().getRewards();
      setState(() => _rewards = r);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载失败: $e')));
    } finally { setState(() => _loading = false); }
  }

  void _showDialog(Reward? reward) {
    final nameCtrl = TextEditingController(text: reward?.name ?? '');
    final descCtrl = TextEditingController(text: reward?.description ?? '');
    final ptsCtrl = TextEditingController(text: reward != null ? '${reward.pointsCost}' : '');
    String selectedEmoji = reward?.emoji ?? '🎁';
    bool isActive = reward?.isActive ?? true;
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(reward == null ? '添加奖励' : '编辑奖励'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _emojis.map((e) => GestureDetector(
                    onTap: () => setS(() => selectedEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selectedEmoji == e ? kGreen.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selectedEmoji == e ? kGreen : Colors.transparent, width: 2),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '奖励名称')),
                const SizedBox(height: 10),
                TextField(controller: ptsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '所需积分')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '说明（可选）')),
                if (reward != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('激活状态'),
                      const Spacer(),
                      Switch(value: isActive, onChanged: (v) => setS(() => isActive = v), activeColor: kGreen),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: loading ? null : () async {
                final pts = int.tryParse(ptsCtrl.text);
                if (nameCtrl.text.trim().isEmpty || pts == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('请填写名称和积分')));
                  return;
                }
                setS(() => loading = true);
                try {
                  if (reward == null) {
                    await ApiService().createReward(nameCtrl.text.trim(), pts, selectedEmoji, description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim());
                  } else {
                    await ApiService().updateReward(reward.id, {
                      'name': nameCtrl.text.trim(), 'points_cost': pts, 'emoji': selectedEmoji,
                      'description': descCtrl.text.trim(), 'is_active': isActive ? 1 : 0,
                    });
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('失败: $e')));
                } finally { setS(() => loading = false); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kGreen),
              child: loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Reward reward) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('删除「${reward.name}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    try { await ApiService().deleteReward(reward.id); _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e'))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(null),
        backgroundColor: kGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('添加奖励', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _rewards.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('🎁', style: TextStyle(fontSize: 48)), SizedBox(height: 12), Text('还没有奖励', style: TextStyle(color: Colors.grey))]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _rewards.length,
                      itemBuilder: (ctx, i) {
                        final r = _rewards[i];
                        return Card(
                          color: r.isActive ? Colors.white : Colors.grey.shade100,
                          child: ListTile(
                            leading: Opacity(opacity: r.isActive ? 1.0 : 0.5, child: Text(r.emoji, style: const TextStyle(fontSize: 32))),
                            title: Text(r.name, style: TextStyle(fontWeight: FontWeight.bold, color: r.isActive ? Colors.black87 : Colors.grey)),
                            subtitle: Text('${r.pointsCost} 积分${r.isActive ? '' : '  （已停用）'}', style: TextStyle(color: r.isActive ? kGreen : Colors.grey, fontWeight: FontWeight.w600)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: Icon(Icons.edit, color: kGreen), onPressed: () => _showDialog(r)),
                                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _delete(r)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
