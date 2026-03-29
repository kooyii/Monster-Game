import 'package:flutter/material.dart';
import '../../local_db.dart';
import '../../models.dart';
import '../../theme.dart';

class PunishmentsScreen extends StatefulWidget {
  const PunishmentsScreen({super.key});
  @override
  State<PunishmentsScreen> createState() => _PunishmentsScreenState();
}

class _PunishmentsScreenState extends State<PunishmentsScreen> {
  List<Punishment> _punishments = [];
  bool _loading = true;

  final _emojis = ['😅', '😬', '😤', '🏃', '🍽️', '📚', '🌙', '🧹', '💪', '🛏️', '🚿', '🙅'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await LocalDb().getPunishments();
    setState(() { _punishments = p; _loading = false; });
  }

  void _showDialog([Punishment? punishment]) {
    final emojiCtrl = TextEditingController(text: punishment?.emoji ?? '😅');
    final titleCtrl = TextEditingController(text: punishment?.title ?? '');
    final ptsCtrl = TextEditingController(text: punishment != null ? '${punishment.pointsDelta}' : '0');
    String selectedEmoji = punishment?.emoji ?? '😅';
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(punishment == null ? '添加惩罚' : '编辑惩罚'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji picker
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _emojis.map((e) => GestureDetector(
                    onTap: () => setS(() => selectedEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selectedEmoji == e ? Colors.red.shade50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selectedEmoji == e ? Colors.redAccent : Colors.transparent, width: 2),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '惩罚内容', hintText: '例：做20个深蹲')),
                const SizedBox(height: 10),
                TextField(
                  controller: ptsCtrl,
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  decoration: const InputDecoration(
                    labelText: '扣除积分（0表示仅任务，负数扣积分）',
                    hintText: '例：-1',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: loading ? null : () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final pts = int.tryParse(ptsCtrl.text) ?? 0;
                setS(() => loading = true);
                try {
                  if (punishment == null) {
                    await LocalDb().createPunishment(selectedEmoji, titleCtrl.text.trim(), pts);
                  } else {
                    await LocalDb().updatePunishment(punishment.id, selectedEmoji, titleCtrl.text.trim(), pts);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } finally {
                  setS(() => loading = false);
                }
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

  Future<void> _delete(Punishment p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('删除「${p.title}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await LocalDb().deletePunishment(p.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('管理惩罚项目')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(),
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('添加惩罚', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _punishments.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('😅', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('还没有惩罚项目', style: TextStyle(color: Colors.grey)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _punishments.length,
                  itemBuilder: (ctx, i) {
                    final p = _punishments[i];
                    return Card(
                      child: ListTile(
                        leading: Text(p.emoji, style: const TextStyle(fontSize: 32)),
                        title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          p.pointsDelta < 0 ? '扣 ${p.pointsDelta.abs()} 积分' : '仅任务，不扣分',
                          style: TextStyle(color: p.pointsDelta < 0 ? Colors.red : kGreen, fontWeight: FontWeight.w600),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showDialog(p)),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _delete(p)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
