import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../services/local_store.dart';
import '../widgets/nebula_background.dart';
import '../widgets/rules_sheet.dart';

class ComposePage extends StatefulWidget {
  const ComposePage({super.key});

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  final _bodyCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();

  final _states = const ['迷茫', '开心', '低谷', '想要突破', '想倾诉', '想庆祝'];
  final _paces = const ['随缘即可', '希望认真回复', '只想被看见', '可以深聊', '慢慢来'];

  String _state = '迷茫';
  String _pace = '随缘即可';
  bool _sending = false;
  String _msg = '';

  Future<void> _send() async {
    setState(() => _msg = '');
    final profile = await LocalStore.loadProfile();
    if (profile == null) {
      setState(() => _msg = '请先绑定出生信息。');
      return;
    }

    final wallet = await LocalStore.loadWallet();
    if (wallet.stamps <= 0) {
      setState(() => _msg = '邮票不足。请先购买邮票。');
      return;
    }

    final pending = await LocalStore.loadPending();
    if (pending.any((e) => e.status == RequestStatus.pending)) {
      setState(() => _msg = '你已经在等待一个决定。为了反撒网：同一时间只能等待 1 个决定。');
      return;
    }

    final body = _bodyCtrl.text.trim();
    if (body.length < 20) {
      setState(() => _msg = '至少写 20 个字。越真诚，越容易被“另一个我”接住。');
      return;
    }
    if (containsExternalContact(body) || containsExternalContact(_extraCtrl.text)) {
      setState(() => _msg = '信里不要放联系方式/链接/邮箱等外部信息。');
      return;
    }

    setState(() => _sending = true);

    final me = await LocalStore.getOrCreateUserId();
    final other = mirrorUserId(profile.birthDate, profile.shichen);

    final now = DateTime.now().millisecondsSinceEpoch;
    final rid = 'R-${now}-${Random().nextInt(9999)}';

    final req = MailRequest(
      id: rid,
      fromUserId: me,
      toUserId: other,
      mood: _state,
      pace: _pace,
      extraLine: _extraCtrl.text.trim(),
      createdAt: now,
      note: body.length > 28 ? '${body.substring(0, 28)}…' : body,
      status: RequestStatus.pending,
    );

    // consume 1 stamp
    await LocalStore.saveWallet(StampWallet(wallet.stamps - 1));

    // save pending
    await LocalStore.savePending([req]);

    // for MVP demo: create a mirror incoming request sometimes
    final incoming = await LocalStore.loadIncoming();
    if (incoming.isEmpty && Random().nextDouble() < 0.55) {
      final rid2 = 'R-${now + 7}-${Random().nextInt(9999)}';
      incoming.add(
        MailRequest(
          id: rid2,
          fromUserId: other,
          toUserId: me,
          mood: ['开心', '低谷', '迷茫', '想倾诉'][Random().nextInt(4)],
          pace: ['随缘即可', '希望认真回复', '慢慢来'][Random().nextInt(3)],
          extraLine: '想听听你怎么走过这一段。',
          createdAt: now + 7,
          note: '我好像在很相似的路口停住了……你也会吗？',
          status: RequestStatus.incoming,
        ),
      );
      await LocalStore.saveIncoming(incoming);
    }

    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已寄出。${DateFormat('HH:mm').format(DateTime.now())} 投递到命运信箱。')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('写一封信'),
          actions: [
            IconButton(
              onPressed: () => showRulesSheet(context),
              icon: const Icon(Icons.info_outline),
              tooltip: '规则',
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('把这一刻写给“另一个我”', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _state,
                        items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _state = v ?? _states.first),
                        decoration: const InputDecoration(labelText: '我现在的状态'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _pace,
                        items: _paces.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _pace = v ?? _paces.first),
                        decoration: const InputDecoration(labelText: '我希望的互动'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _bodyCtrl,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          labelText: '正文（至少20字）',
                          hintText: '你可以写开心、失落、无助、庆祝、迷茫……\n像写给未来的自己一样写。',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _extraCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: '附言（可选）',
                          hintText: '一句话也好：比如“如果你也在低谷，我愿意听”。',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _sending ? null : _send,
                        child: Text(_sending ? '寄出中…' : '支付 1 张邮票并寄出'),
                      ),
                      const SizedBox(height: 8),
                      Text(_msg, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 4),
                      const Text('提示：本地演示会偶尔生成一条“收到的请求卡”。', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
