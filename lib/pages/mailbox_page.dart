import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../core/utils.dart';
import '../widgets/fate_scaffold.dart';

class MailboxPage extends StatefulWidget {
  const MailboxPage({super.key});

  @override
  State<MailboxPage> createState() => _MailboxPageState();
}

class _MailboxPageState extends State<MailboxPage> {
  List<MailItem> _items = [];
  bool _loading = true;

  final _replyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await LocalStore.loadMailbox();
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _send() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    if (containsExternalContact(text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('信里禁止外部联系方式。')));
      return;
    }
    _replyCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已发送（演示）。')));
  }

  @override
  Widget build(BuildContext context) {
    return FateScaffold(
      title: '信箱',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _items.isEmpty
                      ? const Center(child: Text('还没有信。', style: TextStyle(color: Colors.white70)))
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final it = _items[i];
                            final dt = DateTime.fromMillisecondsSinceEpoch(it.createdAt);
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('来自：${it.peerFateKey}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    Text('时间：${DateFormat('yyyy-MM-dd HH:mm').format(dt)}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                    const SizedBox(height: 8),
                                    Text('状态：${it.state} · 节奏：${it.pace}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                    const SizedBox(height: 10),
                                    Text(it.text, style: const TextStyle(height: 1.35)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _replyCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '回一封（禁止外部联系方式）',
                    hintText: '写一句话回过去…',
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(onPressed: _send, child: const Text('发送')),
                const SizedBox(height: 6),
                const Text('提示：我们不做公开社交，只做一对一的信箱。', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
    );
  }
}
