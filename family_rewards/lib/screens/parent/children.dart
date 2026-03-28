import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models.dart';
import '../../theme.dart';

class ChildrenScreen extends StatefulWidget {
  const ChildrenScreen({super.key});
  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  List<Child> _children = [];
  bool _loading = true;

  final _avatars = ['😊', '😎', '🥳', '🤩', '😄', '🌟', '🦁', '🐯', '🐻', '🦊', '🐼', '🐸'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final c = await ApiService().getChildren();
      setState(() => _children = c);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载失败: $e')));
    } finally { setState(() => _loading = false); }
  }

  void _showAddDialog() => _showChildDialog(null);

  void _showChildDialog(Child? child) {
    final nameCtrl = TextEditingController(text: child?.name ?? '');
    String selectedEmoji = child?.avatarEmoji ?? '😊';
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(child == null ? '添加孩子' : '编辑 ${child.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar picker
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _avatars.map((e) => GestureDetector(
                    onTap: () => setS(() => selectedEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selectedEmoji == e ? kPurple.withValues(alpha:0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selectedEmoji == e ? kPurple : Colors.transparent, width: 2),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '姓名')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: loading ? null : () async {
                setS(() => loading = true);
                try {
                  if (child == null) {
                    await ApiService().createChild(nameCtrl.text.trim(), '', '', selectedEmoji);
                  } else {
                    await ApiService().updateChild(child.id, {'name': nameCtrl.text.trim(), 'avatar_emoji': selectedEmoji});
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('失败: $e')));
                } finally { setS(() => loading = false); }
              },
              child: loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Child child) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('删除 ${child.name}？'),
        content: Text('将永久删除 ${child.name} 的所有积分记录，无法恢复。'),
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
    try {
      await ApiService().deleteChild(child.id);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: kPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('添加孩子', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _children.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('👶', style: TextStyle(fontSize: 48)), SizedBox(height: 12), Text('还没有孩子账号', style: TextStyle(color: Colors.grey))]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _children.length,
                      itemBuilder: (ctx, i) {
                        final c = _children[i];
                        return Card(
                          child: ListTile(
                            leading: Text(c.avatarEmoji, style: const TextStyle(fontSize: 36)),
                            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${c.points} 积分', style: const TextStyle(color: kPurple, fontWeight: FontWeight.w600)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, color: kPurple), onPressed: () => _showChildDialog(c)),
                                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _delete(c)),
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
