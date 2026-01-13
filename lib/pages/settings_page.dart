import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../widgets/fate_scaffold.dart';
import '../widgets/rules_sheet.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _emailCtrl = TextEditingController();
  Profile? _p;
  String _msg = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await LocalStore.loadProfile();
    setState(() {
      _p = p;
      _emailCtrl.text = p?.email ?? '';
      _loading = false;
    });
  }

  bool _isValidEmail(String s) {
    final t = s.trim();
    return t.contains('@') && t.contains('.') && t.length >= 6;
  }

  Future<void> _saveEmail() async {
    setState(() => _msg = '');
    final p = _p;
    if (p == null) return;
    final email = _emailCtrl.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _msg = '邮箱格式不正确。');
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final can = (now - p.emailUpdatedAt) >= const Duration(hours: 24).inMilliseconds;
    if (!can) {
      final left = const Duration(hours: 24).inMilliseconds - (now - p.emailUpdatedAt);
      final h = (left / (1000 * 60 * 60)).ceil();
      setState(() => _msg = '24小时内只能改一次邮箱。约 $h 小时后可再修改。');
      return;
    }

    final next = Profile(
      birthDate: p.birthDate,
      shichen: p.shichen,
      email: email,
      createdAt: p.createdAt,
      emailUpdatedAt: now,
      locked: p.locked,
    );
    await LocalStore.saveProfile(next);
    setState(() {
      _p = next;
      _msg = '已保存。';
    });
  }

  Future<void> _resetHint() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('如需重置，请在系统设置里清除应用数据。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final p = _p;
    return FateScaffold(
      title: '设置',
      actions: [
        IconButton(
          onPressed: () => RulesSheet.show(context),
          icon: const Icon(Icons.info_outline),
          tooltip: '规则与隐私',
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (p != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text('你的命运坐标：${p.fateKey}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: '你的邮箱（仅用于通知/找回）',
              helperText: '不会对外展示；对方只会看到临时信箱（后端上线后生效）。',
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(onPressed: _saveEmail, child: const Text('保存邮箱（24小时内只能改一次）')),
          const SizedBox(height: 8),
          Text(_msg, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _resetHint, child: const Text('如何重置')),
          const Spacer(),
          const Text(
            '上架前你需要准备：隐私政策URL、用户协议、举报处理方式说明。',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
