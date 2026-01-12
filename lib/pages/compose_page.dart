import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../core/utils.dart';
import '../widgets/fate_background.dart';
import '../widgets/fate_card.dart';

class ComposePage extends StatefulWidget {
  const ComposePage({super.key});

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  final _tCtl = TextEditingController();
  final _bCtl = TextEditingController();
  StampWallet _wallet = const StampWallet(0);
  bool _loading = true;
  String _err = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final w = await LocalStore.loadWallet();
    setState(() {
      _wallet = w;
      _loading = false;
    });
  }

  Future<void> _send() async {
    final title = _tCtl.text.trim();
    final body = _bCtl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      setState(() => _err = '标题和正文都要写。');
      return;
    }
    if (containsExternalContact(body) || containsExternalContact(title)) {
      setState(() => _err = '为了保护双方隐私，信里不要写手机号/微信/邮箱等外部联系方式。');
      return;
    }
    if (_wallet.stamps <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('没有邮票了，先去购买。')));
      return;
    }

    // consume 1 stamp
    final nextWallet = StampWallet(_wallet.stamps - 1);
    await LocalStore.saveWallet(nextWallet);

    final req = LetterRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      createdAt: DateTime.now().toIso8601String(),
      status: 'pending',
    );
    await LocalStore.addPending(req);

    // Demo: also create a mirror request in inbox so user can test accept/reject.
    final mirror = LetterRequest(
      id: 'in_${req.id}',
      title: title,
      body: body,
      createdAt: req.createdAt,
      status: 'incoming',
    );
    await LocalStore.addIncoming(mirror);

    if (!mounted) return;
    setState(() {
      _wallet = nextWallet;
      _err = '';
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已投递到命运邮局（等待对方72小时内确认）')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('写给另一个我')),
      body: FateBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FateCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('这一封信，会被送到与你同年同月同日同一时辰的人。', style: t.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        '微信是即时的，信是“等待”。\n'
                        '当你把心事写成一封信，它就不再是随手一句话——它会变成一种力量。',
                        style: TextStyle(color: scheme.onSurface.withOpacity(0.75), height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FateCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('邮票余额：${_wallet.stamps} 枚', style: const TextStyle(fontWeight: FontWeight.w800))),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/wallet').then((_) => _load()),
                            child: const Text('购买邮票'),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '发出一封信消耗 1 枚邮票。若对方拒绝或你撤回，邮票会退回。',
                        style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FateCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _tCtl,
                        decoration: const InputDecoration(
                          labelText: '标题',
                          hintText: '例如：今晚我有点撑不住了',
                        ),
                        maxLength: 30,
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _bCtl,
                        decoration: const InputDecoration(
                          labelText: '正文',
                          hintText: '写下你此刻最想对“另一个我”说的话…',
                        ),
                        maxLines: 10,
                        minLines: 8,
                      ),
                      const SizedBox(height: 8),
                      if (_err.isNotEmpty)
                        Text(_err, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _send,
                        icon: const Icon(Icons.send),
                        label: const Text('投递（消耗 1 枚邮票）'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '写作提示：\n'
                  '1）先说“我现在在哪个阶段”\n'
                  '2）再说“我最怕的是什么/最想要的是什么”\n'
                  '3）最后留一句“你那边…好吗？”\n'
                  '（不要写联系方式，保护双方。）',
                  style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.75), height: 1.35),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
