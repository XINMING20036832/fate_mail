import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../widgets/fate_background.dart';
import '../widgets/fate_card.dart';

class PendingPage extends StatefulWidget {
  const PendingPage({super.key});

  @override
  State<PendingPage> createState() => _PendingPageState();
}

class _PendingPageState extends State<PendingPage> {
  List<LetterRequest> _items = [];
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

  Future<void> _withdraw(LetterRequest req) async {
    await LocalStore.removePending(req.id);
    // refund 1 stamp
    final w = await LocalStore.loadWallet();
    await LocalStore.saveWallet(StampWallet(w.stamps + 1));
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已撤回，邮票已退回')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('等待确认')),
      body: FateBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FateCard(
                  child: Text(
                    '这些信件已经投递到“命运邮局”，等待对方确认。\n撤回会退回 1 枚邮票；对方 72 小时未处理也会自动退回。',
                    style: TextStyle(color: scheme.onSurface.withOpacity(0.75), height: 1.3),
                  ),
                ),
                const SizedBox(height: 12),
                if (_items.isEmpty)
                  const FateCard(child: Text('暂无待确认信件。')),
                for (final r in _items) ...[
                  FateCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.title,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _withdraw(r),
                              child: const Text('撤回'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r.body,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurface.withOpacity(0.78), height: 1.25),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r.createdAt,
                          style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
