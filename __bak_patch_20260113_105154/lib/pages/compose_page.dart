import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/local_store.dart';
import '../widgets/fate_background.dart';
import '../widgets/fate_card.dart';

class ComposePage extends StatefulWidget {
  const ComposePage({super.key});

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  final _formKey = GlobalKey<FormState>();

  String _state = 'Tonight';
  String _pace = 'Slow & warm';
  String _extraLine = '';

  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('写一封给「另一个我」')),
      body: FateBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            FateCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '你不是在写给陌生人。',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '你写给：和你同年同月同日同一时辰来到这世界的人。很多相似，不需要解释太多。',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.onSurface.withOpacity(0.78), height: 1.25),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FateCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('写信模板', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    _drop(
                      label: '此刻的你',
                      value: _state,
                      items: const ['Tonight', 'A little lost', 'Good news', 'I miss someone', 'I need a sign'],
                      onChanged: (v) => setState(() => _state = v),
                    ),
                    const SizedBox(height: 10),
                    _drop(
                      label: '语气与节奏',
                      value: _pace,
                      items: const ['Slow & warm', 'Short & direct', 'Gentle & poetic', 'Serious & honest'],
                      onChanged: (v) => setState(() => _pace = v),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: '加一句只属于你的话（可选）',
                        hintText: '比如：今天我突然很想证明自己…',
                      ),
                      maxLength: 40,
                      onChanged: (v) => _extraLine = v.trim(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _sending ? null : () => _send(context),
                            icon: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: const Text('投递（消耗 1 封邮票）'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '投递后，你的邮箱仍然隐藏。只有对方同意，你们才会解锁对话。邮票可退回待用。',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurface.withOpacity(0.68), height: 1.25),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drop({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String v) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) {
        if (v == null) return;
        onChanged(v);
      },
    );
  }

  Future<void> _send(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final p = await LocalStore.loadProfile();
      if (p == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('请先完成绑定：生日 + 时辰')));
        return;
      }
      final wallet = await LocalStore.loadWallet();
      if (wallet.stamps <= 0) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('邮票不足：先去“邮票”页购买')));
        return;
      }

      final myId = await LocalStore.getOrCreateUserId();
      final now = DateTime.now().millisecondsSinceEpoch;

      final req = MailRequest(
        id: '${now}_$myId',
        fromUserId: myId,
        toUserId: 'unknown',
        fateKey: '${p.birthDate}_${p.shichen}',
        status: 'pending',
        createdAt: now,
        templateState: _state,
        templatePace: _pace,
        extraLine: _extraLine,
      );

      await LocalStore.addPending(req);
      await LocalStore.saveWallet(wallet.copyWith(stamps: wallet.stamps - 1));

      // Demo: create a mirror incoming request so the app can be tested locally.
      final mirror = req.copyWith(
        id: '${now}_mirror',
        fromUserId: 'mirror',
        toUserId: myId,
        status: 'incoming',
      );
      await LocalStore.addIncoming(mirror);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已投递。去“待回应 / 收到的信”看看。')),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
