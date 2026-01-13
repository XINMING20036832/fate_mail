import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../services/local_store.dart';
import '../widgets/nebula_background.dart';

class ThreadPage extends StatefulWidget {
  const ThreadPage({super.key});

  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  late final String requestId;
  List<MailItem> _items = <MailItem>[];
  bool _loading = true;

  final _ctrl = TextEditingController();
  String _msg = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    requestId = (ModalRoute.of(context)?.settings.arguments ?? '').toString();
    _load();
  }

  Future<void> _load() async {
    final xs = await LocalStore.loadMailbox();
    final filtered = xs.where((e) => e.requestId == requestId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (!mounted) return;
    setState(() {
      _items = filtered;
      _loading = false;
    });
  }

  Future<void> _send() async {
    setState(() => _msg = '');
    final txt = _ctrl.text.trim();
    if (txt.length < 10) {
      setState(() => _msg = '至少写 10 个字。');
      return;
    }
    if (containsExternalContact(txt)) {
      setState(() => _msg = '不要放联系方式/链接/邮箱等外部信息。');
      return;
    }

    final me = await LocalStore.getOrCreateUserId();
    final now = DateTime.now().millisecondsSinceEpoch;
    final item = MailItem(
      id: 'M-$now-${Random().nextInt(9999)}',
      requestId: requestId,
      fromUserId: me,
      toUserId: 'mirror',
      body: txt,
      createdAt: now,
    );

    final all = await LocalStore.loadMailbox();
    all.add(item);
    await LocalStore.saveMailbox(all);

    _ctrl.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('对话')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final m = _items[i];
                          final dt = DateTime.fromMillisecondsSinceEpoch(m.createdAt);
                          final isMe = m.fromUserId.startsWith('U-');
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                              decoration: BoxDecoration(
                                color: isMe ? theme.colorScheme.primary.withOpacity(0.22) : Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.body, style: const TextStyle(height: 1.45)),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('MM-dd HH:mm').format(dt),
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.55)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _ctrl,
                                  maxLines: 3,
                                  minLines: 1,
                                  decoration: const InputDecoration(
                                    labelText: '写回信',
                                    hintText: '把这一刻写给“另一个我”…',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              FilledButton(
                                onPressed: _send,
                                child: const Text('发送'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_msg, style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
