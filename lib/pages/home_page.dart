import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../widgets/fate_background.dart';
import '../widgets/fate_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Profile? _profile;
  StampWallet _wallet = const StampWallet(0);

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

  String _fateEditHint(Profile p) {
    final boundAt = p.boundAt;
    if (boundAt <= 0) return '';
    final now = DateTime.now().millisecondsSinceEpoch;
    final remainMs = (boundAt + 24 * 60 * 60 * 1000) - now;
    final can = p.fateEditsLeft > 0 && remainMs > 0;
    if (!can) return '已锁定';
    final h = (remainMs / (60 * 60 * 1000)).floor();
    final m = ((remainMs % (60 * 60 * 1000)) / (60 * 1000)).floor();
    return '可改1次 · 剩余 ${h}h${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    if (p == null) {
      return const Scaffold(body: Center(child: Text('未绑定时间坐标')));
    }

    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('另一个我'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/rules'),
            icon: const Icon(Icons.shield_outlined),
            tooltip: '规则与隐私',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings').then((_) => _load()),
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
          ),
        ],
      ),
      body: FateBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FateCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('你的命运坐标', style: t.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        '${p.birthDate}  ·  ${p.shichen}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _fateEditHint(p),
                        style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '你写的是心事，不是社交。
当你需要一个“能懂你”的回声时，它会出现。',
                        style: TextStyle(color: scheme.onSurface.withOpacity(0.78), height: 1.25),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FateCard(
                  child: Row(
                    children: [
                      const Icon(Icons.local_post_office_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('邮票余额', style: t.titleMedium),
                            const SizedBox(height: 2),
                            Text('${_wallet.stamps} 枚（6元/封）', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pushNamed(context, '/wallet').then((_) => _load()),
                        child: const Text('购买'),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/compose').then((_) => _load()),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('写给另一个我'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/incoming').then((_) => _load()),
                        icon: const Icon(Icons.inbox_outlined),
                        label: const Text('我收到的请求卡'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/pending').then((_) => _load()),
                        icon: const Icon(Icons.schedule),
                        label: const Text('我在等待'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/mailbox').then((_) => _load()),
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('我的信箱'),
                ),
                const SizedBox(height: 18),
                Text(
                  '一句话规则：先“请求卡”，再“信内容”。\n对方拒绝，不再打扰；你可在对方接受前撤回，邮票退回待用。',
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
