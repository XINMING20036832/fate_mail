import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../services/local_store.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  DateTime? _birth;
  String _shichen = shichenList.first;
  Profile? _profile;
  bool _loading = true;
  bool _locked = false;
  String _msg = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await LocalStore.getOrCreateUserId();
    final p = await LocalStore.loadProfile();
    setState(() {
      _profile = p;
      _locked = p?.locked ?? false;
      _loading = false;
    });
    if (p != null) {
      // already bound
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

  Future<void> _bind() async {
    if (_birth == null) {
      setState(() => _msg = '请先选择生日');
      return;
    }
    final dateStr = DateFormat('yyyy-MM-dd').format(_birth!);
    final profile = Profile(birthDate: dateStr, shichen: _shichen, locked: true);
    await LocalStore.saveProfile(profile);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('绑定命运坐标')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('只给同年同月同日同一时辰的人写信。', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _bind,
              child: const Text('确认绑定（24小时内可改一次，之后锁定）'),
            ),
            const SizedBox(height: 8),
            Text(_msg, style: const TextStyle(color: Colors.red)),
            const Spacer(),
            const Text('提示：MVP阶段不做公开广场、不做刷人，只做一对一慢信箱。', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
