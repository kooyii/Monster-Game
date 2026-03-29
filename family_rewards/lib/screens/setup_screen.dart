import 'package:flutter/material.dart';
import '../providers.dart';
import '../theme.dart';

class SetupScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SetupScreen({super.key, required this.onDone});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _userCtrl = TextEditingController(text: 'admin');
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _save() async {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    final pass2 = _pass2Ctrl.text;
    if (user.isEmpty || pass.isEmpty) {
      setState(() => _error = '请填写用户名和密码');
      return;
    }
    if (pass != pass2) {
      setState(() => _error = '两次密码不一致');
      return;
    }
    if (pass.length < 4) {
      setState(() => _error = '密码至少4位');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await saveParentAccount(user, pass);
      widget.onDone();
    } catch (e) {
      setState(() => _error = '保存失败: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 52)),
                      const SizedBox(height: 8),
                      const Text('家庭积分', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      const Text('首次使用，请创建家长账号', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _userCtrl,
                        decoration: const InputDecoration(labelText: '用户名', prefixIcon: Icon(Icons.person)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: '密码', prefixIcon: Icon(Icons.lock)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pass2Ctrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: '确认密码', prefixIcon: Icon(Icons.lock_outline)),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _save,
                          child: _loading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('创建账号并开始使用'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
