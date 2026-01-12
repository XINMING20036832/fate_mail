import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../core/constants.dart';
import '../widgets/fate_background.dart';
import '../widgets/fate_card.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  DateTime? _selectedDate;
  String _shichen = shichenList.first;
  final _emailCtrl = TextEditingController();
  String _msg = '';

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final profile = await LocalStore.loadProfile();
    if (profile != null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  bool _isEmailValid(String s) {
    if (s.trim().isEmpty) return true; // optional
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(s.trim());
  }

  Future<void> _bind() async {
    if (_selectedDate == null) {
      setState(() => _msg = '先选出生日期。');
      return;
    }
    final email = _emailCtrl.text.trim();
    if (!_isEmailValid(email)) {
      setState(() => _msg = '邮箱格式不对（可留空）。');
      return;
    }

    final birthDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final profile = Profile(
      birthDate: birthDate,
      shichen: _shichen,
      boundAt: nowMs,
      fateEditsLeft: 1,
      notifyEmail: email,
      emailUpdatedAt: email.isEmpty ? 0 : nowMs,
    );
    await LocalStore.saveProfile(profile);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: FateBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 18),
                Text('另一个我', style: t.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  '同年同月同日、同一时辰的人，
可能在某些拐点里拥有相似的心事。',
                  style: TextStyle(color: scheme.onSurface.withOpacity(0.85), height: 1.3),
                ),
                const SizedBox(height: 14),
                FateCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('绑定你的时间坐标', style: t.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        '24小时内可改一次，之后锁定。\n这不是社交资料，只是“命运匹配坐标”。',
                        style: TextStyle(color: scheme.onSurface.withOpacity(0.75), fontSize: 13, height: 1.25),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(_selectedDate == null
                            ? '选择出生日期'
                            : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _shichen,
                        decoration: const InputDecoration(labelText: '选择出生时辰'),
                        items: shichenList
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _shichen = v ?? shichenList.first),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: '通知邮箱（可选）',
                          hintText: '用于接收提醒，不会展示给对方',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '邮箱24小时内只能改一次。\n未来用于通知你：有人接受了你的信。',
                        style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.7), height: 1.25),
                      ),
                      const SizedBox(height: 10),
                      if (_msg.isNotEmpty)
                        Text(_msg, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 6),
                      FilledButton(
                        onPressed: _bind,
                        child: const Text('确认绑定，进入写信'),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/rules'),
                          child: const Text('先看看规则与隐私 →'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '你写的，不是信息。\n是一封能被等待的信。',
                  style: TextStyle(color: scheme.onSurface.withOpacity(0.7), height: 1.25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
