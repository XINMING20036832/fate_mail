import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../core/constants.dart';
import '../widgets/fate_background.dart';
import '../widgets/fate_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Profile? _profile;
  bool _loading = true;
  final _emailCtrl = TextEditingController();

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
      _profile = p;
      _emailCtrl.text = p?.notifyEmail ?? '';
      _loading = false;
    });
  }

  bool _canEditFate(Profile p) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return p.fateEditsLeft > 0 && (nowMs - p.boundAt) <= 24 * 60 * 60 * 1000;
  }

  Duration _fateTimeLeft(Profile p) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final leftMs = (p.boundAt + 24 * 60 * 60 * 1000) - nowMs;
    return Duration(milliseconds: leftMs < 0 ? 0 : leftMs);
  }

  bool _canEditEmail(Profile p) {
    if (p.emailUpdatedAt <= 0) return true;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return (nowMs - p.emailUpdatedAt) >= 24 * 60 * 60 * 1000;
  }

  Duration _emailTimeLeft(Profile p) {
    if (p.emailUpdatedAt <= 0) return Duration.zero;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final leftMs = (p.emailUpdatedAt + 24 * 60 * 60 * 1000) - nowMs;
    return Duration(milliseconds: leftMs < 0 ? 0 : leftMs);
  }

  Future<void> _editFate(Profile p) async {
    final dateFmt = DateFormat('yyyy-MM-dd');
    var selectedDate = DateTime.tryParse(p.birthDate) ?? DateTime(2000, 1, 1);
    var shichen = p.shichen;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 10,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('修改命运坐标', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text('你只有一次修改机会（且必须在绑定后 24 小时内）。'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(dateFmt.format(selectedDate)),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setStateModal(() => selectedDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: shichen,
                          decoration: const InputDecoration(labelText: '时辰'),
                          items: shichenList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setStateModal(() => shichen = v ?? shichen),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('确认修改（消耗一次机会）'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (ok == true) {
      final updated = p.copyWith(
        birthDate: dateFmt.format(selectedDate),
        shichen: shichen,
        fateEditsLeft: (p.fateEditsLeft - 1).clamp(0, 1),
      );
      await LocalStore.saveProfile(updated);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已修改命运坐标（机会已用完）')));
    }
  }

  Future<void> _saveEmail(Profile p) async {
    final email = _emailCtrl.text.trim();
    final updated = p.copyWith(
      notifyEmail: email,
      emailUpdatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await LocalStore.saveProfile(updated);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存（24小时内仅可再改一次）')));
  }

  Future<void> _resetAll() async {
    await LocalStore.resetAll();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final p = _profile;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: FateBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FateCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, color: scheme.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '我们只需要你的“时间坐标”，用于匹配。\n邮箱只是通知用，永远不会直接展示给对方。',
                          style: TextStyle(height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (p != null) ...[
                  FateCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('命运坐标', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text('生日：${p.birthDate}'),
                        Text('时辰：${p.shichen}'),
                        const SizedBox(height: 10),
                        Builder(builder: (_) {
                          final can = _canEditFate(p);
                          final left = _fateTimeLeft(p);
                          final leftText = can
                              ? '剩余 ${left.inHours} 小时可改，次数：${p.fateEditsLeft}'
                              : '已锁定（次数：${p.fateEditsLeft}）';
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  leftText,
                                  style: TextStyle(color: scheme.onSurface.withOpacity(0.7), fontSize: 12),
                                ),
                              ),
                              TextButton(
                                onPressed: can ? () => _editFate(p) : null,
                                child: const Text('修改'),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FateCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('通知邮箱（可选）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: '你的邮箱',
                            hintText: '用于通知，不会展示给对方',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Builder(builder: (_) {
                          final can = _canEditEmail(p);
                          final left = _emailTimeLeft(p);
                          final leftText = can
                              ? '现在可以修改（24小时内最多改一次）'
                              : '还需等待 ${left.inHours} 小时才能再次修改';
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  leftText,
                                  style: TextStyle(color: scheme.onSurface.withOpacity(0.7), fontSize: 12),
                                ),
                              ),
                              FilledButton(
                                onPressed: can ? () => _saveEmail(p) : null,
                                child: const Text('保存'),
                              ),
                            ],
                          );
                        })
                      ],
                    ),
                  ),
                ] else ...[
                  const FateCard(child: Text('未绑定。请返回首页完成绑定。')),
                ],
                const SizedBox(height: 12),
                FateCard(
                  child: Row(
                    children: [
                      const Expanded(child: Text('规则与隐私')),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/rules'),
                        child: const Text('打开'),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FateCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('危险操作', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(
                        '清空全部数据（包含坐标、信箱、邮票）。\n仅用于你需要重新开始时。',
                        style: TextStyle(color: scheme.onSurface.withOpacity(0.75), height: 1.3),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('清空全部数据'),
                          onPressed: _resetAll,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
