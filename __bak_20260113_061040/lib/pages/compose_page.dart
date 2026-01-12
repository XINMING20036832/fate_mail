import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/utils.dart';
import '../services/local_store.dart';
import '../models/models.dart';

class ComposePage extends StatefulWidget {
  const ComposePage({super.key});

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  final _extraCtrl = TextEditingController();
  String _state = '迷茫';
  String _pace = '慢慢写信';
  String _msg = '';
  bool _sending = false;

  final List<String> _states = const ['孤独', '迷茫', '焦虑', '平静', '想倾诉'];
  final List<String> _paces = const ['慢慢写信', '偶尔写', '只读不回也行'];

  @override
  void dispose() {
    _extraCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _msg = '';
      _sending = true;
    });

    final pending = await LocalStore.loadPending();
    // enforce 1 pending at a time
    final hasPending = pending.any((r) => r.status == 'pending');
    if (hasPending) {
      setState(() {
        _msg = '你已有一条正在等待对方决定的请求，不能同时撒网。';
        _sending = false;
      });
      return;
    }

    final wallet = await LocalStore.loadWallet();
    if (wallet.stamps <= 0) {
      setState(() {
        _msg = '邮票不足：请先购买邮票（6元/封）。';
        _sending = false;
      });
      return;
    }

    final extra = _extraCtrl.text.trim();
    if (containsExternalContact(extra)) {
      setState(() {
        _msg = '首封信禁止包含手机号/链接/微信等外联信息。';
        _sending = false;
      });
      return;
    }

    // consume 1 stamp for now (MVP local); production should be "pre-authorize" style
    await LocalStore.saveWallet(StampWallet(wallet.stamps - 1));

    final uid = await LocalStore.getOrCreateUserId();
    final profile = await LocalStore.loadProfile();
    final fateKey = '${profile?.birthDate ?? ''}|${profile?.shichen ?? ''}';
    final now = DateTime.now().millisecondsSinceEpoch;
    final req = MailRequest(
      id: now.toString(),
      fromUserId: uid,
      toUserId: 'FATE_MATCH_PLACEHOLDER',
      fateKey: fateKey,
      status: 'pending',
      createdAt: now,
      templateState: _state,
      templatePace: _pace,
      extraLine: extra,
    );

    pending.insert(0, req);
    await LocalStore.savePending(pending);

    // Also create a simulated incoming request (for demo)
    final incoming = await LocalStore.loadIncoming();
    final demoIncoming = MailRequest(
      id: (now + 1).toString(),
      fromUserId: 'demo_sender',
      toUserId: uid,
      fateKey: fateKey,
      status: 'pending',
      createdAt: now,
      templateState: '孤独',
      templatePace: '慢慢写信',
      extraLine: '同命的你，今天过得好吗？',
    );
    incoming.insert(0, demoIncoming);
    await LocalStore.saveIncoming(incoming);

    if (!mounted) return;
    setState(() => _sending = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('寄一封同命信')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('首封信使用模板（反骗子 + 社恐友好），对方接受后才可读。'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _state,
              items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _state = v ?? _states.first),
              decoration: const InputDecoration(labelText: '我现在的状态'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _pace,
              items: _paces.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _pace = v ?? _paces.first),
              decoration: const InputDecoration(labelText: '我希望的互动'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _extraCtrl,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: '给同命的你一句话（可空）',
                hintText: '不要写微信/手机号/链接',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _sending ? null : _send,
              child: Text(_sending ? '发送中...' : '支付邮票并寄出（6元/封）'),
            ),
            const SizedBox(height: 8),
            Text(_msg, style: const TextStyle(color: Colors.red)),
            const Spacer(),
            const Text('MVP提示：本地模拟会自动给你生成一条“收到的请求卡”用于演示。', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
