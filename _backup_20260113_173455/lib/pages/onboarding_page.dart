\
import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../core/constants.dart';
import '../widgets/fate_scaffold.dart';
import '../widgets/fate_card.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  DateTime? _picked;
  String _shichen = shichenList.first;
  final _emailCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final p = await LocalStore.loadProfile();
    if (!mounted) return;
    if (p != null && p.birthDate.isNotEmpty && p.shichen.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }
    setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _picked = picked);
  }

  String _fmt(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _bind() async {
    if (_picked == null) {
      _toast('先选择出生日期');
      return;
    }
    final birth = _fmt(_picked!);
    final email = _emailCtrl.text.trim();

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final p = Profile(
      birthDate: birth,
      shichen: _shichen,
      boundAtMs: nowMs,
      coordEditCount: 0,
      locked: false,
      email: email,
      emailSetAtMs: email.isEmpty ? 0 : nowMs,
      emailEditCount: 0,
    );
    await LocalStore.saveProfile(p);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _toast(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FateScaffold(
      title: '开始',
      actions: [
        IconButton(
          tooltip: '规则',
          onPressed: () => Navigator.pushNamed(context, '/rules'),
          icon: const Icon(Icons.auto_awesome),
        )
      ],
      body: ListView(
        children: [
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('找到“同命”的那个人', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  '只要出生在同年同月同日、同一时辰，人生常常会出现奇妙的相似。\n'
                  '你写下的信，会被投递到那个“另一个我”。',
                  style: TextStyle(color: Colors.white.withOpacity(0.80), height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('你的命运坐标', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.cake),
                  label: Text(_picked == null ? '选择出生日期' : _fmt(_picked!)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _shichen,
                  items: shichenList
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _shichen = v ?? shichenList.first),
                  decoration: const InputDecoration(labelText: '出生时辰'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '邮箱（选填）',
                    hintText: '用于未来双方同意后建立联系',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '提示：命运坐标与邮箱，绑定后 24 小时内各可改 1 次；之后会自动锁定。',
                  style: TextStyle(color: Colors.white.withOpacity(0.75)),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _bind,
                  child: const Text('确认绑定'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '我们不阅读你的信，不向任何人展示你的邮箱。\n'
            '邮箱默认隐藏，只有双方都“愿意公开”时才会互相看到。',
            style: TextStyle(color: Colors.white.withOpacity(0.70), height: 1.3),
          ),
        ],
      ),
    );
  }
}
