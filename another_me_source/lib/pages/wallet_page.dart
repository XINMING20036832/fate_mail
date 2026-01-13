\
import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../widgets/fate_scaffold.dart';
import '../widgets/fate_card.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  StampWallet? _wallet;

  int _packStamps = 3;
  int _packPrice = 15;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final w = await LocalStore.loadWallet();
    if (!mounted) return;
    setState(() => _wallet = w);
  }

  void _selectPack(int stamps, int price) {
    setState(() {
      _packStamps = stamps;
      _packPrice = price;
      _qty = 1;
    });
  }

  int get _totalStamps => _packStamps * _qty;
  int get _totalPrice => _packPrice * _qty;

  Future<void> _buy() async {
    if (_qty <= 0) return;
    final w = await LocalStore.loadWallet();
    final next = StampWallet((w?.stamps ?? 0) + _totalStamps);
    await LocalStore.saveWallet(next);
    if (!mounted) return;
    setState(() => _wallet = next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已增加 $_totalStamps 张邮票（模拟购买）')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stamps = _wallet?.stamps ?? 0;

    return FateScaffold(
      title: '邮票',
      body: ListView(
        children: [
          FateCard(
            child: Row(
              children: [
                const Icon(Icons.local_post_office, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('我的邮票：$stamps 张', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: () => setState(() => _qty = 0),
                  child: const Text('取消选择'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('选择套餐', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                _packTile(stamps: 1, price: 6, selected: _packStamps == 1, onTap: () => _selectPack(1, 6)),
                const SizedBox(height: 10),
                _packTile(stamps: 3, price: 15, selected: _packStamps == 3, onTap: () => _selectPack(3, 15)),
                const SizedBox(height: 10),
                _packTile(stamps: 10, price: 30, selected: _packStamps == 10, onTap: () => _selectPack(10, 30)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('数量', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      onPressed: _qty <= 0 ? null : () => setState(() => _qty -= 1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_qty', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    IconButton(
                      onPressed: () => setState(() => _qty += 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    const Spacer(),
                    Text('共 $_totalStamps 张 / ￥$_totalPrice', style: TextStyle(color: Colors.white.withOpacity(0.85))),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _qty <= 0 ? null : _buy,
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('确认购买（模拟）'),
                ),
                const SizedBox(height: 8),
                Text(
                  '说明：当前版本为 MVP，购买为模拟增加邮票。正式版可接入支付。',
                  style: TextStyle(color: Colors.white.withOpacity(0.70)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _packTile({
    required int stamps,
    required int price,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.10) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.check_circle : Icons.circle_outlined, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('$stamps 张邮票', style: const TextStyle(fontWeight: FontWeight.w700))),
            Text('￥$price', style: TextStyle(color: Colors.white.withOpacity(0.85))),
          ],
        ),
      ),
    );
  }
}
