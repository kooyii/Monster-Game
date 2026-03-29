import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../local_db.dart';
import '../models.dart';

// ── Slot item types ───────────────────────────────────────────────────────────
enum _SlotType { reward, punishment, blank }

class _SlotItem {
  final _SlotType type;
  final String emoji;
  final String label;
  final int? rewardId;
  final int pointsDelta;

  const _SlotItem({
    required this.type,
    required this.emoji,
    required this.label,
    this.rewardId,
    this.pointsDelta = 0,
  });
}

// ── Main screen ───────────────────────────────────────────────────────────────
class LotteryScreen extends StatefulWidget {
  final Child child;
  const LotteryScreen({super.key, required this.child});

  @override
  State<LotteryScreen> createState() => _LotteryScreenState();
}

class _LotteryScreenState extends State<LotteryScreen> {
  late Child _child;
  List<Reward> _rewards = [];
  List<Punishment> _punishments = [];
  List<_SlotItem> _pool = [];
  bool _loading = true;
  bool _spinning = false;
  _SlotItem? _result;
  bool _showResult = false;

  // 3 reels, each tracks current index into _pool
  final List<int> _reelIdx = [0, 0, 0];
  final List<bool> _reelStopped = [false, false, false];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _child = widget.child;
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final rewards = await LocalDb().getRewards(allRewards: false);
    final punishments = await LocalDb().getPunishments();
    final child = await LocalDb().getChild(_child.id);
    setState(() {
      _rewards = rewards;
      _punishments = punishments;
      if (child != null) _child = child;
      _pool = _buildPool(rewards, punishments);
      _loading = false;
    });
  }

  List<_SlotItem> _buildPool(List<Reward> rewards, List<Punishment> punishments) {
    final pool = <_SlotItem>[
      const _SlotItem(type: _SlotType.blank, emoji: '💨', label: '空白'),
    ];
    for (final p in punishments) {
      pool.add(_SlotItem(type: _SlotType.punishment, emoji: p.emoji, label: p.title, pointsDelta: p.pointsDelta));
    }
    for (final r in rewards) {
      pool.add(_SlotItem(type: _SlotType.reward, emoji: r.emoji, label: r.name, rewardId: r.id));
    }
    return pool.isEmpty ? [const _SlotItem(type: _SlotType.blank, emoji: '💨', label: '空白')] : pool;
  }

  _SlotItem _pickResult() {
    final rng = Random();
    final roll = rng.nextDouble();

    // 10% blank
    if (roll < 0.10) {
      return _pool.firstWhere((i) => i.type == _SlotType.blank,
          orElse: () => const _SlotItem(type: _SlotType.blank, emoji: '💨', label: '空白'));
    }

    // 20% punishment
    if (roll < 0.30) {
      final items = _pool.where((i) => i.type == _SlotType.punishment).toList();
      if (items.isEmpty) return const _SlotItem(type: _SlotType.blank, emoji: '💨', label: '空白');
      return items[rng.nextInt(items.length)];
    }

    // 70% reward — inversely weighted by cost
    final rewardItems = _pool.where((i) => i.type == _SlotType.reward).toList();
    if (rewardItems.isEmpty) return const _SlotItem(type: _SlotType.blank, emoji: '💨', label: '空白');

    final weights = rewardItems.map((item) {
      final r = _rewards.firstWhere((r) => r.id == item.rewardId, orElse: () => _rewards.first);
      return 1.0 / r.pointsCost;
    }).toList();
    final total = weights.reduce((a, b) => a + b);
    double cum = 0;
    final rr = rng.nextDouble();
    for (int i = 0; i < rewardItems.length; i++) {
      cum += weights[i] / total;
      if (rr <= cum) return rewardItems[i];
    }
    return rewardItems.last;
  }

  Future<void> _spin() async {
    if (_child.points < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('积分不足！需要至少 2 积分才能抽奖')),
      );
      return;
    }
    _timer?.cancel();
    setState(() {
      _spinning = true;
      _showResult = false;
      _result = null;
      _reelStopped[0] = false;
      _reelStopped[1] = false;
      _reelStopped[2] = false;
    });

    await LocalDb().awardPoints(_child.id, -2, '抽奖消费');
    final result = _pickResult();
    final resultIdx = _pool.indexOf(result);

    int tick = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      tick++;
      setState(() {
        if (!_reelStopped[0]) _reelIdx[0] = (_reelIdx[0] + 1) % _pool.length;
        if (!_reelStopped[1]) _reelIdx[1] = (_reelIdx[1] + 1) % _pool.length;
        if (!_reelStopped[2]) _reelIdx[2] = (_reelIdx[2] + 1) % _pool.length;

        if (tick == 20) { _reelStopped[0] = true; _reelIdx[0] = resultIdx; }
        if (tick == 28) { _reelStopped[1] = true; _reelIdx[1] = resultIdx; }
        if (tick == 36) {
          _reelStopped[2] = true;
          _reelIdx[2] = resultIdx;
          timer.cancel();
          _onSpinDone(result);
        }
      });
    });
  }

  Future<void> _onSpinDone(_SlotItem result) async {
    if (result.type == _SlotType.punishment && result.pointsDelta < 0) {
      await LocalDb().awardPoints(_child.id, result.pointsDelta, result.label);
    }
    final child = await LocalDb().getChild(_child.id);
    if (mounted) {
      setState(() {
        if (child != null) _child = child;
        _result = result;
        _spinning = false;
        _showResult = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D001A),
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
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('⭐ ${_child.points}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text('🎰 幸运转盘', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('消耗 2 积分 · 当前 ${_child.points} 积分',
                      style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 24),

                  // ── Slot machine ──
                  _SlotMachine(pool: _pool, reelIdx: _reelIdx, reelStopped: _reelStopped),

                  const SizedBox(height: 20),

                  // ── Result banner ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _showResult && _result != null
                        ? _ResultBanner(result: _result!)
                        : const SizedBox(height: 72),
                  ),

                  const Spacer(),

                  // ── Spin button ──
                  GestureDetector(
                    onTap: _spinning ? null : _spin,
                    child: Container(
                      width: 160, height: 56,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: _spinning
                            ? const LinearGradient(colors: [Color(0xFF444444), Color(0xFF666666)])
                            : const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                        boxShadow: _spinning
                            ? []
                            : [BoxShadow(color: Colors.orange.withValues(alpha: 0.5), blurRadius: 16, spreadRadius: 2)],
                      ),
                      child: Center(
                        child: _spinning
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('SPIN  -2积分', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () => _showOdds(context),
                    child: const Text('查看概率 →', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }

  void _showOdds(BuildContext context) {
    List<double> weights = [];
    double total = 0;
    final rewardItems = _pool.where((i) => i.type == _SlotType.reward).toList();
    if (rewardItems.isNotEmpty && _rewards.isNotEmpty) {
      weights = rewardItems.map((item) {
        final r = _rewards.firstWhere((r) => r.id == item.rewardId, orElse: () => _rewards.first);
        return 1.0 / r.pointsCost;
      }).toList();
      total = weights.reduce((a, b) => a + b);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A003A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('抽奖概率', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('奖励所需积分越多，抽中概率越低', style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 16),
            _OddsRow('💨 空白', '10.0%', Colors.white38),
            _OddsRow('😅 惩罚（合计）', '20.0%', Colors.redAccent),
            if (rewardItems.isNotEmpty && total > 0) ...[
              const Divider(color: Colors.white12, height: 20),
              ...rewardItems.asMap().entries.map((e) {
                final pct = ((weights[e.key] / total) * 70).toStringAsFixed(1);
                final r = _rewards.firstWhere((r) => r.id == e.value.rewardId, orElse: () => _rewards.first);
                return _OddsRow('${e.value.emoji} ${e.value.label} (${r.pointsCost}积分)', '$pct%', const Color(0xFFFFD700));
              }),
            ] else
              const _OddsRow('（奖励栏为空，请先添加奖励）', '', Colors.white24),
          ],
        ),
      ),
    );
  }
}

// ── Slot machine widget ───────────────────────────────────────────────────────
class _SlotMachine extends StatelessWidget {
  final List<_SlotItem> pool;
  final List<int> reelIdx;
  final List<bool> reelStopped;

  const _SlotMachine({required this.pool, required this.reelIdx, required this.reelStopped});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0030),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.2), blurRadius: 16)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Reel row with center highlight
          Stack(
            alignment: Alignment.center,
            children: [
              // Highlight bar for center row
              Container(
                height: 72,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5), width: 1),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (i) => _Reel(
                  pool: pool,
                  centerIdx: reelIdx[i],
                  stopped: reelStopped[i],
                )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Reel separators label
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DividerLine(), SizedBox(width: 8),
              Text('中奖行', style: TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold)),
              SizedBox(width: 8), _DividerLine(),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();
  @override
  Widget build(BuildContext context) =>
      Container(width: 40, height: 1, color: const Color(0xFFFFD700).withValues(alpha: 0.4));
}

// ── Single reel ───────────────────────────────────────────────────────────────
class _Reel extends StatelessWidget {
  final List<_SlotItem> pool;
  final int centerIdx;
  final bool stopped;

  const _Reel({required this.pool, required this.centerIdx, required this.stopped});

  @override
  Widget build(BuildContext context) {
    if (pool.isEmpty) return const SizedBox(width: 90);
    final n = pool.length;
    final top = pool[(centerIdx - 1 + n * 100) % n];
    final mid = pool[centerIdx % n];
    final bot = pool[(centerIdx + 1) % n];

    return SizedBox(
      width: 90,
      child: Column(
        children: [
          _ReelCell(item: top, isCenter: false),
          _ReelCell(item: mid, isCenter: true),
          _ReelCell(item: bot, isCenter: false),
        ],
      ),
    );
  }
}

class _ReelCell extends StatelessWidget {
  final _SlotItem item;
  final bool isCenter;
  const _ReelCell({required this.item, required this.isCenter});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Center(
        child: Opacity(
          opacity: isCenter ? 1.0 : 0.25,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.emoji, style: TextStyle(fontSize: isCenter ? 36 : 24)),
              if (isCenter)
                Text(
                  item.label,
                  style: const TextStyle(fontSize: 9, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Result banner ─────────────────────────────────────────────────────────────
class _ResultBanner extends StatelessWidget {
  final _SlotItem result;
  const _ResultBanner({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isReward = result.type == _SlotType.reward;
    final isPunish = result.type == _SlotType.punishment;
    final color = isReward ? const Color(0xFFFFD700) : isPunish ? Colors.redAccent : Colors.white38;
    final bg = isReward ? const Color(0xFF3D2A00) : isPunish ? const Color(0xFF3A0000) : const Color(0xFF1A1A2E);
    final msg = isReward ? '🎉 恭喜！去找家长兑换' : isPunish ? '😅 运气不好，接受惩罚' : '💨 很遗憾，空白！下次加油';

    return Container(
      key: ValueKey(result.label),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Text(result.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
                Text(msg, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Odds row helper ───────────────────────────────────────────────────────────
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
