import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../widgets/fate_scaffold.dart';
import '../widgets/rules_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Profile? _profile;
  StampWallet _wallet = StampWallet(0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await LocalStore.loadProfile();
    final w = await LocalStore.loadWallet();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _wallet = w;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    return FateScaffold(
      showBack: false,
      title: '另一个我',
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/settings').then((_) => _load()),
          icon: const Icon(Icons.settings),
        ),
        IconButton(
          onPressed: () => RulesSheet.show(context),
          icon: const Icon(Icons.info_outline),
          tooltip: '规则与隐私',
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p == null ? '未绑定' : '你的命运坐标：${p.fateKey}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '生活路途遥远。\n'
                    '你会遇到让你兴奋的时刻，也会有无人可说的夜晚。\n'
                    '把那句话写下来，寄给“另一个你”。\n也许对方的一句回信，会在某个夜里把你拉回来。',
                    style: TextStyle(height: 1.45),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('邮票：${_wallet.stamps} 枚', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('寄出一封信消耗 1 枚邮票。拒绝/超时会退回。', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/compose').then((_) => _load()),
            icon: const Icon(Icons.edit),
            label: const Text('写一封信'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/pending'),
                  child: const Text('我寄出的'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/incoming'),
                  child: const Text('我收到的'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/mailbox'),
            child: const Text('信箱（接受后可继续往返）'),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/wallet').then((_) => _load()),
            child: const Text('购买邮票'),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }
}
