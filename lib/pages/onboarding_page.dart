import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../services/local_store.dart';
import '../widgets/nebula_background.dart';
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
  String _msg = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final p = await LocalStore.loadProfile();
    if (!mounted) return;
    if (p != null) {
      // already bound
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }
    setState(() => _loading = false);
  }

  bool _validEmail(String s) {
    final t = s.trim();
    if (t.isEmpty) return false;
    return RegExp(r'^\S+@\S+\.\S+\$').hasMatch(t);
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final init = _birth ?? DateTime(now.year - 20, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      builder: (ctx, child) {
        return Theme(data: Theme.of(ctx).copyWith(dialogBackgroundColor: Colors.black87), child: child!);
      },
    );
    if (picked != null) setState(() => _birth = picked);
  }

  Future<void> _bind() async {
    setState(() => _msg = '');
    if (_birth == null) {
      setState(() => _msg = '请选择出生日期。');
      return;
    }
    if (!_validEmail(_emailCtrl.text)) {
      setState(() => _msg = '请填写有效邮箱（用于收取必要通知；对方不可见）。');
      return;
    }

    final birthStr = DateFormat('yyyy-MM-dd').format(_birth!);
    final now = DateTime.now().millisecondsSinceEpoch;
    final p = Profile(
      birthDate: birthStr,
      shichen: _shichen,
      email: _emailCtrl.text.trim(),
      createdAt: now,
      profileEditsUsed: 0,
      lastEmailChangeAt: now,
    );
    await LocalStore.saveProfile(p);
    await LocalStore.getOrCreateUserId();
    await LocalStore.saveWallet(StampWallet(0));
    await LocalStore.savePending(<MailRequest>[]);
    await LocalStore.saveIncoming(<MailRequest>[]);
    await LocalStore.saveMailbox(<MailItem>[]);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NebulaBackground(
      padding: true,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('另一个我', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      onPressed: () => showRulesSheet(context),
                      icon: const Icon(Icons.info_outline),
                      tooltip: '规则',
                    ),
                  ],
                ),
                Text(
                  '把一封信寄给 “同一刻出生的你”。\n不是社交，是一种被命运回声回应的感觉。',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.75), height: 1.5),
                ),
                const SizedBox(height: 18),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('绑定出生信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pickBirth,
                          icon: const Icon(Icons.cake_outlined),
                          label: Text(_birth == null ? '选择出生日期' : DateFormat('yyyy-MM-dd').format(_birth!)),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _shichen,
                          items: shichenList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setState(() => _shichen = v ?? shichenList.first),
                          decoration: const InputDecoration(labelText: '出生时辰'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: '你的邮箱（对方不可见）',
                            hintText: '用于收取必要通知；24小时可改一次',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _bind,
                          child: const Text('确认绑定（24小时内可改一次，之后锁定）'),
                        ),
                        const SizedBox(height: 8),
                        Text(_msg, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ),

                const Spacer(),
                Text(
                  '提示：MVP 阶段不做公开广场，不做刷人，只做一对一的“命运信箱”。',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.55)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}
