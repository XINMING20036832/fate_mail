import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/local_store.dart';
import '../widgets/nebula_background.dart';

class PendingPage extends StatefulWidget {
  const PendingPage({super.key});

  @override
  State<PendingPage> createState() => _PendingPageState();
}

class _PendingPageState extends State<PendingPage> {
  List<MailRequest> _items = <MailRequest>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await LocalStore.loadPending();
    if (!mounted) return;
    setState(() {
      _items = p;
      _loading = false;
    });
  }

  Future<void> _cancel(MailRequest r) async {
    final wallet = await LocalStore.loadWallet();
    // refund stamp
    await LocalStore.saveWallet(StampWallet(wallet.stamps + 1));
    await LocalStore.savePending(<MailRequest>[]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已撤回，邮票已退回（演示）。')));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('我在等待')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (_items.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('你目前没有在等待的请求。', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.75))),
                        ),
                      )
                    else
                      ..._items.map((r) {
                        final dt = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.hourglass_bottom),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '等待对方决定',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
                                      ),
                                    ),
                                    Text(DateFormat('MM-dd HH:mm').format(dt), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.65))),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text('你的状态：${r.mood}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.78))),
                                const SizedBox(height: 4),
                                Text('你希望的互动：${r.pace}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.78))),
                                const SizedBox(height: 10),
                                Text('预览：${r.note}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), height: 1.4)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _cancel(r),
                                        icon: const Icon(Icons.undo),
                                        label: const Text('撤回并退回邮票'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 10),
                    Text(
                      '正式版：72小时内对方未回应 → 系统自动退回邮票（后端定时任务）。\n演示版：你可以手动“撤回”。',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6), height: 1.5),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
