import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../services/local_store.dart';
import '../widgets/fate_scaffold.dart';
import '../widgets/rules_sheet.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  DateTime? _birth;
  String _shichen = shichenList.first;
  final _emailCtrl = TextEditingController();

  Profile? _profile;
  bool _loading = true;
  bool _agree = false;
  String _msg = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await LocalStore.getOrCreateUserId();
    final p = await LocalStore.loadProfile();
    setState(() {
      _profile = p;
      _loading = false;
      if (p != null) {
        _birth = DateTime.tryParse(p.birthDate);
        _shichen = p.shichen.isNotEmpty ? p.shichen : shichenList.first;
        _emailCtrl.text = p.email;
        _agree = true;
      }
    });
    if (p != null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDate: DateTime(1990, 1, 1),
    );
    if (picked != null) setState(() => _birth = picked);
  }

  bool _isValidEmail(String s) {
    final t = s.trim();
    if (t.isEmpty) return false;
    // intentionally simple
    return t.contains('@') && t.contains('.') && t.length >= 6;
  }

  Future<void> _bind() async {
    setState(() => _msg = '');
    if (!_agree) {
      setState(() => _msg = '请先阅读并同意规则与隐私。');
      return;
    }
    if (_birth == null) {
      setState(() => _msg = '请先选择生日。');
      return;
    }
    final email = _emailCtrl.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _msg = '请填写有效邮箱（仅用于通知/找回，不对外展示）。');
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    // Lock logic (birth/shichen): allow changes only within 24h from first bind.
    final old = await LocalStore.loadProfile();
    final createdAt = old?.createdAt ?? now;
    final within24h = (now - createdAt) <= const Duration(hours: 24).inMilliseconds;

    final locked = old == null ? false : (!within24h || old.locked);

    if (old != null && locked) {
      setState(() => _msg = '绑定已锁定（超过24小时或已锁定）。如需更换，请重装后再绑定。');
      return;
    }

    final p = Profile(
      birthDate: DateFormat('yyyy-MM-dd').format(_birth!),
      shichen: _shichen,
      email: email,
      createdAt: createdAt,
      emailUpdatedAt: old?.emailUpdatedAt ?? now,
      locked: old == null ? false : true, // once updated within window -> lock
    );

    await LocalStore.saveProfile(p);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FateScaffold(
      showBack: false,
      title: '另一个我',
      actions: [
        IconButton(
          onPressed: () => RulesSheet.show(context),
          icon: const Icon(Icons.info_outline),
          tooltip: '规则与隐私',
        )
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('只给同年同月同日同一时辰的人写信。', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text(
                    '当你高兴、失落、无助、或者突然想留下些什么——\n'
                    '把它寄给“另一个你”。\n'
                    '对方接受之前，内容不会被看见。',
                    style: TextStyle(height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            title: const Text('生日'),
            subtitle: Text(_birth == null ? '点击选择' : DateFormat('yyyy-MM-dd').format(_birth!)),
            trailing: const Icon(Icons.calendar_month),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _shichen,
            items: shichenList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _shichen = v ?? shichenList.first),
            decoration: const InputDecoration(labelText: '时辰（子丑寅卯…亥）'),
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
          const SizedBox(height: 8),
          InkWell(
            onTap: () => RulesSheet.show(context),
            child: Row(
              children: [
                Checkbox(value: _agree, onChanged: (v) => setState(() => _agree = v ?? false)),
                const Expanded(child: Text('我已阅读并同意《规则与隐私》')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _bind,
            child: const Text('确认绑定（24小时内可改一次，之后锁定）'),
          ),
          const SizedBox(height: 8),
          Text(_msg, style: const TextStyle(color: Colors.red)),
          const Spacer(),
          const Text(
            '提示：本版本为本地演示。你现在看到的界面与流程，会按最终上架体验设计。',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
