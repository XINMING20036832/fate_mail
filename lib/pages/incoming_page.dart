import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/local_store.dart';
import '../widgets/nebula_background.dart';

class IncomingPage extends StatefulWidget {
  const IncomingPage({super.key});

  @override
  State<IncomingPage> createState() => _IncomingPageState();
}

class _IncomingPageState extends State<IncomingPage> {
  List<MailRequest> _items = <MailRequest>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final xs = await LocalStore.loadIncoming();
    if (!mounted) return;
    setState(() {
      _items = xs;
      _loading = false;
    });
  }

  Future<void> _accept(MailRequest r) async {
    // move to mailbox: create a first mail from sender
    final mailbox = await LocalStore.loadMailbox();
    final now = DateTime.now().millisecondsSinceEpoch;
    mailbox.add(
      MailItem(
        id: 'M-$now-${Random().nextInt(9999)}',
        requestId: r.id,
        fromUserId: r.fromUserId,
        toUserId: r.toUserId,
        createdAt: now,
        body: '我也不知道为什么会点开这个应用。\n但看到“同一刻出生的人”这句话时，我突然有点想说话。\n\n${r.note}',
      ),
    );
    await LocalStore.saveMailbox(mailbox);

    // remove from incoming
    _items.removeWhere((e) => e.id == r.id);
    await LocalStore.saveIncoming(_items);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已接受。信已投递到信箱。')));
    // open thread
    Navigator.pushNamed(context, '/thread', arguments: r.id).then((_) => _load());
  }

  Future<void> _reject(MailRequest r) async {
    _items.removeWhere((e) => e.id == r.id);
    await LocalStore.saveIncoming(_items);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已拒绝。')));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('我收到的请求')),
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
                          child: Text('暂时没有收到请求。', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.75))),
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
                                    const Icon(Icons.mark_email_unread_outlined),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text('来自“另一个我”的请求', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                                    ),
                                    Text(DateFormat('MM-dd HH:mm').format(dt), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.65))),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text('对方状态：${r.mood}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.78))),
                                const SizedBox(height: 4),
                                Text('对方希望的互动：${r.pace}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.78))),
                                const SizedBox(height: 10),
                                Text('对方写道：${r.note}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), height: 1.4)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () => _accept(r),
                                        icon: const Icon(Icons.check_circle_outline),
                                        label: const Text('接受'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _reject(r),
                                        icon: const Icon(Icons.close),
                                        label: const Text('拒绝'),
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
                      '提醒：双方默认不显示真实邮箱。只有当双方都愿意，才会开启进一步联系（正式版）。',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6), height: 1.5),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
