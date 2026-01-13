\
import 'package:flutter/material.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../services/local_store.dart';
import '../widgets/fate_scaffold.dart';
import '../widgets/fate_card.dart';

class ComposePage extends StatefulWidget {
  const ComposePage({super.key});

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  final _controller = TextEditingController();
  String _state = '';
  String _pace = '';
  String _extra = '';
  bool _sending = false;

  final _states = const ['开心', '失落', '迷茫', '无助', '平静', '想倾诉'];
  final _paces = const ['慢慢说', '想马上说完', '只说一句也行'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toast(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _send() async {
    if (_sending) return;
    final body = _controller.text.trim();
    if (body.isEmpty) {
      _toast('写点什么再寄出');
      return;
    }
    if (!passesContentPolicy(body)) {
      _toast('包含联系方式/二维码/引流信息或敏感内容，请删掉再试');
      return;
    }

    setState(() => _sending = true);

    final p = await LocalStore.loadProfile();
    final w = await LocalStore.loadWallet();
    if (p == null) {
      _toast('请先绑定命运坐标');
      setState(() => _sending = false);
      return;
    }
    if ((w?.stamps ?? 0) <= 0) {
      _toast('邮票不够，先去购买');
      setState(() => _sending = false);
      return;
    }

    // 只能同时存在一张“等待中的请求卡”
    final pending = await LocalStore.loadPending();
    if (pending.any((e) => e.status == 'pending')) {
      _toast('你已经有一张等待中的请求卡了');
      setState(() => _sending = false);
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final me = await LocalStore.getOrCreateUserId();
    final fateKey = '${p.birthDate}_${p.shichen}';

    final req = MailRequest(
      id: 'req_$now',
      fromUserId: me,
      toUserId: 'TBD',
      fateKey: fateKey,
      status: 'pending',
      createdAt: now,
      templateState: _state,
      templatePace: _pace,
      extraLine: _extra,
    );

    await LocalStore.savePending([req]);

    // 扣 1 张邮票，等待对方是否接受（拒绝/撤回/超时会退回）
    await LocalStore.saveWallet(StampWallet((w?.stamps ?? 0) - 1));

    if (!mounted) return;
    setState(() => _sending = false);
    Navigator.pushReplacementNamed(context, '/pending');
  }

  @override
  Widget build(BuildContext context) {
    return FateScaffold(
      title: '写信',
      actions: [
        IconButton(
          tooltip: '规则',
          onPressed: () => Navigator.pushNamed(context, '/rules'),
          icon: const Icon(Icons.auto_awesome),
        )
      ],
      body: ListView(
        children: [
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('写给“另一个我”', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  '这不是聊天。\n'
                  '你可以把今天的胜利、委屈、失败、希望——写成一封信。\n'
                  '它只会投递给同命的那个人。',
                  style: TextStyle(color: Colors.white.withOpacity(0.80), height: 1.35),
                ),
                const SizedBox(height: 10),
                Text(
                  '寄出会消耗 1 张邮票；对方拒绝/你撤回/超时会退回。',
                  style: TextStyle(color: Colors.white.withOpacity(0.75)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('先选一下感觉（可选）', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _states.map((s) {
                    final selected = _state == s;
                    return ChoiceChip(
                      label: Text(s),
                      selected: selected,
                      onSelected: (_) => setState(() => _state = selected ? '' : s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _paces.map((s) {
                    final selected = _pace == s;
                    return ChoiceChip(
                      label: Text(s),
                      selected: selected,
                      onSelected: (_) => setState(() => _pace = selected ? '' : s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => _extra = v,
                  decoration: const InputDecoration(
                    labelText: '加一句（可选）',
                    hintText: '比如：你现在过得好吗？',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('写信内容', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                TextField(
                  controller: _controller,
                  minLines: 6,
                  maxLines: 14,
                  decoration: const InputDecoration(
                    hintText: '把你想说的话写进信里……\n（不要写联系方式、二维码或引流内容）',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                  label: const Text('寄出（消耗 1 张邮票）'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/wallet'),
                  child: const Text('邮票不够？去购买'),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
