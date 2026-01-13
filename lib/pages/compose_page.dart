import 'package:flutter/material.dart';
import '../core/utils.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../widgets/fate_scaffold.dart';
import '../widgets/rules_sheet.dart';

class ComposePage extends StatefulWidget {
  const ComposePage({super.key});

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  final _extraCtrl = TextEditingController();
  String _state = '迷茫';
  String _pace = '慢一点';
  bool _sending = false;
  String _msg = '';

  @override
  void dispose() {
    _extraCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _msg = '');
    final text = _extraCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _msg = '写点什么吧。');
      return;
    }
    if (containsExternalContact(text)) {
      setState(() => _msg = '信里禁止外部联系方式（微信/号码/链接/邮箱等）。');
      return;
    }

    final w = await LocalStore.loadWallet();
    if (w.stamps <= 0) {
      setState(() => _msg = '邮票不足，请先购买。');
      return;
    }

    setState(() => _sending = true);

    // Deduct 1 stamp
    await LocalStore.saveWallet(StampWallet(w.stamps - 1));

    // MVP：本地模拟生成“待决定请求”与“收到请求卡”
    final uid = await LocalStore.getOrCreateUserId();
    final p = await LocalStore.loadProfile();
    final fateKey = p?.fateKey ?? 'unknown';

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final req = MailRequest(
      id: id,
      fromUserId: uid,
      toUserId: 'peer',
      fateKey: fateKey,
      status: 'pending',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      templateState: _state,
      templatePace: _pace,
      extraLine: text,
    );

    final pending = await LocalStore.loadPending();
    await LocalStore.savePending([req, ...pending]);

    final incoming = await LocalStore.loadIncoming();
    await LocalStore.saveIncoming([req, ...incoming]);

    if (!mounted) return;
    setState(() {
      _sending = false;
      _extraCtrl.clear();
      _msg = '已寄出（演示）：等待对方决定。拒绝/超时会退回邮票。';
    });
  }

  @override
  Widget build(BuildContext context) {
    return FateScaffold(
      title: '写信',
      actions: [
        IconButton(onPressed: () => RulesSheet.show(context), icon: const Icon(Icons.info_outline)),
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
                  Text('写给“另一个你”', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text('对方接受之前，看不到内容。', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _state,
            items: const ['迷茫', '开心', '失落', '愤怒', '平静']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _state = v ?? '迷茫'),
            decoration: const InputDecoration(labelText: '我此刻的状态'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _pace,
            items: const ['慢一点', '正常', '快一点']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _pace = v ?? '慢一点'),
            decoration: const InputDecoration(labelText: '希望对方多久后回复'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _extraCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: '信的内容（禁止外部联系方式）',
              hintText: '把你想对另一个自己说的话写下来…',
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _sending ? null : _send,
            child: Text(_sending ? '寄出中...' : '支付 1 枚邮票并寄出'),
          ),
          const SizedBox(height: 8),
          Text(_msg, style: const TextStyle(color: Colors.red)),
          const Spacer(),
          const Text('提示：本地演示会自动生成一条“收到的请求卡”用于展示流程。', style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}
