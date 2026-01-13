\
import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../core/constants.dart';
import '../widgets/fate_scaffold.dart';
import '../widgets/fate_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Profile? _p;
  DateTime? _picked;
  String _shichen = shichenList.first;
  final _emailCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await LocalStore.loadProfile();
    if (!mounted) return;
    setState(() {
      _p = p;
      _loading = false;
    });

    if (p != null) {
      _shichen = p.shichen.isNotEmpty ? p.shichen : shichenList.first;
      _emailCtrl.text = p.email;
      _picked = _tryParse(p.birthDate);
    }
  }

  DateTime? _tryParse(String s) {
    final parts = s.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  String _fmt(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _picked ?? DateTime(now.year - 20);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _picked = picked);
  }

  void _toast(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> _save() async {
    final p0 = _p;
    if (p0 == null) {
      _toast('还未绑定，请先回到开始页面绑定');
      return;
    }
    if (_picked == null) {
      _toast('出生日期不能为空');
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final newBirth = _fmt(_picked!);
    final newShi = _shichen;
    final newEmail = _emailCtrl.text.trim();

    // --- 坐标修改规则 ---
    final coordChanged = (newBirth != p0.birthDate) || (newShi != p0.shichen);
    int boundAt = p0.boundAtMs > 0 ? p0.boundAtMs : nowMs;
    int coordEdits = p0.coordEditCount;

    if (coordChanged) {
      if (!p0.canEditCoord(nowMs: nowMs)) {
        _toast('命运坐标已锁定（24小时过期或已改过一次）');
        return;
      }
      coordEdits = 1; // 允许一次：用完就锁
    }

    final coordExpired = (nowMs - boundAt) > 24 * 60 * 60 * 1000;
    final locked = coordExpired || coordEdits >= 1;

    // --- 邮箱修改规则 ---
    final emailChanged = newEmail != p0.email;
    int emailSetAt = p0.emailSetAtMs;
    int emailEdits = p0.emailEditCount;

    if (emailChanged) {
      if (!p0.canEditEmail(nowMs: nowMs)) {
        _toast('邮箱已锁定（24小时过期或已改过一次）');
        return;
      }
      if (emailSetAt == 0) {
        emailSetAt = nowMs; // 首次设置
      } else {
        emailEdits = 1; // 允许一次：用完就锁
      }
    }

    final next = p0.copyWith(
      birthDate: newBirth,
      shichen: newShi,
      boundAtMs: boundAt,
      coordEditCount: coordEdits,
      locked: locked,
      email: newEmail,
      emailSetAtMs: emailSetAt,
      emailEditCount: emailEdits,
    );

    await LocalStore.saveProfile(next);
    if (!mounted) return;
    setState(() => _p = next);
    _toast('已保存');
  }

  String _leftText(Profile p) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final coordLeft = p.canEditCoord(nowMs: nowMs) ? '可改 1 次' : '已锁定';
    final emailLeft = p.canEditEmail(nowMs: nowMs) ? (p.emailSetAtMs == 0 ? '可设置' : '可改 1 次') : '已锁定';

    return '命运坐标：$coordLeft · 邮箱：$emailLeft';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final p = _p;
    return FateScaffold(
      title: '资料',
      actions: [
        IconButton(
          tooltip: '规则',
          onPressed: () => Navigator.pushNamed(context, '/rules'),
          icon: const Icon(Icons.auto_awesome),
        )
      ],
      body: ListView(
        children: [
          if (p != null)
            FateCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('当前', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('${p.birthDate} · ${p.shichen}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(_leftText(p), style: TextStyle(color: Colors.white.withOpacity(0.75))),
                ],
              ),
            ),
          const SizedBox(height: 14),
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('命运坐标', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: (p != null && !p.canEditCoord()) ? null : _pickDate,
                  icon: const Icon(Icons.cake),
                  label: Text(_picked == null ? '选择出生日期' : _fmt(_picked!)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _shichen,
                  items: shichenList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (p != null && !p.canEditCoord()) ? null : (v) => setState(() => _shichen = v ?? _shichen),
                  decoration: const InputDecoration(labelText: '出生时辰'),
                ),
                const SizedBox(height: 10),
                Text(
                  '绑定后 24 小时内可改 1 次。它是“投递地址”，改完就会锁定。',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), height: 1.25),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('邮箱（默认隐藏）', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  enabled: (p == null) ? false : p.canEditEmail(),
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '邮箱',
                    hintText: '双方同意后才会互相看到',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '邮箱不参与匹配，只用于“双方同意后建立联系”。\n'
                  '设置后 24 小时内可改 1 次；之后锁定。',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), height: 1.25),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
