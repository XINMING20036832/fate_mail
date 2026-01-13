\
import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../widgets/fate_scaffold.dart';
import '../widgets/fate_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Profile? _profile;
  StampWallet? _wallet;

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
    final w = _wallet;

    return FateScaffold(
      title: '另一个我',
      actions: [
        IconButton(
          tooltip: '规则',
          onPressed: () => Navigator.pushNamed(context, '/rules'),
          icon: const Icon(Icons.auto_awesome),
        ),
        IconButton(
          tooltip: '设置',
          onPressed: () => Navigator.pushNamed(context, '/settings').then((_) => _load()),
          icon: const Icon(Icons.settings),
        ),
      ],
      body: ListView(
        children: [
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('你的命运坐标', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p == null ? '未绑定' : '${p.birthDate} · ${p.shichen}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (w != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withOpacity(0.10)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_post_office, size: 16),
                            const SizedBox(width: 6),
                            Text('${w.stamps}'),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '你写下的每一封信，都只会投递给“同年同月同日同一时辰”的那个人。',
                  style: TextStyle(color: Colors.white.withOpacity(0.80)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/compose').then((_) => _load()),
                      icon: const Icon(Icons.edit),
                      label: const Text('写一封'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/wallet').then((_) => _load()),
                      icon: const Icon(Icons.shopping_bag),
                      label: const Text('买邮票'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/profile').then((_) => _load()),
                      icon: const Icon(Icons.person),
                      label: Text(p == null ? '绑定坐标' : '改资料'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('为什么不是微信？', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(
                  '因为你需要的不是“随手一句”，而是一封值得等待的信。\n'
                  '当你高兴、失落、无助，或者只是想找一个懂你的人——你会更愿意把它写进信里。',
                  style: TextStyle(color: Colors.white.withOpacity(0.80), height: 1.35),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, '/pending'),
                        child: const Text('我在等待'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, '/incoming'),
                        child: const Text('我收到的请求卡'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/mailbox'),
                  child: const Text('我的信箱'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('一句话就能上手', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                _step('1', '绑定你的命运坐标（出生日期 + 时辰）'),
                _step('2', '买邮票：1 / 3 / 10 封'),
                _step('3', '写信 → 进入等待（最多72小时）'),
                _step('4', '对方接受后才能阅读；撤回/拒绝/超时会退邮票'),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/rules'),
                  child: const Text('查看完整规则与隐私说明'),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Text(n, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: Colors.white.withOpacity(0.80), height: 1.25))),
        ],
      ),
    );
  }
}
