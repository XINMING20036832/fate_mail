\
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../widgets/fate_scaffold.dart';
import '../widgets/fate_card.dart';

class MailboxPage extends StatefulWidget {
  const MailboxPage({super.key});

  @override
  State<MailboxPage> createState() => _MailboxPageState();
}

class _MailboxPageState extends State<MailboxPage> {
  List<MailItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await LocalStore.loadMailbox();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _open(MailItem m) async {
    final dt = DateTime.fromMillisecondsSinceEpoch(m.createdAt);
    final time = DateFormat('yyyy-MM-dd HH:mm').format(dt);

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('来信 · $time'),
        content: SingleChildScrollView(
          child: Text(m.body),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
        ],
      ),
    );
  }

  Future<void> _delete(MailItem m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除这封信？'),
        content: const Text('删除后仅本机不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;

    final next = _items.where((e) => e.id != m.id).toList();
    await LocalStore.saveMailbox(next);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return FateScaffold(
      title: '我的信箱',
      body: _items.isEmpty
          ? Center(
              child: FateCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mail_outline, size: 36),
                    const SizedBox(height: 10),
                    Text('信箱还是空的', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('当你接受请求卡后，信会出现在这里。', style: TextStyle(color: Colors.white.withOpacity(0.75))),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/incoming'),
                      child: const Text('去看看我收到的请求卡'),
                    )
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final m = _items[i];
                final dt = DateTime.fromMillisecondsSinceEpoch(m.createdAt);
                final time = DateFormat('yyyy-MM-dd HH:mm').format(dt);

                final lines = m.body.split('\n').where((e) => e.trim().isNotEmpty).toList();
                final preview = lines.take(3).join(' · ');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FateCard(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _open(m),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text('来信 · $time', style: const TextStyle(fontWeight: FontWeight.w700))),
                                IconButton(
                                  tooltip: '删除',
                                  onPressed: () => _delete(m),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              preview.isEmpty ? '（空）' : preview,
                              style: TextStyle(color: Colors.white.withOpacity(0.80), height: 1.25),
                            ),
                            const SizedBox(height: 8),
                            Text('点开阅读全文', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
