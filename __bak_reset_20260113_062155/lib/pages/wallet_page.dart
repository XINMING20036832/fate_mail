import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../models/models.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  StampWallet _wallet = StampWallet(0);
  bool _loading = true;

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

  Future<void> _buy(int count) async {
    // MVP: local simulate
    final next = StampWallet(_wallet.stamps + count);
    await LocalStore.saveWallet(next);
    setState(() => _wallet = next);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('邮票')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('当前邮票：${_wallet.stamps}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text('MVP本地模拟购买。上架后请接 Google Play Billing。'),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => _buy(1), child: const Text('购买 1 张（6元/张）')),
            const SizedBox(height: 8),
            FilledButton(onPressed: () => _buy(3), child: const Text('购买 3 张')),
            const SizedBox(height: 8),
            FilledButton(onPressed: () => _buy(10), child: const Text('购买 10 张')),
            const Spacer(),
            const Text('建议：72小时未被接受 → 自动退回邮票（后端做定时任务）。', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
