\
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_store.dart';
import '../models/models.dart';
import '../widgets/fate_scaffold.dart';
import '../widgets/fate_card.dart';

class IncomingPage extends StatefulWidget {
  const IncomingPage({super.key});

  @override
  State<IncomingPage> createState() => _IncomingPageState();
}

class _IncomingPageState extends State<IncomingPage> {
  List<MailRequest> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await LocalStore.loadIncoming();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _seedDemo() async {
    // Demo: 生成一张“来自另一个我”的请求卡，方便你测试接受/拒绝流程
    final me = await LocalStore.getOrCreateUserId();
    final now = DateTime.now().millisecondsSinceEpoch;
    final req = MailRequest(
      id: 'in_$now',
      fromUserId: 'someone_$now',
      toUserId: me,
      fateKey: '同年同月同日同一时辰',
      status: 'pending',
      createdAt: now,
      templateState: '想倾诉',
      templatePace: '慢慢说',
      extraLine: '你最近还好吗？',
    );
    final list = await LocalStore.loadIncoming();
    list.insert(0, req);
    await LocalStore.saveIncoming(list);
    await _load();
  }

  Future<void> _accept(MailRequest req) async {
    // 更新状态
    final list = await LocalStore.loadIncoming();
    final next = list.map((e) {
      if (e.id == req.id) {
        return MailRequest(
          id: e.id,
          fromUserId: e.fromUserId,
          toUserId: e.toUserId,
          fateKey: e.fateKey,
          status: 'accepted',
          createdAt: e.createdAt,
          templateState: e.templateState,
          templatePace: e.templatePace,
          extraLine: e.extraLine,
        );
      }
      return e;
    }).toList();
    await LocalStore.saveIncoming(next);

    // 生成一封“邮件内容”（MVP：根据模板拼成正文）
    final body = [
      '【来自：另一个我】',
      if (req.templateState.isNotEmpty) 'TA此刻：${req.templateState}',
      if (req.templatePace.isNotEmpty) '语气：${req.templatePace}',
      if (req.extraLine.isNotEmpty) 'TA说：${req.extraLine}',
      '',
      '（正式版：这里会显示对方真实写下的信件正文）',
    ].join('\n');

    final mail = MailItem(
      id: 'mail_${DateTime.now().millisecondsSinceEpoch}',
      requestId: req.id,
      fromUserId: req.fromUserId,
      toUserId: req.toUserId,
      body: body,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final box = await LocalStore.loadMailbox();
    box.insert(0, mail);
    await LocalStore.saveMailbox(box);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已接受，信件已进入信箱')));
    Navigator.pushNamed(context, '/mailbox');
  }

  Future<void> _reject(MailRequest req) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('拒绝这张请求卡？'),
        content: const Text('拒绝后，对方会收到“退待用”的邮票，不会看到你的任何信息。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('拒绝')),
        ],
      ),
    );
    if (ok != true) return;

    final list = await LocalStore.loadIncoming();
    final next = list.map((e) {
      if (e.id == req.id) {
        return MailRequest(
          id: e.id,
          fromUserId: e.fromUserId,
          toUserId: e.toUserId,
          fateKey: e.fateKey,
          status: 'rejected',
          createdAt: e.createdAt,
          templateState: e.templateState,
          templatePace: e.templatePace,
          extraLine: e.extraLine,
        );
      }
      return e;
    }).toList();
    await LocalStore.saveIncoming(next);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已拒绝')));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return FateScaffold(
      title: '我收到的请求卡',
      actions: [
        IconButton(
          tooltip: '生成一张测试请求卡',
          onPressed: _seedDemo,
          icon: const Icon(Icons.add),
        ),
      ],
      body: _items.isEmpty
          ? Center(
              child: FateCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox, size: 36),
                    const SizedBox(height: 10),
                    Text('还没有收到请求卡', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('你可以点右上角 + 生成一张测试卡。', style: TextStyle(color: Colors.white.withOpacity(0.75))),
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final r = _items[i];
                final dt = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
                final time = DateFormat('yyyy-MM-dd HH:mm').format(dt);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FateCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('请求卡', style: Theme.of(context).textTheme.titleMedium),
                            ),
                            _statusChip(r.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('命运坐标：${r.fateKey}', style: TextStyle(color: Colors.white.withOpacity(0.82))),
                        const SizedBox(height: 6),
                        Text('时间：$time', style: TextStyle(color: Colors.white.withOpacity(0.70))),
                        const SizedBox(height: 10),
                        if (r.status == 'pending')
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _accept(r),
                                  child: const Text('接受'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _reject(r),
                                  child: const Text('拒绝'),
                                ),
                              ),
                            ],
                          )
                        else
                          Text('已处理', style: TextStyle(color: Colors.white.withOpacity(0.70))),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _statusChip(String s) {
    String text;
    switch (s) {
      case 'pending':
        text = '待处理';
        break;
      case 'accepted':
        text = '已接受';
        break;
      case 'rejected':
        text = '已拒绝';
        break;
      default:
        text = s;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
