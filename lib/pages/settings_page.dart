import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../services/local_store.dart';
import '../widgets/nebula_background.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Profile? _p;
  bool _loading = true;

  final _emailCtrl = TextEditingController();
  DateTime? _birth;
  String _shichen = shichenList.first;

  String _msg = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _validEmail(String s) => RegExp(r'^\S+@\S+\.\S+\$').hasMatch(s.trim());

  Future<void> _load() async {
    final p = await LocalStore.loadProfile();
    if (!mounted) return;
    setState(() {
      _p = p;
      _loading = false;
      _msg = '';
    });
    if (p != null) {
      _emailCtrl.text = p.email;
      _birth = DateTime.tryParse(p.birthDate);
      _shichen = p.shichen;
    }
  }

  bool get _profileEditable {
    final p = _p;
    if (p == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final inWindow = (now - p.createdAt) <= kProfileEditWindowMs;
    final remain = (kMaxProfileEditsInWindow - p.profileEditsUsed) > 0;
    return inWindow && remain;
  }

  String _profileLockHint() {
    final p = _p;
    if (p == null) return '';
    final now = DateTime.now().millisecondsSinceEpoch;
    final passed = now - p.createdAt;
    final left = kProfileEditWindowMs - passed;
    if (left <= 0) return '已锁定：绑定后 24 小时已过。';
    final h = (left / (60 * 60 * 1000)).floor();
    final m = ((left % (60 * 60 * 1000)) / (60 * 1000)).floor();
    final remainEdits = (kMaxProfileEditsInWindow - p.profileEditsUsed).clamp(0, 99);
    return '可修改：剩余 $remainEdits 次，剩余时间 ${h}h ${m}m';
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final init = _birth ?? DateTime(now.year - 20, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(dialogBackgroundColor: Colors.black87), child: child!),
    );
    if (picked != null) setState(() => _birth = picked);
  }

  Future<void> _saveProfile() async {
    setState(() => _msg = '');
    final p = _p;
    if (p == null) return;

    if (!_profileEditable) {
      setState(() => _msg = '出生信息已锁定。');
      return;
    }
    if (_birth == null) {
      setState(() => _msg = '请选择出生日期。');
      return;
    }

    final birthStr = DateFormat('yyyy-MM-dd').format(_birth!);
    final np = Profile(
      birthDate: birthStr,
      shichen: _shichen,
      email: p.email,
      createdAt: p.createdAt,
      profileEditsUsed: p.profileEditsUsed + 1,
      lastEmailChangeAt: p.lastEmailChangeAt,
    );
    await LocalStore.saveProfile(np);
    if (!mounted) return;
    setState(() {
      _p = np;
      _msg = '已保存（演示）。';
    });
  }

  Future<void> _saveEmail() async {
    setState(() => _msg = '');
    final p = _p;
    if (p == null) return;

    final email = _emailCtrl.text.trim();
    if (!_validEmail(email)) {
      setState(() => _msg = '邮箱格式不对。');
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if ((now - p.lastEmailChangeAt) < kEmailChangeCooldownMs) {
      final left = kEmailChangeCooldownMs - (now - p.lastEmailChangeAt);
      final h = (left / (60 * 60 * 1000)).floor();
      final m = ((left % (60 * 60 * 1000)) / (60 * 1000)).floor();
      setState(() => _msg = '邮箱 24 小时只能改一次。还剩 ${h}h ${m}m。');
      return;
    }

    final np = Profile(
      birthDate: p.birthDate,
      shichen: p.shichen,
      email: email,
      createdAt: p.createdAt,
      profileEditsUsed: p.profileEditsUsed,
      lastEmailChangeAt: now,
    );
    await LocalStore.saveProfile(np);
    if (!mounted) return;
    setState(() {
      _p = np;
      _msg = '邮箱已更新（演示）。';
    });
  }

  Future<void> _resetAll() async {
    await LocalStore.clearAll();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('设置')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (_p == null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('尚未绑定', style: TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 10),
                              FilledButton(
                                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                                child: const Text('去绑定'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('出生信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _profileEditable ? _pickBirth : null,
                                icon: const Icon(Icons.cake_outlined),
                                label: Text(_birth == null ? _p!.birthDate : DateFormat('yyyy-MM-dd').format(_birth!)),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value: _shichen,
                                items: shichenList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: _profileEditable ? (v) => setState(() => _shichen = v ?? shichenList.first) : null,
                                decoration: const InputDecoration(labelText: '时辰'),
                              ),
                              const SizedBox(height: 10),
                              Text(_profileLockHint(), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.65))),
                              const SizedBox(height: 10),
                              FilledButton(
                                onPressed: _profileEditable ? _saveProfile : null,
                                child: const Text('保存出生信息'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('邮箱（对方不可见）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: '邮箱',
                                  hintText: '24小时可改一次',
                                ),
                              ),
                              const SizedBox(height: 10),
                              FilledButton(
                                onPressed: _saveEmail,
                                child: const Text('更新邮箱'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('维护', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _resetAll,
                                icon: const Icon(Icons.restart_alt),
                                label: const Text('清空本机数据（重置）'),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '注意：这是本地演示版的重置按钮。正式版会上线后端账号体系。',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6), height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Text(_msg, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
