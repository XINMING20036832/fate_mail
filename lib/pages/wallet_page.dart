import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../services/local_store.dart';
import '../widgets/nebula_background.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  StampWallet _wallet = StampWallet(0);
  bool _loading = true;

  int _p1 = 0;
  int _p3 = 0;
  int _p10 = 0;

  int get _totalStamps => _p1 * 1 + _p3 * 3 + _p10 * 10;
  int get _totalPrice => _p1 * kPackPrice1 + _p3 * kPackPrice3 + _p10 * kPackPrice10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final w = await LocalStore.loadWallet();
    if (!mounted) return;
    setState(() {
      _wallet = w;
      _loading = false;
    });
  }

  Future<void> _applyPurchase() async {
    if (_totalStamps <= 0) return;
    setState(() => _loading = true);
    final newWallet = StampWallet(_wallet.stamps + _totalStamps);
    await LocalStore.saveWallet(newWallet);
    if (!mounted) return;
    setState(() {
      _wallet = newWallet;
      _p1 = 0;
      _p3 = 0;
      _p10 = 0;
      _loading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已购买 $_totalStamps 张邮票（模拟）。')),
    );
  }

  Widget _packTile({
    required String title,
    required String subtitle,
    required int count,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65))),
                ],
              ),
            ),
            IconButton(
              onPressed: onMinus,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            IconButton(
              onPressed: onPlus,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('邮票')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('当前余额', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.75))),
                                  const SizedBox(height: 6),
                                  Text('${_wallet.stamps}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 6),
                                  Text('1封信 = 1张邮票（6元）', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                                ],
                              ),
                            ),
                            const Icon(Icons.local_post_office, size: 34),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('选择购买套餐', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    _packTile(
                      title: '6 元 · 1 封',
                      subtitle: '适合先试一封',
                      count: _p1,
                      onMinus: () => setState(() => _p1 = (_p1 - 1).clamp(0, 99)),
                      onPlus: () => setState(() => _p1 = (_p1 + 1).clamp(0, 99)),
                    ),
                    _packTile(
                      title: '15 元 · 3 封',
                      subtitle: '更划算，适合连续写',
                      count: _p3,
                      onMinus: () => setState(() => _p3 = (_p3 - 1).clamp(0, 99)),
                      onPlus: () => setState(() => _p3 = (_p3 + 1).clamp(0, 99)),
                    ),
                    _packTile(
                      title: '30 元 · 10 封',
                      subtitle: '适合长期使用',
                      count: _p10,
                      onMinus: () => setState(() => _p10 = (_p10 - 1).clamp(0, 99)),
                      onPlus: () => setState(() => _p10 = (_p10 + 1).clamp(0, 99)),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('合计：$_totalStamps 张', style: const TextStyle(fontWeight: FontWeight.w800)),
                                ),
                                Text('￥$_totalPrice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _totalStamps <= 0 ? null : _applyPurchase,
                                    child: const Text('确认购买（MVP模拟）'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  onPressed: () => setState(() { _p1 = 0; _p3 = 0; _p10 = 0; }),
                                  child: const Text('清空'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '提示：正式版接入 Google Play Billing 后，服务器校验成功才会加邮票。\n未被接受/超时会退回邮票（正式版由后端定时任务处理）。',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6), height: 1.5),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
