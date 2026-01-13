import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/local_store.dart';
import '../widgets/nebula_background.dart';

class MailboxPage extends StatefulWidget {
  const MailboxPage({super.key});

  @override
  State<MailboxPage> createState() => _MailboxPageState();
}

class _MailboxPageState extends State<MailboxPage> {
  List<MailItem> _items = <MailItem>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final xs = await LocalStore.loadMailbox();
    xs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return;
    setState(() {
      _items = xs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('信箱')),
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
                          child: Text('你的信箱还空着。先写一封信，或者接受一封来信。', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.75))),
                        ),
                      )
                    else
                      ..._items.map((m) {
                        final dt = DateTime.fromMillisecondsSinceEpoch(m.createdAt);
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                            title: Text(m.body.split('\n').first, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(dt), style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pushNamed(context, '/thread', arguments: m.requestId).then((_) => _load()),
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}
