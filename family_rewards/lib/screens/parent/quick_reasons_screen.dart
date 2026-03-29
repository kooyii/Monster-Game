import 'package:flutter/material.dart';
import '../../local_db.dart';
import '../../models.dart';
import '../../theme.dart';

class QuickReasonsScreen extends StatefulWidget {
  const QuickReasonsScreen({super.key});
  @override
  State<QuickReasonsScreen> createState() => _QuickReasonsScreenState();
}

class _QuickReasonsScreenState extends State<QuickReasonsScreen> {
  List<QuickReason> _reasons = [];
  bool _loading = true;

  final _emojis = ['⭐', '🗑️', '🍽️', '🏠', '📚', '🏅', '❌', '💪', '🧹', '🌟', '🎯', '✅', '🏆', '🌱', '🎨'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await LocalDb().getQuickReasons();
    setState(() { _reasons = r; _loading = false; });
  }

  void _showDialog([QuickReason? reason]) {
    final labelCtrl = TextEditingController(text: reason?.label ?? '');
    final ptsCtrl = TextEditingController(text: reason != null ? '${reason.points}' : '1');
    String selectedEmoji = reason?.emoji ?? '⭐';
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(reason == null ? '添加理由' : '编辑理由'),
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
                        color: selectedEmoji == e ? kPurple.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selectedEmoji == e ? kPurple : Colors.transparent, width: 2),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: '理由描述', hintText: '例：倒垃圾')),
                const SizedBox(height: 10),
                TextField(
                  controller: ptsCtrl,
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  decoration: const InputDecoration(labelText: '积分（负数为扣分）', hintText: '例：1 或 -1'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (labelCtrl.text.trim().isEmpty) return;
                final pts = int.tryParse(ptsCtrl.text) ?? 1;
                setS(() => loading = true);
                try {
                  if (reason == null) {
                    await LocalDb().createQuickReason(selectedEmoji, labelCtrl.text.trim(), pts);
                  } else {
                    await LocalDb().updateQuickReason(reason.id, selectedEmoji, labelCtrl.text.trim(), pts);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } finally { setS(() => loading = false); }
              },
              child: loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(QuickReason r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('删除「${r.label}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    await LocalDb().deleteQuickReason(r.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('快速发分理由')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(),
        backgroundColor: kPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('添加理由', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reasons.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('⭐', style: TextStyle(fontSize: 48)), SizedBox(height: 12),
                  Text('还没有快速理由', style: TextStyle(color: Colors.grey)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _reasons.length,
                  itemBuilder: (ctx, i) {
                    final r = _reasons[i];
                    return Card(
                      child: ListTile(
                        leading: Text(r.emoji, style: const TextStyle(fontSize: 32)),
                        title: Text(r.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          r.points > 0 ? '+${r.points} 积分' : '${r.points} 积分',
                          style: TextStyle(color: r.points > 0 ? kGreen : Colors.red, fontWeight: FontWeight.w600),
                        ),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit, color: kPurple), onPressed: () => _showDialog(r)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _delete(r)),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
}
