import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/local_store.dart';
import '../widgets/fate_background.dart';
import '../widgets/fate_card.dart';

class PendingPage extends StatefulWidget {
  const PendingPage({super.key});

  @override
  State<PendingPage> createState() => _PendingPageState();
}

class _PendingPageState extends State<PendingPage> {
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
      appBar: AppBar(title: const Text('待回应')),
      body: FateBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  FateCard(
                    child: Text(
                      _items.isEmpty
                          ? '还没有待回应的投递。写一封吧。'
                          : '这里是你已经投递、等待回应的信。对方同意前，你的邮箱保持隐藏。',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: scheme.onSurface.withOpacity(0.78), height: 1.25),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._items.map((e) => Padding(
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
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    '状态：等待回应',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: scheme.onSurface.withOpacity(0.7)),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () => _withdraw(e),
                                    icon: const Icon(Icons.undo_rounded, size: 18),
                                    label: const Text('撤回并退回邮票'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      )),
                ],
              ),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final list = await LocalStore.loadPending();
    if (!mounted) return;
    setState(() {
      _items = list.reversed.toList();
      _loading = false;
    });
  }

  Future<void> _withdraw(MailRequest req) async {
    final wallet = await LocalStore.loadWallet();
    await LocalStore.removePending(req.id);
    await LocalStore.saveWallet(wallet.copyWith(stamps: wallet.stamps + 1));
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已撤回，邮票已退回待用')));
  }
}
