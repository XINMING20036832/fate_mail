import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/local_store.dart';
import '../widgets/nebula_background.dart';
import '../widgets/rules_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Profile? _profile;
  StampWallet _wallet = StampWallet(0);
  int _pendingCount = 0;
  int _incomingCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await LocalStore.loadProfile();
    final w = await LocalStore.loadWallet();
    final pending = await LocalStore.loadPending();
    final incoming = await LocalStore.loadIncoming();

    if (!mounted) return;
    setState(() {
      _profile = p;
      _wallet = w;
      _pendingCount = pending.where((e) => e.status == RequestStatus.pending).length;
      _incomingCount = incoming.where((e) => e.status == RequestStatus.incoming).length;
      _loading = false;
    });
  }

  Widget _pill(String text, IconData icon, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        appBar: AppBar(
          title: const Text('另一个我'),
          actions: [
            IconButton(
              onPressed: () => showRulesSheet(context),
              icon: const Icon(Icons.auto_awesome),
              tooltip: '规则与氛围',
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/settings').then((_) => _load()),
              icon: const Icon(Icons.settings_outlined),
              tooltip: '设置',
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (_profile == null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('尚未绑定出生信息', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text(
                                '请先绑定出生日期与时辰，才能找到“另一个我”。',
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.75)),
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                                child: const Text('去绑定'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('你的坐标', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _pill('生日：${_profile!.birthDate}', Icons.cake_outlined),
                                  _pill('时辰：${_profile!.shichen}', Icons.schedule),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '同一刻出生的人，往往在“喜与痛”的节点上有相似的回声。\n你不需要解释自己太多。',
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.72), height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('邮票余额', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.75))),
                                  const SizedBox(height: 6),
                                  Text('${_wallet.stamps}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 8),
                                  Text('1封信 = 1张邮票（6元）', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('等待中的决定', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.75))),
                                  const SizedBox(height: 6),
                                  Text('$_pendingCount', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 8),
                                  Text('同一时间只允许1个决定', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('现在做什么？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () => Navigator.pushNamed(context, '/compose').then((_) => _load()),
                                    icon: const Icon(Icons.edit_note),
                                    label: const Text('写一封信'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pushNamed(context, '/wallet').then((_) => _load()),
                                    icon: const Icon(Icons.local_post_office_outlined),
                                    label: const Text('买邮票'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pushNamed(context, '/pending').then((_) => _load()),
                                    icon: const Icon(Icons.hourglass_bottom),
                                    label: Text('我在等($_pendingCount)'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pushNamed(context, '/incoming').then((_) => _load()),
                                    icon: const Icon(Icons.mark_email_unread_outlined),
                                    label: Text('我收到($_incomingCount)'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/mailbox').then((_) => _load()),
                              icon: const Icon(Icons.all_inbox_outlined),
                              label: const Text('打开信箱'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      '提示：这是一对一的信件模式。我们不展示公开广场，也不提供“刷人”。\n这样你写出的每一句话，都更像写给“另一个我”。',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6), height: 1.5),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
