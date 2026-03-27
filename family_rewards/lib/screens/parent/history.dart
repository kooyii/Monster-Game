import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models.dart';
import '../../theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<PointTransaction> _transactions = [];
  List<Child> _children = [];
  Child? _filterChild;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService().getTransactions(limit: 50, childId: _filterChild?.id),
        ApiService().getChildren(),
      ]);
      setState(() {
        _transactions = results[0] as List<PointTransaction>;
        _children = results[1] as List<Child>;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载失败: $e')));
    } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DropdownButtonFormField<Child?>(
              value: _filterChild,
              decoration: const InputDecoration(labelText: '筛选孩子（全部）', prefixIcon: Icon(Icons.filter_list)),
              items: [
                const DropdownMenuItem(value: null, child: Text('全部孩子')),
                ..._children.map((c) => DropdownMenuItem(value: c, child: Text('${c.avatarEmoji} ${c.name}'))),
              ],
              onChanged: (v) { setState(() => _filterChild = v); _load(); },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _transactions.isEmpty
                        ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('📊', style: TextStyle(fontSize: 48)), SizedBox(height: 12), Text('暂无记录', style: TextStyle(color: Colors.grey))]))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: _transactions.length,
                            itemBuilder: (ctx, i) => _TxCard(tx: _transactions[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final PointTransaction tx;
  const _TxCard({required this.tx});

  String _formatDate(String s) {
    try {
      final d = DateTime.parse(s).toLocal();
      return '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) { return s; }
  }

  @override
  Widget build(BuildContext context) {
    final isEarn = tx.points > 0;
    return Card(
      color: isEarn ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Text(tx.avatarEmoji ?? '🧒', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.childName ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(tx.description, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  Text(_formatDate(tx.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isEarn ? '+${tx.points}' : '${tx.points}',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: isEarn ? kGreen : Colors.redAccent),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isEarn ? kGreen.withOpacity(0.15) : Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(isEarn ? '获得' : '兑换', style: TextStyle(fontSize: 10, color: isEarn ? kGreen : Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
