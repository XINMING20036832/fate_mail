import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../core/utils.dart';

class MailboxPage extends StatefulWidget {
  const MailboxPage({super.key});

  @override
  State<MailboxPage> createState() => _MailboxPageState();
}

class _MailboxPageState extends State<MailboxPage> {
  List<MailItem> _items = [];
  bool _loading = true;
  final _ctrl = TextEditingController();
  String _msg = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await LocalStore.loadMailbox();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _send() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;
    if (containsExternalContact(txt)) {
      setState(() => _msg = '信箱里暂时也禁止外联信息（手机号/链接/微信）。');
      return;
    }
    final uid = await LocalStore.getOrCreateUserId();
    final now = DateTime.now().millisecondsSinceEpoch;

    final mail = MailItem(
      id: now.toString(),
      requestId: _items.isEmpty ? 'unknown' : _items.first.requestId,
      fromUserId: uid,
      toUserId: 'peer',
      body: txt,
      createdAt: now,
    );
    final next = [mail, ..._items];
    await LocalStore.saveMailbox(next);
    _ctrl.clear();
    setState(() {
      _items = next;
      _msg = '';
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('我的信箱（慢信）')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(_msg, style: const TextStyle(color: Colors.red)),
            Expanded(
              child: ListView.builder(
                reverse: false,
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final m = _items[i];
                  final dt = DateTime.fromMillisecondsSinceEpoch(m.createdAt);
                  return Card(
                    child: ListTile(
                      title: Text(DateFormat('yyyy-MM-dd HH:mm').format(dt)),
                      subtitle: Text(m.body),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: '写一封慢信（不要留微信/手机号/链接）',
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _send, child: const Text('发送')),
              ],
            ),
            const SizedBox(height: 6),
            const Text('提示：MVP用“慢信”节奏，减少即时社交焦虑。', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
