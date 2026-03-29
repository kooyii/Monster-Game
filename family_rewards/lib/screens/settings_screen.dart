import 'package:flutter/material.dart';
import 'parent/children.dart';
import 'parent/rewards.dart';
import 'parent/punishments_screen.dart';
import 'parent/quick_reasons_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const _SectionHeader('人员管理'),
          _SettingsTile(
            icon: Icons.people_outline,
            label: '孩子管理',
            subtitle: '添加、修改、删除孩子',
            color: const Color(0xFF7C3AED),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildrenScreen())),
          ),
          const _SectionHeader('奖励与惩罚'),
          _SettingsTile(
            icon: Icons.card_giftcard_outlined,
            label: '奖励管理',
            subtitle: '添加、修改、删除奖励项目',
            color: const Color(0xFF059669),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen())),
          ),
          _SettingsTile(
            icon: Icons.warning_amber_outlined,
            label: '惩罚管理',
            subtitle: '设置抽奖惩罚内容',
            color: Colors.redAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PunishmentsScreen())),
          ),
          const _SectionHeader('积分发放'),
          _SettingsTile(
            icon: Icons.bolt_outlined,
            label: '快速发分理由',
            subtitle: '自定义发放积分的快捷原因',
            color: const Color(0xFFF59E0B),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickReasonsScreen())),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
