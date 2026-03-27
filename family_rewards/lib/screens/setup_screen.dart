import 'package:flutter/material.dart';
import '../api_service.dart';
import '../providers.dart';
import '../theme.dart';

class SetupScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SetupScreen({super.key, required this.onDone});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _urlCtrl = TextEditingController(text: 'http://192.168.1.');
  final _userCtrl = TextEditingController(text: 'admin');
  final _passCtrl = TextEditingController(text: 'family2024');
  bool _loading = false;
  String? _error;

  Future<void> _connect() async {
    final url = _urlCtrl.text.trim().replaceAll(RegExp(r'/$'), '');
    if (!url.startsWith('http')) {
      setState(() => _error = '请输入完整地址，如 http://192.168.1.5:3000');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await saveServerUrl(url);
      await ApiService().login(_userCtrl.text.trim(), _passCtrl.text);
      widget.onDone();
    } catch (e) {
      setState(() => _error = '连接失败，请检查地址和账号密码\n$e');
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
                      const Text('首次使用，请设置服务器地址', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _urlCtrl,
                        decoration: const InputDecoration(
                          labelText: '服务器地址',
                          hintText: 'http://192.168.1.5:3000',
                          prefixIcon: Icon(Icons.computer),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('家长账号', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      ),
                      const SizedBox(height: 8),
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
                          onPressed: _loading ? null : _connect,
                          child: _loading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('连接并开始使用'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '💡 提示：电脑上启动服务后，控制台会显示手机访问地址',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
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
