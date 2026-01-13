import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../widgets/fate_scaffold.dart';

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
    final list = await LocalStore.loadPending();
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _withdraw(MailRequest r) async {
    // Refund 1 stamp for pending withdraw
    final w = await LocalStore.loadWallet();
    await LocalStore.saveWallet(StampWallet(w.stamps + 1));

    final next = _items.where((e) => e.id != r.id).toList();
    await LocalStore.savePending(next);
    if (!mounted) return;
    setState(() => _items = next);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已撤回，邮票已退回（演示）。')));
  }

  @override
  Widget build(BuildContext context) {
    return FateScaffold(
      title: '我寄出的',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
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
