import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_store.dart';
import '../models/models.dart';

class PendingPage extends StatefulWidget {
  const PendingPage({super.key});

  @override
  State<PendingPage> createState() => _PendingPageState();
}

class _PendingPageState extends State<PendingPage> {
  List<MailRequest> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await LocalStore.loadPending();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _withdraw(MailRequest req) async {
    // MVP: mark withdrawn and refund stamp locally
    final wallet = await LocalStore.loadWallet();
    await LocalStore.saveWallet(StampWallet(wallet.stamps + 1));

    final next = _items.map((e) {
      if (e.id == req.id) {
        return MailRequest(
          id: e.id,
          fromUserId: e.fromUserId,
          toUserId: e.toUserId,
          fateKey: e.fateKey,
          status: 'expired',
          createdAt: e.createdAt,
          templateState: e.templateState,
          templatePace: e.templatePace,
          extraLine: e.extraLine,
        );
      }
      return e;
    }).toList();

    await LocalStore.savePending(next);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('我在等待（72小时）')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final r = _items[i];
          final dt = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
          return Card(
            child: ListTile(
              title: Text('状态：${r.status}'),
              subtitle: Text('坐标：${r.fateKey}\n时间：${DateFormat('yyyy-MM-dd HH:mm').format(dt)}'),
              isThreeLine: true,
              trailing: r.status == 'pending'
                  ? TextButton(onPressed: () => _withdraw(r), child: const Text('撤回并退邮票'))
                  : null,
            ),
          );
        },
      ),
    );
  }
}
