import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/local_store.dart';
import '../widgets/fate_background.dart';
import '../widgets/fate_card.dart';

class IncomingPage extends StatefulWidget {
  const IncomingPage({super.key});

  @override
  State<IncomingPage> createState() => _IncomingPageState();
}

class _IncomingPageState extends State<IncomingPage> {
  List<MailRequest> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('收到的信')),
      body: FateBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  FateCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '同年同月同日同一时辰的人，往往会在某些节点上，经历相似的路。',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(height: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '你可以选择接住这封信，让对方在远处等到你的回音。\n同意后，你们才会互相看到邮箱（默认隐藏）。',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurface.withOpacity(0.78), height: 1.25),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_items.isEmpty)
                    FateCard(
                      child: Text(
                        '暂时还没有来信。\n你可以先去“写信”投递一封，命运会把它送到另一个你那里。',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: scheme.onSurface.withOpacity(0.78), height: 1.25),
                      ),
                    ),
                  ..._items.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FateCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.templateState} · ${e.templatePace}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (e.extraLine.trim().isNotEmpty)
                              Text(
                                '“${e.extraLine.trim()}”',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(height: 1.25),
                              ),
                            if (e.extraLine.trim().isNotEmpty) const SizedBox(height: 8),
                            Text(
                              '命运码：${e.fateKey}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurface.withOpacity(0.62)),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _reject(e),
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  label: const Text('忽略'),
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: () => _accept(e),
                                  icon: const Icon(Icons.check_rounded, size: 18),
                                  label: const Text('接住这封信'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final list = await LocalStore.loadIncoming();
    if (!mounted) return;
    setState(() {
      _items = list.reversed.toList();
      _loading = false;
    });
  }

  Future<void> _reject(MailRequest req) async {
    await LocalStore.removeIncoming(req.id);
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已忽略')));
  }

  Future<void> _accept(MailRequest req) async {
    // Mark accepted
    final accepted = req.copyWith(status: 'accepted');
    final list = await LocalStore.loadIncoming();
    final idx = list.indexWhere((e) => e.id == req.id);
    if (idx >= 0) {
      list[idx] = accepted;
      await LocalStore.saveIncoming(list);
    }

    // Create a first mailbox message (the short line becomes the first content)
    final first = MailItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: accepted.fromUserId,
      content: accepted.extraLine.trim().isEmpty
          ? '（对方没有留下额外一句话）'
          : accepted.extraLine.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await LocalStore.addMailbox(first);

    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已同意：你们的邮箱已在“信箱”里开启')),
    );
  }
}
