import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../models/models.dart';

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
    setState(() {
      _profile = p;
      _wallet = w;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    if (p == null) {
      return const Scaffold(body: Center(child: Text('未绑定命运坐标')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('宿命信箱'),
        actions: [
          IconButton(onPressed: () => Navigator.pushNamed(context, '/settings'), icon: const Icon(Icons.settings)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('你的命运坐标：${p.birthDate} ｜ ${p.shichen}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text('邮票余额：${_wallet.stamps}（6元/封）', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/compose').then((_) => _load()),
              child: const Text('寄一封同命信'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/incoming').then((_) => _load()),
              child: const Text('我收到的请求卡'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/pending').then((_) => _load()),
              child: const Text('我在等待（72小时）'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/mailbox').then((_) => _load()),
              child: const Text('我的信箱（慢信）'),
            ),
            const Spacer(),
            const Text(
              '规则：对方先看到请求卡，接受后才读内容；拒绝不会再打扰。\n'
              '为了反撒网：同一时间只能等待1个决定。',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/wallet').then((_) => _load()),
        label: const Text('购买邮票'),
        icon: const Icon(Icons.local_post_office),
      ),
    );
  }
}
