import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../widgets/fate_background.dart';
import '../widgets/fate_card.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  StampWallet _wallet = const StampWallet(0);
  bool _loading = true;
  int _selected = 0;
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

  void _setSelected(int v) {
    setState(() {
      _msg = '';
      _selected = v.clamp(0, 999);
    });
  }

  int _priceFor(int count) {
    if (count <= 0) return 0;
    // Bundle pricing: 1=6, 3=15, 10=30 (greedy works here).
    final ten = count ~/ 10;
    final rem10 = count % 10;
    final three = rem10 ~/ 3;
    final one = rem10 % 3;
    return ten * 30 + three * 15 + one * 6;
  }

  Future<void> _buySelected() async {
    final count = _selected;
    if (count <= 0) {
      setState(() => _msg = '先选择要购买的邮票数量。');
      return;
    }
    final next = StampWallet(_wallet.stamps + count);
    await LocalStore.saveWallet(next);
    if (!mounted) return;
    setState(() {
      _wallet = next;
      _selected = 0;
      _msg = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('购买成功：+$count 枚（本地模拟）')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('邮票')),
      body: FateBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FateCard(
                  child: Row(
                    children: [
                      const Icon(Icons.local_post_office_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('当前邮票', style: t.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              '${_wallet.stamps} 枚',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Text('6/15/30', style: TextStyle(color: scheme.onSurface.withOpacity(0.75))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FateCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('选择购买数量', style: t.titleMedium),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _selected <= 0 ? null : () => _setSelected(_selected - 1),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: scheme.outline.withOpacity(0.4)),
                              ),
                              child: Text(
                                '$_selected',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _setSelected(_selected + 1),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _PriceChip(label: '6元', sub: '1封', onTap: () => _setSelected(1)),
                          _PriceChip(label: '15元', sub: '3封', onTap: () => _setSelected(3)),
                          _PriceChip(label: '30元', sub: '10封', onTap: () => _setSelected(10)),
                          ActionChip(
                            label: const Text('清空'),
                            onPressed: _selected == 0 ? null : () => _setSelected(0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: _buySelected,
                              child: Text('确认购买（${_priceFor(_selected)}元）'),
                            ),
                          ),
                        ],
                      ),
                      if (_msg.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_msg, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '提示：当前为本地模拟购买。正式上架后接入支付渠道即可。',
                        style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.65)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '邮票不是“收费点”，而是“认真度”。\n'
                  '你愿意为一封信付出一点成本，就更愿意好好写，也更愿意等待。',
                  style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.7), height: 1.3),
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

class _PriceChip extends StatelessWidget {
  final String label;
  final String sub;
  final VoidCallback onTap;
  const _PriceChip({required this.label, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline.withOpacity(0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}
