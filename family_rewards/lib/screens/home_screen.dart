import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../theme.dart';
import 'child_view_screen.dart';
import 'pin_screen.dart';
import 'parent/parent_app.dart';

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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 8),
                    const Text('家庭积分', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4C1D95))),
                    const Spacer(),
                    _ParentButton(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('👶', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('还没有孩子', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          Text('请家长登录后添加', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ]),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(publicChildrenProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: children.length,
                        itemBuilder: (ctx, i) => _ChildGrowthCard(child: children[i], rank: i + 1),
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

// ── Level system ──────────────────────────────────────────────────────────────
String _levelTitle(int pts) {
  if (pts >= 500) return '👑 传奇';
  if (pts >= 200) return '🏆 冠军';
  if (pts >= 100) return '💫 高手';
  if (pts >= 50)  return '🌟 进阶';
  if (pts >= 20)  return '⭐ 成长';
  return '🌱 新手';
}

Color _levelColor(int pts) {
  if (pts >= 500) return const Color(0xFFFF8C00);
  if (pts >= 200) return const Color(0xFF7C3AED);
  if (pts >= 100) return const Color(0xFF2563EB);
  if (pts >= 50)  return const Color(0xFF059669);
  if (pts >= 20)  return const Color(0xFF0891B2);
  return Colors.grey;
}

// Returns [currentInLevel, levelSize, nextThreshold]
List<int> _levelProgress(int pts) {
  const thresholds = [0, 20, 50, 100, 200, 500];
  for (int i = 0; i < thresholds.length - 1; i++) {
    if (pts < thresholds[i + 1]) {
      return [pts - thresholds[i], thresholds[i + 1] - thresholds[i], thresholds[i + 1]];
    }
  }
  return [pts - 500, 0, 0]; // max level
}

// ── Child growth card ─────────────────────────────────────────────────────────
class _ChildGrowthCard extends StatelessWidget {
  final Child child;
  final int rank;
  const _ChildGrowthCard({required this.child, required this.rank});

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(child.points);
    final progress = _levelProgress(child.points);
    final isMaxLevel = progress[1] == 0;
    final pct = isMaxLevel ? 1.0 : (progress[0] / progress[1]).clamp(0.0, 1.0);
    final medals = ['🥇', '🥈', '🥉'];
    final medal = rank <= 3 ? medals[rank - 1] : '#$rank';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: rank == 1 ? 4 : 1,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildViewScreen(child: child))),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank medal
              SizedBox(
                width: 32,
                child: Text(medal, style: const TextStyle(fontSize: 22), textAlign: TextAlign.center),
              ),
              const SizedBox(width: 12),
              // Avatar
              _ChildAvatar(child: child, size: 60),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(child.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: levelColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_levelTitle(child.points),
                              style: TextStyle(fontSize: 11, color: levelColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMaxLevel ? '已达最高等级 🎉' : '距下一级还差 ${progress[2] - child.points} 积分',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Points
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${child.points}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: levelColor)),
                  const Text('积分', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildAvatar extends StatelessWidget {
  final Child child;
  final double size;
  const _ChildAvatar({required this.child, required this.size});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = child.avatarPath != null && File(child.avatarPath!).existsSync();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _levelColor(child.points).withValues(alpha: 0.15),
      backgroundImage: hasPhoto ? FileImage(File(child.avatarPath!)) : null,
      child: hasPhoto ? null : Text(child.avatarEmoji, style: TextStyle(fontSize: size * 0.45)),
    );
  }
}

// ── Parent login button ───────────────────────────────────────────────────────
class _ParentButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider);
    return ElevatedButton.icon(
      onPressed: () {
        if (isLoggedIn) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentApp()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PinScreen()));
        }
      },
      icon: const Text('👨‍👩‍👧', style: TextStyle(fontSize: 16)),
      label: Text(isLoggedIn ? '控制台' : '家长'),
      style: ElevatedButton.styleFrom(
        backgroundColor: kPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }
}
