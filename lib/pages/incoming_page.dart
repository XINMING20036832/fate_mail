import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../widgets/fate_scaffold.dart';

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
    final list = await LocalStore.loadIncoming();
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _accept(MailRequest r) async {
    final next = _items.map((e) => e.id == r.id
        ? MailRequest(
            id: e.id,
            fromUserId: e.fromUserId,
            toUserId: e.toUserId,
            fateKey: e.fateKey,
            status: 'accepted',
            createdAt: e.createdAt,
            templateState: e.templateState,
            templatePace: e.templatePace,
            extraLine: e.extraLine,
          )
        : e).toList();
    await LocalStore.saveIncoming(next);

    // Add to mailbox
    final mailbox = await LocalStore.loadMailbox();
    final item = MailItem(
      id: r.id,
      peerFateKey: r.fateKey,
      state: r.templateState,
      pace: r.templatePace,
      text: r.extraLine,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await LocalStore.saveMailbox([item, ...mailbox]);

    if (!mounted) return;
    setState(() => _items = next);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已接受：已放入信箱。')));
  }

  Future<void> _reject(MailRequest r) async {
    // Refund 1 stamp to sender in real backend; demo: refund to current user to show effect.
    final w = await LocalStore.loadWallet();
    await LocalStore.saveWallet(StampWallet(w.stamps + 1));

    final next = _items.where((e) => e.id != r.id).toList();
    await LocalStore.saveIncoming(next);
    if (!mounted) return;
    setState(() => _items = next);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已拒绝（演示）：邮票已退回。')));
  }

  @override
  Widget build(BuildContext context) {
    return FateScaffold(
      title: '我收到的',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final r = _items[i];
                final dt = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('命运坐标：${r.fateKey}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text('时间：${DateFormat('yyyy-MM-dd HH:mm').format(dt)}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text('状态：${r.status}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                        const SizedBox(height: 10),
                        if (r.status == 'pending')
                          Row(
                            children: [
                              Expanded(child: FilledButton(onPressed: () => _accept(r), child: const Text('接受并阅读'))),
                              const SizedBox(width: 8),
                              Expanded(child: OutlinedButton(onPressed: () => _reject(r), child: const Text('拒绝'))),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
