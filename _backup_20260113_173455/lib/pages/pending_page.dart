\
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../widgets/fate_scaffold.dart';
import '../widgets/fate_card.dart';

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

  
  Future<void> _removeAndRefund(MailRequest r) async {
    final list = await LocalStore.loadPending();
    final next = list.where((e) => e.id != r.id).toList();
    await LocalStore.savePending(next);

    final w = await LocalStore.loadWallet();
    await LocalStore.saveWallet(StampWallet((w?.stamps ?? 0) + 1));
  }

Future<void> _withdraw(MailRequest r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('撤回请求卡？'),
        content: const Text('撤回后，对方将看不到这封信。邮票会退回。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('撤回')),
        ],
      ),
    );
    if (ok != true) return;

    await _removeAndRefund(r);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已撤回并退回邮票')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return FateScaffold(
      title: '我在等待',
      actions: [
        IconButton(
          tooltip: '写一封',
          onPressed: () => Navigator.pushReplacementNamed(context, '/compose'),
          icon: const Icon(Icons.edit),
        )
      ],
      body: _items.isEmpty
          ? Center(
              child: FateCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_empty, size: 36),
                    const SizedBox(height: 10),
                    Text('还没有等待中的请求卡', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('写一封信，投递给“另一个我”。', style: TextStyle(color: Colors.white.withOpacity(0.75))),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/compose'),
                      child: const Text('去写信'),
                    )
                  ],
                ),
              ),
            )
          : ListView(
              children: _items.map((r) {
                final dt = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FateCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('请求卡', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('状态：${r.status}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          '投递地址：${r.fateKey}\n时间：${DateFormat('yyyy-MM-dd HH:mm').format(dt)}\n等待上限：72小时',
                          style: TextStyle(color: Colors.white.withOpacity(0.80), height: 1.25),
                        ),
                        const SizedBox(height: 10),
                        if (r.status == 'pending')
                          OutlinedButton(
                            onPressed: () => _withdraw(r),
                            child: const Text('撤回并退邮票'),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
