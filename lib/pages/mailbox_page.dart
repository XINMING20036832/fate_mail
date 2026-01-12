import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../widgets/fate_background.dart';
import '../widgets/fate_card.dart';

class MailboxPage extends StatefulWidget {
  const MailboxPage({super.key});

  @override
  State<MailboxPage> createState() => _MailboxPageState();
}

class _MailboxPageState extends State<MailboxPage> {
  List<LetterRequest> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await LocalStore.loadMailbox();
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _delete(LetterRequest req) async {
    await LocalStore.removeMailbox(req.id);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除')));
  }

  void _open(LetterRequest req) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(req.title),
          content: SingleChildScrollView(child: Text(req.body)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('信箱')),
      body: FateBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FateCard(
                  child: Text(
                    '这里保存你收到并确认过的信。\n它们不会出现在任何搜索里，只属于你。',
                    style: TextStyle(color: scheme.onSurface.withOpacity(0.75), height: 1.3),
                  ),
                ),
                const SizedBox(height: 12),
                if (_items.isEmpty)
                  const FateCard(child: Text('信箱还是空的。')),
                for (final r in _items) ...[
                  FateCard(
                    child: InkWell(
                      onTap: () => _open(r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r.title,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                              ),
                              IconButton(
                                tooltip: '删除',
                                onPressed: () => _delete(r),
                                icon: const Icon(Icons.delete_outline),
                              )
                            ],
                          ),
                          Text(
                            r.body,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: scheme.onSurface.withOpacity(0.78), height: 1.25),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            r.createdAt,
                            style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.6)),
                          ),
                        ],
                      ),
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
