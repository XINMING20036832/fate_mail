import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../widgets/fate_scaffold.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  StampWallet _wallet = StampWallet(0);
  bool _loading = true;

  int _q1 = 0;  // 1 stamp, 6
  int _q3 = 0;  // 3 stamps, 15
  int _q10 = 0; // 10 stamps, 30
  String _msg = '';

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

  int get _totalStamps => _q1 * 1 + _q3 * 3 + _q10 * 10;
  int get _totalPrice => _q1 * 6 + _q3 * 15 + _q10 * 30;

  void _clear() => setState(() {
    _q1 = 0;
    _q3 = 0;
    _q10 = 0;
    _msg = '';
  });

  Future<void> _confirmBuy() async {
    setState(() => _msg = '');
    if (_totalStamps <= 0) {
      setState(() => _msg = '请选择数量。');
      return;
    }
    // MVP：本地模拟增加邮票。上架后接 Google Play Billing + 后端校验。
    final next = StampWallet(_wallet.stamps + _totalStamps);
    await LocalStore.saveWallet(next);
    if (!mounted) return;
    setState(() {
      _wallet = next;
      _msg = '已购买 +$_totalStamps 枚（演示）。';
      _q1 = 0;
      _q3 = 0;
      _q10 = 0;
    });
  }

  Widget _row(String title, String subtitle, int q, VoidCallback minus, VoidCallback plus) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            IconButton(onPressed: q > 0 ? minus : null, icon: const Icon(Icons.remove_circle_outline)),
            Text('$q', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            IconButton(onPressed: plus, icon: const Icon(Icons.add_circle_outline)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return FateScaffold(
      title: '邮票',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('当前邮票：${_wallet.stamps} 枚', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 10),
          _row('1 封邮票', '￥6  ·  适合先试一封', _q1,
              () => setState(() => _q1 = (_q1 - 1).clamp(0, 99)),
              () => setState(() => _q1 = (_q1 + 1).clamp(0, 99))),
          _row('3 封邮票', '￥15  ·  更划算', _q3,
              () => setState(() => _q3 = (_q3 - 1).clamp(0, 99)),
              () => setState(() => _q3 = (_q3 + 1).clamp(0, 99))),
          _row('10 封邮票', '￥30  ·  适合长期写', _q10,
              () => setState(() => _q10 = (_q10 - 1).clamp(0, 99)),
              () => setState(() => _q10 = (_q10 + 1).clamp(0, 99))),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(child: Text('合计：$_totalStamps 枚', style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text('￥$_totalPrice', style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _clear, child: const Text('取消/清空'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton(onPressed: _confirmBuy, child: const Text('确认购买'))),
            ],
          ),
          const SizedBox(height: 8),
          Text(_msg, style: const TextStyle(color: Colors.red)),
          const Spacer(),
          const Text('建议：72小时未被接受 → 自动退回邮票（后端做定时任务）。', style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}
