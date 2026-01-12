import "dart:convert";
import "dart:math";
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await Store.create();
  runApp(App(store: store));
}

class App extends StatelessWidget {
  final Store store;
  const App({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C6CFF),
      brightness: Brightness.dark,
      background: const Color(0xFF070A12),
      surface: const Color(0xFF0E1426),
    );

    return MaterialApp(
      title: "另一个我",
      debugShowCheckedModeBanner: false, // ③ 去掉右上角 DEBUG 斜条
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF070A12),
        cardColor: const Color(0xFF0E1426),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.1),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          bodyMedium: TextStyle(fontSize: 14, height: 1.4),
        ),
      ),
      home: Shell(store: store),
    );
  }
}

class Store {
  final SharedPreferences sp;
  Store._(this.sp);
  static Future<Store> create() async => Store._(await SharedPreferences.getInstance());

  static const kBalance = "stamp_balance";
  static const kLocked = "stamp_locked";
  static const kPending = "pending_request";
  static const kSeen = "seen_onboarding";

  int get balance => sp.getInt(kBalance) ?? 0; // 默认不做试用：0
  int get locked => sp.getInt(kLocked) ?? 0;
  bool get seen => sp.getBool(kSeen) ?? false;

  Future<void> setSeen() => sp.setBool(kSeen, true);
  Future<void> setBalance(int v) => sp.setInt(kBalance, v);
  Future<void> setLocked(int v) => sp.setInt(kLocked, v);

  Pending? get pending {
    final raw = sp.getString(kPending);
    if (raw == null || raw.isEmpty) return null;
    return Pending.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> setPending(Pending? p) async {
    if (p == null) {
      await sp.remove(kPending);
    } else {
      await sp.setString(kPending, jsonEncode(p.toJson()));
    }
  }

  Future<bool> autoExpire72h() async {
    final p = pending;
    if (p == null) return false;
    final due = p.createdAtMs + const Duration(hours: 72).inMilliseconds;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now >= due) {
      final lk = locked;
      if (lk > 0) {
        await setBalance(balance + lk);
        await setLocked(0);
      }
      await setPending(null);
      return true;
    }
    return false;
  }
}

class Pending {
  final int createdAtMs;
  final String mood;
  final String content;
  const Pending({required this.createdAtMs, required this.mood, required this.content});
  Map<String, dynamic> toJson() => {"createdAtMs": createdAtMs, "mood": mood, "content": content};
  static Pending fromJson(Map<String, dynamic> j) => Pending(
    createdAtMs: (j["createdAtMs"] as num).toInt(),
    mood: (j["mood"] ?? "").toString(),
    content: (j["content"] ?? "").toString(),
  );
}

class Copy {
  static const hook = "同年同月同日同一刻出生的人，像被投进同一条时间河。\n"
      "人生不可能完全相同，但很多拐点、情绪与考题，会出现共振。\n"
      "你写下的，也许正是“另一个我”正在经历的。";

  static const whyLetter = "微信太快：一句话发出去，很快就被新的信息淹没。\n"
      "信不一样——它更郑重、更像仪式。\n"
      "很多人曾把“等一封信”当作精神支撑，\n"
      "不是因为慢，而是因为它足够认真。";

  static const privacy = "我们不参与信件内容，不做公开展示。\n"
      "我们只提供站内投递与临时匿名信箱。\n"
      "默认隐藏任何联系方式；未经双方同意，不会交换。";

  static const micro = "对方先同意，信才会送达；拒绝/超时，邮票自动退回。";

  static const flow = [
    "每封信=1张邮票（一次结缘尝试）。",
    "投递后先进入等待池：对方先看到“接受/拒绝”，不先看到你的内容。",
    "对方点“接受”，首封才真正送达，并建立1对1匿名信箱。",
    "对方拒绝或72小时未处理：邮票自动退回余额，继续待用。",
    "你随时可以撤回：邮票立刻退回。",
    "默认隐藏联系方式；只有双方都同意才会交换（后续版本上线）。",
  ];
}

class Shell extends StatefulWidget {
  final Store store;
  const Shell({super.key, required this.store});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int idx = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.store.autoExpire72h();
      if (!widget.store.seen && mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => Onboarding(store: widget.store),
        );
      }
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      Home(store: widget.store, go: (i) => setState(() => idx = i)),
      Compose(store: widget.store, goStore: () => setState(() => idx = 2)),
      StampStore(store: widget.store),
    ];

    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: "首页"),
          NavigationDestination(icon: Icon(Icons.edit_note_rounded), label: "写信"),
          NavigationDestination(icon: Icon(Icons.local_post_office_rounded), label: "邮票"),
        ],
      ),
    );
  }
}

class Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onHelp;
  const Header({super.key, required this.title, required this.subtitle, required this.onHelp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 50, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1020), Color(0xFF1B1A3A), Color(0xFF0B1020)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: IgnorePointer(child: Opacity(opacity: 0.75, child: CustomPaint(painter: Stars())))),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ),
              IconButton(onPressed: onHelp, icon: const Icon(Icons.help_outline_rounded, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

class Stars extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(7);
    final dot = Paint()..color = Colors.white.withOpacity(0.18);
    final line = Paint()..color = Colors.white.withOpacity(0.10)..strokeWidth = 1;
    final pts = <Offset>[];
    for (var i = 0; i < 28; i++) {
      pts.add(Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height));
    }
    for (var i = 0; i < pts.length; i++) {
      for (var j = i + 1; j < pts.length; j++) {
        final d = (pts[i] - pts[j]).distance;
        if (d < 90) canvas.drawLine(pts[i], pts[j], line);
      }
    }
    for (final p in pts) { canvas.drawCircle(p, 1.6, dot); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CardBox extends StatelessWidget {
  final Widget child;
  const CardBox({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF101A33), Color(0xFF0D1224)]),
        border: Border.all(color: const Color(0xFF2A3350)),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(22), child: Padding(padding: const EdgeInsets.all(18), child: child)),
    );
  }
}

class Home extends StatefulWidget {
  final Store store;
  final void Function(int) go;
  const Home({super.key, required this.store, required this.go});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    final bal = widget.store.balance;
    final locked = widget.store.locked;
    final pending = widget.store.pending;

    return Column(
      children: [
        Header(
          title: "另一个我",
          subtitle: "写一封信，投递给同一刻出生的那个人。\n${Copy.micro}",
          onHelp: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => Rules()),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 10, bottom: 24),
            children: [
              CardBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("为什么你会相信这件事", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(Copy.hook, style: Theme.of(context).textTheme.bodyMedium),
              ])),
              CardBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("邮票", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text("可用：$bal   锁定：$locked", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text("锁定=已投递等待确认。拒绝/超时/撤回都会退回。", style: Theme.of(context).textTheme.bodyMedium),
                if (pending != null) ...[
                  const SizedBox(height: 10),
                  Text("进行中：等待对方确认（72小时超时自动退回）", style: Theme.of(context).textTheme.bodyMedium),
                ]
              ])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  Expanded(child: FilledButton(
                    onPressed: () => widget.go(1),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text("写一封信", style: TextStyle(fontWeight: FontWeight.w900)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton(
                    onPressed: () => widget.go(2),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text("买邮票（6/15/30）"),
                  )),
                ]),
              ),
              CardBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("写信比微信更浪漫", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(Copy.whyLetter, style: Theme.of(context).textTheme.bodyMedium),
              ])),
            ],
          ),
        )
      ],
    );
  }
}

class Compose extends StatefulWidget {
  final Store store;
  final VoidCallback goStore;
  const Compose({super.key, required this.store, required this.goStore});
  @override
  State<Compose> createState() => _ComposeState();
}

class _ComposeState extends State<Compose> {
  final ctrl = TextEditingController();
  String mood = "迷茫";
  @override
  void dispose() { ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bal = widget.store.balance;
    final pending = widget.store.pending;

    return Column(
      children: [
        Header(
          title: "写给另一个我",
          subtitle: "不是聊天，是一封郑重的信。\n${Copy.micro}",
          onHelp: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => Rules()),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 10, bottom: 24),
            children: [
              if (bal <= 0)
                CardBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("你还没有邮票", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text("邮票=一次投递机会（拒绝/超时会退回）。先买1封试试。", style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: widget.goStore, child: const Text("去买邮票")),
                ])),
              if (pending != null)
                CardBox(child: Text("你已有一封正在等待确认。\n同一时刻只允许1封进行中。", style: Theme.of(context).textTheme.bodyMedium)),
              CardBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("此刻的你", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: ["高兴","平静","焦虑","迷茫","失落","想倾诉"].map((m) {
                  return ChoiceChip(label: Text(m), selected: mood==m, onSelected: (_) => setState(() => mood=m));
                }).toList()),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  minLines: 6,
                  maxLines: 10,
                  decoration: InputDecoration(
                    hintText: "写具体一点：你在经历什么？你最想被理解的一句话是什么？",
                    filled: true,
                    fillColor: const Color(0xFF0B1020),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () async {
                    if (widget.store.pending != null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已有进行中的信。")));
                      return;
                    }
                    final txt = ctrl.text.trim();
                    if (txt.length < 10) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("写10个字以上，更容易共振。")));
                      return;
                    }
                    if (widget.store.balance <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("邮票不足，先去购买。")));
                      return;
                    }
                    await widget.store.setBalance(widget.store.balance - 1);
                    await widget.store.setLocked(1);
                    await widget.store.setPending(Pending(
                      createdAtMs: DateTime.now().millisecondsSinceEpoch,
                      mood: mood,
                      content: txt,
                    ));
                    ctrl.clear();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已投递：对方先同意才送达；拒绝/超时邮票自动退回。")));
                    setState(() {});
                  },
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text("投递（锁定1张邮票）", style: TextStyle(fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: widget.store.pending == null ? null : () async {
                    final lk = widget.store.locked;
                    if (lk > 0) {
                      await widget.store.setBalance(widget.store.balance + lk);
                      await widget.store.setLocked(0);
                    }
                    await widget.store.setPending(null);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已撤回：邮票已退回待用。")));
                    setState(() {});
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text("撤回（退回邮票）"),
                )
              ])),
            ],
          ),
        )
      ],
    );
  }
}

class StampStore extends StatefulWidget {
  final Store store;
  const StampStore({super.key, required this.store});
  @override
  State<StampStore> createState() => _StampStoreState();
}

class _StampStoreState extends State<StampStore> {
  int selected = 0; // 0=未选择；1/3/10

  int price(int c) => c==1 ? 6 : (c==3 ? 15 : (c==10 ? 30 : 0));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(
          title: "邮票",
          subtitle: "邮票=一次投递机会。\n${Copy.micro}",
          onHelp: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => Rules()),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 10, bottom: 24),
            children: [
              CardBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("当前余额", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text("可用：${widget.store.balance}   锁定：${widget.store.locked}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text("锁定=已投递等待确认。拒绝/超时/撤回都会退回。", style: Theme.of(context).textTheme.bodyMedium),
              ])),
              CardBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("选择套餐（可取消/可改）", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _pkg(1, "一封", "给“另一个我”的一次投递"),
                const SizedBox(height: 10),
                _pkg(3, "三封", "更适合：连续写下不同阶段的你"),
                const SizedBox(height: 10),
                _pkg(10, "十封", "长期陪伴：把人生写成一条暗线"),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: selected==0 ? null : () => setState(() => selected=0),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text("取消选择"),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(
                    onPressed: selected==0 ? null : () async {
                      // 这里是演示“加余额”。接支付后，把这段放到支付成功回调里即可。
                      await widget.store.setBalance(widget.store.balance + selected);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("已购买：$selected封（${price(selected)}元，演示）")));
                      setState(() => selected=0);
                    },
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Text(selected==0 ? "确认购买" : "确认购买（${price(selected)}元）", style: const TextStyle(fontWeight: FontWeight.w900)),
                  )),
                ]),
                const SizedBox(height: 10),
                Text("说明：本版本未接支付，按钮为演示。接支付后体验不变。", style: Theme.of(context).textTheme.bodyMedium),
              ])),
            ],
          ),
        )
      ],
    );
  }

  Widget _pkg(int c, String title, String sub) {
    final sel = selected==c;
    final border = sel ? const Color(0xFF7C6CFF) : const Color(0xFF2A3350);
    final bg = sel ? const Color(0xFF141A36) : const Color(0xFF0B1020);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => selected = sel ? 0 : c),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: bg, border: Border.all(color: border, width: 1.2)),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: sel ? [const Color(0xFF7C6CFF).withOpacity(0.35), const Color(0xFF0B1020)] : [const Color(0xFF1A2340), const Color(0xFF0B1020)]),
            ),
            child: Center(child: Text("$c", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("$title · ${price(c)}元", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 13, height: 1.35)),
          ])),
          Icon(sel ? Icons.check_circle_rounded : Icons.circle_outlined, color: sel ? const Color(0xFF7C6CFF) : Colors.white54),
        ]),
      ),
    );
  }
}

class Onboarding extends StatelessWidget {
  final Store store;
  const Onboarding({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF0E1426),
          border: Border.all(color: const Color(0xFF2A3350)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("欢迎来到《另一个我》", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(Copy.hook, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text(Copy.whyLetter, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text(Copy.micro, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async { await store.setSeen(); if (context.mounted) Navigator.pop(context); },
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text("我明白了", style: TextStyle(fontWeight: FontWeight.w900)),
          )
        ]),
      ),
    );
  }
}

class Rules extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF0E1426),
          border: Border.all(color: const Color(0xFF2A3350)),
        ),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("规则与隐私", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(Copy.hook, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text("写信比微信更有分量", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(Copy.whyLetter, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text("流程（你一眼就懂）", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...Copy.flow.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("•  ", style: TextStyle(fontWeight: FontWeight.w900)),
                Expanded(child: Text(s, style: Theme.of(context).textTheme.bodyMedium)),
              ]),
            )),
            const SizedBox(height: 12),
            Text("隐私", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(Copy.privacy, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text("关闭"),
            )
          ]),
        ),
      ),
    );
  }
}
