import 'package:flutter/material.dart';
import 'dart:math';
import '../local_db.dart';
import '../models.dart';

class LotteryScreen extends StatefulWidget {
  final Child child;
  const LotteryScreen({super.key, required this.child});

  @override
  State<LotteryScreen> createState() => _LotteryScreenState();
}

class _LotteryScreenState extends State<LotteryScreen> with SingleTickerProviderStateMixin {
  late Child _child;
  List<Reward> _rewards = [];
  bool _loading = true;
  bool _spinning = false;
  _LotteryResult? _result;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _child = widget.child;
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    _load();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rewards = await LocalDb().getRewards(allRewards: false);
    final child = await LocalDb().getChild(_child.id);
    setState(() {
      _rewards = rewards;
      if (child != null) _child = child;
      _loading = false;
    });
  }

  Future<void> _spin() async {
    if (_child.points < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('积分不足！需要至少 2 积分才能抽奖')),
      );
      return;
    }
    setState(() { _spinning = true; _result = null; });

    // Deduct 2 points for lottery
    await LocalDb().awardPoints(_child.id, -2, '抽奖消费');

    // Calculate result
    final result = _calculateResult();

    // Apply point deduction if punishment
    if (result.type == _ResultType.punishment && result.pointsDelta < 0) {
      await LocalDb().awardPoints(_child.id, result.pointsDelta, result.title);
    }

    // Refresh child balance
    final child = await LocalDb().getChild(_child.id);
    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted) {
      setState(() {
        if (child != null) _child = child;
        _result = result;
        _spinning = false;
      });
      _animController.forward(from: 0);
    }
  }

  _LotteryResult _calculateResult() {
    final rng = Random();
    final roll = rng.nextDouble();

    // 10% blank
    if (roll < 0.10) return _blankResult();
    // 10% punishment
    if (roll < 0.20) return _punishmentResult(rng);
    // 80% rewards (inverse weight by cost)
    if (_rewards.isEmpty) return _blankResult();

    final weights = _rewards.map((r) => 1.0 / r.pointsCost).toList();
    final total = weights.reduce((a, b) => a + b);

    double cumulative = 0.20;
    for (int i = 0; i < _rewards.length; i++) {
      cumulative += (weights[i] / total) * 0.80;
      if (roll <= cumulative) {
        return _LotteryResult(
          type: _ResultType.reward,
          emoji: _rewards[i].emoji,
          title: '恭喜获得 ${_rewards[i].name}！',
          subtitle: '去找家长兑换吧 🎉',
          pointsDelta: 0,
        );
      }
    }
    final last = _rewards.last;
    return _LotteryResult(
      type: _ResultType.reward,
      emoji: last.emoji,
      title: '恭喜获得 ${last.name}！',
      subtitle: '去找家长兑换吧 🎉',
      pointsDelta: 0,
    );
  }

  _LotteryResult _blankResult() => const _LotteryResult(
    type: _ResultType.blank,
    emoji: '💨',
    title: '很遗憾，空白',
    subtitle: '继续努力，下次好运！',
    pointsDelta: 0,
  );

  _LotteryResult _punishmentResult(Random rng) {
    const list = [
      _LotteryResult(type: _ResultType.punishment, emoji: '😅', title: '扣1积分', subtitle: '下次要努力哦！', pointsDelta: -1),
      _LotteryResult(type: _ResultType.punishment, emoji: '😬', title: '扣2积分', subtitle: '哎呀，运气不好！', pointsDelta: -2),
      _LotteryResult(type: _ResultType.punishment, emoji: '🏃', title: '做20个深蹲', subtitle: '运动一下，加油！', pointsDelta: 0),
      _LotteryResult(type: _ResultType.punishment, emoji: '🍽️', title: '帮忙洗碗一次', subtitle: '帮帮家人吧！', pointsDelta: 0),
      _LotteryResult(type: _ResultType.punishment, emoji: '📚', title: '额外读书20分钟', subtitle: '多读书长知识！', pointsDelta: 0),
      _LotteryResult(type: _ResultType.punishment, emoji: '🌙', title: '今晚早睡30分钟', subtitle: '早睡早起身体好！', pointsDelta: 0),
    ];
    return list[rng.nextInt(list.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0533),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('${_child.avatarEmoji} ${_child.name} 的抽奖'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('⭐ ${_child.points} 积分', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎰', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 8),
                    const Text('幸运抽奖', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('消耗 2 积分 · 当前 ${_child.points} 积分',
                        style: const TextStyle(color: Colors.white60, fontSize: 14)),
                    const SizedBox(height: 40),

                    // Result area
                    SizedBox(
                      height: 160,
                      child: _spinning
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700), strokeWidth: 3))
                          : _result == null
                              ? const SizedBox()
                              : ScaleTransition(
                                  scale: _scaleAnim,
                                  child: _ResultCard(result: _result!),
                                ),
                    ),

                    const SizedBox(height: 40),

                    // Spin button
                    GestureDetector(
                      onTap: _spinning ? null : _spin,
                      child: Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(colors: [Color(0xFFFFE066), Color(0xFFFF9800)]),
                          boxShadow: _spinning
                              ? []
                              : [BoxShadow(color: Colors.orange.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 4)],
                        ),
                        child: Center(
                          child: _spinning
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                              : const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🎲', style: TextStyle(fontSize: 36)),
                                    Text('抽奖', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                                    Text('-2积分', style: TextStyle(fontSize: 11, color: Colors.white70)),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => _showOdds(context),
                      child: const Text('查看概率 →', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showOdds(BuildContext context) {
    List<double> weights = [];
    double total = 0;
    if (_rewards.isNotEmpty) {
      weights = _rewards.map((r) => 1.0 / r.pointsCost).toList();
      total = weights.reduce((a, b) => a + b);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D1B4E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('抽奖概率说明', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('奖励所需积分越多，中奖概率越低', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 16),
            _OddsRow('💨 空白', '10.0%', Colors.white54),
            _OddsRow('😅 惩罚', '10.0%', Colors.redAccent),
            if (_rewards.isNotEmpty) ...[
              const Divider(color: Colors.white24, height: 20),
              ..._rewards.asMap().entries.map((e) {
                final pct = ((weights[e.key] / total) * 80).toStringAsFixed(1);
                return _OddsRow('${e.value.emoji} ${e.value.name} (${e.value.pointsCost}积分)', '$pct%', const Color(0xFFFFD700));
              }),
            ] else
              const _OddsRow('（暂无奖励，请家长先添加）', '', Colors.white38),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final _LotteryResult result;
  const _ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final bgColor = result.type == _ResultType.reward
        ? const Color(0xFFFFD700)
        : result.type == _ResultType.punishment
            ? const Color(0xFFFF6B6B)
            : Colors.white24;
    final textColor = result.type == _ResultType.blank ? Colors.white : Colors.black87;
    final subColor = result.type == _ResultType.blank ? Colors.white60 : Colors.black54;

    return Container(
      width: 260, height: 155,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(result.emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 6),
          Text(result.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(result.subtitle, style: TextStyle(fontSize: 12, color: subColor), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _OddsRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _OddsRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 13))),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

enum _ResultType { reward, punishment, blank }

class _LotteryResult {
  final _ResultType type;
  final String emoji, title, subtitle;
  final int pointsDelta;
  const _LotteryResult({required this.type, required this.emoji, required this.title, required this.subtitle, required this.pointsDelta});
}
