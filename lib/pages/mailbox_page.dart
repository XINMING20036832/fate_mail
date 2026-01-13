import 'package:flutter/material.dart';

import '../core/utils.dart';
import '../models/models.dart';
import '../services/local_store.dart';
import '../widgets/fate_background.dart';
import '../widgets/fate_card.dart';

class MailboxPage extends StatefulWidget {
  const MailboxPage({super.key});

  @override
  State<MailboxPage> createState() => _MailboxPageState();
}

class _MailboxPageState extends State<MailboxPage> {
  final _ctrl = TextEditingController();
  List<MailItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await LocalStore.loadMailbox();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _send() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;

    // Basic safety: block obvious external contact attempts.
    if (containsExternalContact(t)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('为了双方匿名与安全：请不要在信里写手机号/邮箱/外部联系方式。')),
      );
      return;
    }

    final item = MailItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      direction: 'out',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      subject: '新的一封信',
      body: t,
    );

    await LocalStore.addMailbox(item);
    _ctrl.clear();
    await _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FateBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('来信箱'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: FateCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '匿名信件，不等于冷冰冰。\n你写下的每一句，都在等待同命的回声。',
                        style: theme.textTheme.titleSmall?.copyWith(height: 1.25),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '提示：我们不读取/不保存正文内容到服务器；只做“临时转交”。在对方同意前，双方邮箱都保持隐藏。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(0.72),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final m = _items[i];
                          final isOut = m.direction == 'out';
                          return Align(
                            alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: FateCard(
                                  pad: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isOut ? '你' : '对方',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          color: scheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        m.body,
                                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: '写下你想说的话…',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _send,
                      child: const Text('发送'),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
