import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_store.dart';
import '../models/models.dart';

class IncomingPage extends StatefulWidget {
  const IncomingPage({super.key});

  @override
  State<IncomingPage> createState() => _IncomingPageState();
}

class _IncomingPageState extends State<IncomingPage> {
  List<MailRequest> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await LocalStore.loadIncoming();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _accept(MailRequest req) async {
    // create mailbox first letter
    final uid = await LocalStore.getOrCreateUserId();
    final mailbox = await LocalStore.loadMailbox();
    final now = DateTime.now().millisecondsSinceEpoch;

    final body = '状态：${req.templateState}\n互动：${req.templatePace}\n\n${req.extraLine}';
    mailbox.insert(
      0,
      MailItem(
        id: now.toString(),
        requestId: req.id,
        fromUserId: req.fromUserId,
        toUserId: uid,
        body: body,
        createdAt: now,
      ),
    );
    await LocalStore.saveMailbox(mailbox);

    // update incoming status
    final next = _items.map((e) {
      if (e.id == req.id) {
        return MailRequest(
          id: e.id,
          fromUserId: e.fromUserId,
          toUserId: e.toUserId,
          fateKey: e.fateKey,
          status: 'accepted',
          createdAt: e.createdAt,
          templateState: e.templateState,
          templatePace: e.templatePace,
          extraLine: e.extraLine,
        );
      }
      return e;
    }).toList();
    await LocalStore.saveIncoming(next);
    await _load();

    if (!mounted) return;
    Navigator.pushNamed(context, '/mailbox');
  }

  Future<void> _reject(MailRequest req) async {
    final next = _items.map((e) {
      if (e.id == req.id) {
        return MailRequest(
          id: e.id,
          fromUserId: e.fromUserId,
          toUserId: e.toUserId,
          fateKey: e.fateKey,
          status: 'rejected',
          createdAt: e.createdAt,
          templateState: e.templateState,
          templatePace: e.templatePace,
          extraLine: e.extraLine,
        );
      }
      return e;
    }).toList();
    await LocalStore.saveIncoming(next);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('我收到的请求卡')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final r = _items[i];
          final dt = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('同命来信请求', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('命运坐标一致：${r.fateKey}'),
                  const SizedBox(height: 6),
                  const Text('对方已付邮票（群发成本高）'),
                  const Text('对方同一时间只能等待1个决定（无法撒网）'),
                  const Text('你可拒绝且不会再被打扰'),
                  const SizedBox(height: 8),
                  Text('时间：${DateFormat('yyyy-MM-dd HH:mm').format(dt)}'),
                  const SizedBox(height: 10),
                  if (r.status == 'pending') Row(
                    children: [
                      Expanded(child: FilledButton(onPressed: () => _accept(r), child: const Text('接受并阅读'))),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton(onPressed: () => _reject(r), child: const Text('拒绝'))),
                    ],
                  ) else Text('状态：${r.status}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
