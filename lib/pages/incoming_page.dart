import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../widgets/fate_background.dart';
import '../widgets/fate_card.dart';

class IncomingPage extends StatefulWidget {
  const IncomingPage({super.key});

  @override
  State<IncomingPage> createState() => _IncomingPageState();
}

class _IncomingPageState extends State<IncomingPage> {
  List<LetterRequest> _items = [];
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

  Future<void> _accept(LetterRequest req) async {
    await LocalStore.removeIncoming(req.id);
    await LocalStore.addMailbox(LetterRequest(
      id: req.id,
      title: req.title,
      body: req.body,
      createdAt: req.createdAt,
      status: 'mailbox',
    ));
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已接收，信件已存入信箱')));
  }

  Future<void> _reject(LetterRequest req) async {
    await LocalStore.removeIncoming(req.id);
    // demo refund: in the real product, refund happens on the sender side (server controlled).
    final w = await LocalStore.loadWallet();
    await LocalStore.saveWallet(StampWallet(w.stamps + 1));
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已拒绝（演示：邮票已退回）')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('待接收来信')),
      body: FateBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FateCard(
                  child: Text(
                    '这里是与你“同命”之人的来信。\n'
                    '接收后进入信箱；拒绝会退回邮票（演示）。',
                    style: TextStyle(color: scheme.onSurface.withOpacity(0.75), height: 1.3),
                  ),
                ),
                const SizedBox(height: 12),
                if (_items.isEmpty)
                  const FateCard(child: Text('暂无来信。')),
                for (final r in _items) ...[
                  FateCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(r.body, style: TextStyle(color: scheme.onSurface.withOpacity(0.8), height: 1.25)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _reject(r),
                              icon: const Icon(Icons.close),
                              label: const Text('拒绝'),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              onPressed: () => _accept(r),
                              icon: const Icon(Icons.check),
                              label: const Text('接收'),
                            ),
                            const Spacer(),
                            Text(
                              r.createdAt,
                              style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.6)),
                            ),
                          ],
                        )
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
