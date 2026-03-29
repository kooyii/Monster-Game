import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../theme.dart';
import 'parent/parent_app.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});
  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  bool _isSettingPin = false;
  String _newPin = '';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkHasPin();
  }

  Future<void> _checkHasPin() async {
    final has = await ref.read(authProvider.notifier).hasPin();
    setState(() => _isSettingPin = !has);
  }

  void _onKey(String key) {
    if (key == '⌫') {
      if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
      return;
    }
    if (_pin.length >= 4) return;
    setState(() { _pin += key; _error = null; });
    if (_pin.length == 4) _onPinComplete();
  }

  Future<void> _onPinComplete() async {
    setState(() => _loading = true);
    if (_isSettingPin) {
      if (_newPin.isEmpty) {
        setState(() { _newPin = _pin; _pin = ''; _loading = false; });
        return;
      }
      if (_pin != _newPin) {
        setState(() { _pin = ''; _newPin = ''; _error = 'PIN 不一致，请重新设置'; _loading = false; });
        return;
      }
      await ref.read(authProvider.notifier).setPin(_pin);
      await ref.read(authProvider.notifier).loginWithPin(_pin);
    } else {
      final ok = await ref.read(authProvider.notifier).loginWithPin(_pin);
      if (!ok) {
        setState(() { _pin = ''; _error = 'PIN 错误，请重试'; _loading = false; });
        return;
      }
    }
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParentApp()));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dots = List.generate(4, (i) => i < _pin.length);
    final title = _isSettingPin
        ? (_newPin.isEmpty ? '设置家长 PIN 码' : '再次输入确认')
        : '输入家长 PIN 码';
    final subtitle = _isSettingPin
        ? (_newPin.isEmpty ? '请设置一个 4 位数字 PIN' : '请再次输入 $_newPin 以确认')
        : '请输入 4 位 PIN 解锁家长功能';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👨‍👩‍👧', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.white70), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                // Dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: dots.map((filled) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? Colors.white : Colors.white30,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  )).toList(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
                    child: Text(_error!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
                const SizedBox(height: 32),
                if (_loading)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  _NumPad(onKey: _onKey),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消', style: TextStyle(color: Colors.white70, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final void Function(String) onKey;
  const _NumPad({required this.onKey});

  @override
  Widget build(BuildContext context) {
    final keys = ['1','2','3','4','5','6','7','8','9','','0','⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      padding: const EdgeInsets.symmetric(horizontal: 60),
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox();
        return Material(
          color: Colors.white.withValues(alpha:0.2),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onKey(k),
            child: Center(
              child: Text(k, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
