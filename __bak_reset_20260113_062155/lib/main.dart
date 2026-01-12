import "dart:convert";
import "dart:math";
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.create();
  runApp(AnotherMeApp(store: store));
}

class AnotherMeApp extends StatelessWidget {
  final LocalStore store;
  const AnotherMeApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF070A12);
    const panel = Color(0xFF0E1426);
    const panel2 = Color(0xFF0B1020);

    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C6CFF),
      brightness: Brightness.dark,
      background: bg,
      surface: panel,
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.1),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(fontSize: 14, height: 1.35),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      dividerColor: const Color(0xFF28314A),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false, // ③ 取消右上角 DEBUG 斜条
      title: "另一个我",
      theme: theme,
      home: MainShell(store: store),
    );
  }
}

/* ===================== 本地存储 ===================== */

class BirthProfile {
  final String ymd;        // YYYY-MM-DD
  final String hourBranch; // 子丑寅...
  const BirthProfile({required this.ymd, required this.hourBranch});

  Map<String, dynamic> toJson() => {"ymd": ymd, "hourBranch": hourBranch};
  static BirthProfile fromJson(Map<String, dynamic> j) =>
      BirthProfile(ymd: (j["ymd"] ?? "未设置").toString(), hourBranch: (j["hourBranch"] ?? "未设置").toString());
}

class PendingRequest {
  final int createdAtMs;
  final String mood;
  final String content;
  const PendingRequest({required this.createdAtMs, required this.mood, required this.content});

  Map<String, dynamic> toJson() => {"createdAtMs": createdAtMs, "mood": mood, "content": content};
  static PendingRequest fromJson(Map<String, dynamic> j) => PendingRequest(
        createdAtMs: (j["createdAtMs"] as num).toInt(),
        mood: (j["mood"] ?? "").toString(),
        content: (j["content"] ?? "").toString(),
      );
}

class LocalStore {
  final SharedPreferences sp;
  LocalStore._(this.sp);

  static const _kSeen = "seen_onboarding";
  static const _kStamp = "stamp_balance";
  static const _kLocked = "stamp_locked";
  static const _kPending = "pending_request";
  static const _kProfile = "birth_profile";

  static Future<LocalStore> create() async => LocalStore._(await SharedPreferences.getInstance());

  bool get hasSeenOnboarding => sp.getBool(_kSeen) ?? false;
  Future<void> markSeen() => sp.setBool(_kSeen, true);

  // 你要求不做试用：默认 0
  int get stampBalance => sp.getInt(_kStamp) ?? 0;
  Future<void> setStampBalance(int v) => sp.setInt(_kStamp, v);

  int get stampLocked => sp.getInt(_kLocked) ?? 0;
  Future<void> setStampLocked(int v) => sp.setInt(_kLocked, v);

  BirthProfile get profile {
    final raw = sp.getString(_kProfile);
    if (raw == null || raw.isEmpty) return const BirthProfile(ymd: "未设置", hourBranch: "未设置");
    return BirthProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> setProfile(BirthProfile p) => sp.setString(_kProfile, jsonEncode(p.toJson()));

  PendingRequest? get pending {
    final raw = sp.getString(_kPending);
    if (raw == null || raw.isEmpty) return null;
    return PendingRequest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> setPending(PendingRequest? p) async {
    if (p == null) {
      await sp.remove(_kPending);
    } else {
      await sp.setString(_kPending, jsonEncode(p.toJson()));
    }
  }

  // 72 小时超时：邮票自动退回待用
  Future<bool> autoExpireIfNeeded() async {
    final p = pending;
    if (p == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final due = p.createdAtMs + const Duration(hours: 72).inMilliseconds;
    if (now >= due) {
      final locked = stampLocked;
      if (locked > 0) {
        await setStampBalance(stampBalance + locked);
        await setStampLocked(0);
      }
      await setPending(null);
      return true;
    }
    return false;
  }
}

/* ===================== 文案：命运感 + 快速认同 ===================== */

class Copy {
  static const hookA = "同年同月同日同一刻出生的人，像被投进同一条时间河。";
  static const hookB = "人生不可能完全相同，但很多拐点、情绪与考题，往往会出现共振。";
  static const hookC = "你写下的，也许正是“另一个我”正在经历的。";

  static const whyLetter = "微信太快：一句话发出去就被新的信息淹没。\n"
      "信不一样——它更郑重、更像仪式：\n"
      "你把话放进时间里，等它在远处回响。\n"
      "很多人曾把“等一封信”当作精神支撑，\n"
      "不是因为慢，而是因为它足够认真。";

  static const privacy = "我们不参与信件内容，不做公开展示。\n"
      "我们只提供：站内投递 + 临时匿名信箱。\n"
      "默认隐藏任何联系方式；未经双方同意，不会交换。";

  static const micro = "对方先同意，信才会送达；拒绝/超时，邮票自动退回。";

  static const flowTitle = "规则（你一眼就能懂）";
  static const flow = [
    "每封信 = 1 张邮票（一次结缘尝试）。",
    "投递后先进入同命等待池：对方先看到“接受/拒绝”，不先看到你的内容。",
    "对方点“接受”，首封才真正送达，并建立 1 对 1 匿名信箱。",
    "对方拒绝或 72 小时未处理：邮票自动退回余额，继续待用。",
    "你随时可以撤回：邮票立刻退回。",
    "默认隐藏任何联系方式；只有双方都同意才会交换（后续版本上线）。",
  ];
}

/* ===================== 视觉组件：工业 + 命运 ===================== */

class FateHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  const FateHeader({super.key, required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 48, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1020), Color(0xFF1B1A3A), Color(0xFF0B1020)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.75,
                child: CustomPaint(painter: ConstellationPainter()),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white.withOpacity(0.88))),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}

class ConstellationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(7);
    final p = Paint()..color = Colors.white.withOpacity(0.18);
    final line = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 1;

    final pts = <Offset>[];
    for (var i = 0; i < 28; i++) {
      pts.add(Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height));
    }

    // lines
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i];
      // connect to nearest few
      for (var j = i + 1; j < pts.length; j++) {
        final b = pts[j];
        final d = (a - b).distance;
        if (d < 90) canvas.drawLine(a, b, line);
      }
    }

    // dots
    for (final o in pts) {
      canvas.drawCircle(o, 1.6, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FateCard extends StatelessWidget {
  final Widget child;
  const FateCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101A33), Color(0xFF0D1224)],
        ),
        border: Border.all(color: const Color(0xFF2A3350)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: child,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const PrimaryButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

/* ===================== Shell ===================== */

class MainShell extends StatefulWidget {
  final LocalStore store;
  const MainShell({super.key, required this.store});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int idx = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!widget.store.hasSeenOnboarding && mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => OnboardingSheet(store: widget.store),
        );
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(store: widget.store, onGo: (i) => setState(() => idx = i)),
      ComposePage(store: widget.store, onGoStamps: () => setState(() => idx = 3)),
      InboxPage(store: widget.store),
      StampStorePage(store: widget.store),
    ];

    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: "首页"),
          NavigationDestination(icon: Icon(Icons.edit_note_rounded), label: "写信"),
          NavigationDestination(icon: Icon(Icons.mail_rounded), label: "信箱"),
          NavigationDestination(icon: Icon(Icons.local_post_office_rounded), label: "邮票"),
        ],
      ),
    );
  }
}

/* ===================== 页面：首页 ===================== */

class HomePage extends StatefulWidget {
  final LocalStore store;
  final void Function(int) onGo;
  const HomePage({super.key, required this.store, required this.onGo});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final expired = await widget.store.autoExpireIfNeeded();
      if (expired && mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final prof = widget.store.profile;
    final bal = widget.store.stampBalance;
    final locked = widget.store.stampLocked;

    return Column(
      children: [
        FateHeader(
          title: "另一个我",
          subtitle: "写一封信，投递给同一刻出生的那个人。\n${Copy.micro}",
          trailing: IconButton(
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => RulesSheet(store: widget.store),
              );
              setState(() {});
            },
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 10, bottom: 24),
            children: [
              FateCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("你的命运坐标", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFF0B1020),
                          border: Border.all(color: const Color(0xFF2A3350)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place_rounded),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text("${prof.ymd} · ${prof.hourBranch}时",
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                            TextButton(
                              onPressed: () async {
                                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage(store: widget.store)));
                                setState(() {});
                              },
                              child: const Text("修改"),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(Copy.hookA, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(Copy.hookB, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(Copy.hookC, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              FateCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("邮票", style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text("可用：$bal   锁定：$locked",
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text("锁定=已投递，等待对方确认。\n拒绝/超时/撤回都会退回。",
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      const Icon(Icons.local_post_office_rounded, size: 34),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: "写一封信",
                        onPressed: () => widget.onGo(1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => widget.onGo(2),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("去信箱"),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: OutlinedButton.icon(
                  onPressed: () => widget.onGo(3),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text("购买邮票（6/15/30 元）"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ===================== 页面：写信 ===================== */

class ComposePage extends StatefulWidget {
  final LocalStore store;
  final VoidCallback onGoStamps;
  const ComposePage({super.key, required this.store, required this.onGoStamps});

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  final ctrl = TextEditingController();
  String mood = "迷茫";

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.store.pending;
    final bal = widget.store.stampBalance;

    return Column(
      children: [
        FateHeader(
          title: "写给另一个我",
          subtitle: "不是聊天，是一封郑重的信。\n${Copy.micro}",
          trailing: IconButton(
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => RulesSheet(store: widget.store),
              );
              setState(() {});
            },
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 10, bottom: 24),
            children: [
              if (bal <= 0)
                FateCard(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("你还没有邮票", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Text("邮票=一次投递机会（对方拒绝/超时会退回）。\n先买 1 封试试也行。",
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        PrimaryButton(text: "去购买邮票（6/15/30 元）", onPressed: widget.onGoStamps),
                      ],
                    ),
                  ),
                ),
              if (pending != null)
                FateCard(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("你已有一封正在等待确认", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Text("同一时刻只允许 1 封进行中。\n这不是撒网，而是命运的一对一。",
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              FateCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("此刻的你", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ["高兴", "平静", "焦虑", "迷茫", "失落", "想倾诉"].map((m) {
                          final sel = mood == m;
                          return ChoiceChip(
                            label: Text(m),
                            selected: sel,
                            onSelected: (_) => setState(() => mood = m),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      Text("写下你想说的话", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      TextField(
                        controller: ctrl,
                        minLines: 6,
                        maxLines: 10,
                        decoration: InputDecoration(
                          hintText: "写具体一点：你在经历什么？你最想被理解的一句话是什么？",
                          filled: true,
                          fillColor: const Color(0xFF0B1020),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              text: "投递到同命等待池（锁定 1 张邮票）",
                              onPressed: () async {
                                final p = widget.store.pending;
                                if (p != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已有进行中的信。")));
                                  return;
                                }
                                final txt = ctrl.text.trim();
                                if (txt.length < 10) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("写 10 个字以上，更容易共振。")));
                                  return;
                                }
                                final b = widget.store.stampBalance;
                                if (b <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("邮票不足，先去购买。")));
                                  return;
                                }
                                await widget.store.setStampBalance(b - 1);
                                await widget.store.setStampLocked(1);
                                await widget.store.setPending(PendingRequest(
                                  createdAtMs: DateTime.now().millisecondsSinceEpoch,
                                  mood: mood,
                                  content: txt,
                                ));
                                ctrl.clear();
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已投递：对方先同意才送达；拒绝/超时邮票自动退回。")));
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              FateCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("为什么写信比微信更浪漫", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Text(Copy.whyLetter, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

/* ===================== 页面：信箱 ===================== */

class InboxPage extends StatefulWidget {
  final LocalStore store;
  const InboxPage({super.key, required this.store});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final expired = await widget.store.autoExpireIfNeeded();
      if (expired && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("72 小时超时：邮票已自动退回。")));
        setState(() {});
      }
    });
  }

  String remainText(PendingRequest p) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final due = p.createdAtMs + const Duration(hours: 72).inMilliseconds;
    final ms = (due - now).clamp(0, 1 << 62);
    final d = Duration(milliseconds: ms);
    return "${d.inHours}小时${d.inMinutes % 60}分";
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.store.pending;
    final bal = widget.store.stampBalance;
    final locked = widget.store.stampLocked;

    return Column(
      children: [
        FateHeader(
          title: "信箱",
          subtitle: "你不需要暴露任何联系方式。\n${Copy.micro}",
          trailing: IconButton(
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => RulesSheet(store: widget.store),
              );
              setState(() {});
            },
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 10, bottom: 24),
            children: [
              FateCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("邮票", style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text("可用：$bal   锁定：$locked", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text("锁定=等待对方确认的一封。拒绝/超时/撤回都会退回。", style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      const Icon(Icons.local_post_office_rounded, size: 34),
                    ],
                  ),
                ),
              ),
              if (pending == null)
                FateCard(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("暂无进行中的投递", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Text("当你成功高兴、失落无助、或只是想被理解——\n写一封信给“另一个你”。",
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                )
              else
                FateCard(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("已进入同命等待池", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Text("状态：等待对方“接受/拒绝”\n剩余：${remainText(pending)}（超时自动退回邮票）",
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFF0B1020),
                            border: Border.all(color: const Color(0xFF2A3350)),
                          ),
                          child: Text("【${pending.mood}】\n${pending.content}", style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final lk = widget.store.stampLocked;
                                  if (lk > 0) {
                                    await widget.store.setStampBalance(widget.store.stampBalance + lk);
                                    await widget.store.setStampLocked(0);
                                  }
                                  await widget.store.setPending(null);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已撤回：邮票已退回待用。")));
                                  setState(() {});
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text("撤回（退回邮票）"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: () async {
                                  await showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => RulesSheet(store: widget.store),
                                  );
                                },
                                style: FilledButton.tonalFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text("规则/隐私"),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
            ],
          ),
        )
      ],
    );
  }
}

/* ===================== 页面：邮票（套餐 6/15/30） ===================== */

class StampStorePage extends StatefulWidget {
  final LocalStore store;
  const StampStorePage({super.key, required this.store});

  @override
  State<StampStorePage> createState() => _StampStorePageState();
}

class _StampStorePageState extends State<StampStorePage> {
  int selected = 0; // 0=未选择；1/3/10

  int priceOf(int count) {
    if (count == 1) return 6;
    if (count == 3) return 15;
    if (count == 10) return 30;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final bal = widget.store.stampBalance;
    final locked = widget.store.stampLocked;
    final price = priceOf(selected);

    return Column(
      children: [
        FateHeader(
          title: "邮票",
          subtitle: "邮票=一次投递机会。\n${Copy.micro}",
          trailing: IconButton(
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => RulesSheet(store: widget.store),
              );
              setState(() {});
            },
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 10, bottom: 24),
            children: [
              FateCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("当前余额", style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text("可用：$bal   锁定：$locked", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text("锁定=已投递等待确认。拒绝/超时/撤回都会退回。", style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      const Icon(Icons.confirmation_number_rounded, size: 34),
                    ],
                  ),
                ),
              ),

              FateCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("选择套餐", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      PackageTile(
                        title: "一封",
                        subtitle: "给“另一个我”的一次投递",
                        count: 1,
                        price: 6,
                        selected: selected == 1,
                        onTap: () => setState(() => selected = (selected == 1 ? 0 : 1)),
                      ),
                      const SizedBox(height: 10),
                      PackageTile(
                        title: "三封",
                        subtitle: "更适合：连续三次写下不同阶段的你",
                        count: 3,
                        price: 15,
                        selected: selected == 3,
                        onTap: () => setState(() => selected = (selected == 3 ? 0 : 3)),
                      ),
                      const SizedBox(height: 10),
                      PackageTile(
                        title: "十封",
                        subtitle: "长期陪伴：把人生写成一条暗线",
                        count: 10,
                        price: 30,
                        selected: selected == 10,
                        onTap: () => setState(() => selected = (selected == 10 ? 0 : 10)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: selected == 0 ? null : () => setState(() => selected = 0),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text("取消选择"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: selected == 0
                                  ? null
                                  : () async {
                                      // 这里是“演示加余额”。接支付后：把这段放到支付成功回调里。
                                      await widget.store.setStampBalance(widget.store.stampBalance + selected);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("已购买：$selected 封（$price 元，演示）。")));
                                      setState(() => selected = 0);
                                    },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(selected == 0 ? "确认购买" : "确认购买（$price 元）"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text("说明：本版本未接支付，按钮为演示。接支付后体验不变。", style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),

              FateCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Copy.flowTitle, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      ...Copy.flow.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("•  ", style: TextStyle(fontWeight: FontWeight.w900)),
                                Expanded(child: Text(s, style: Theme.of(context).textTheme.bodyMedium)),
                              ],
                            ),
                          )),
                      const SizedBox(height: 10),
                      Text(Copy.privacy, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

class PackageTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final int price;
  final bool selected;
  final VoidCallback onTap;

  const PackageTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = selected ? const Color(0xFF7C6CFF) : const Color(0xFF2A3350);
    final bg = selected ? const Color(0xFF141A36) : const Color(0xFF0B1020);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: bg,
          border: Border.all(color: border, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: selected
                      ? [const Color(0xFF7C6CFF).withOpacity(0.35), const Color(0xFF0B1020)]
                      : [const Color(0xFF1A2340), const Color(0xFF0B1020)],
                ),
              ),
              child: Center(
                child: Text("$count",
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$title · $price 元",
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? const Color(0xFF7C6CFF) : Colors.white54),
          ],
        ),
      ),
    );
  }
}

/* ===================== 规则弹层/引导 ===================== */

class OnboardingSheet extends StatelessWidget {
  final LocalStore store;
  const OnboardingSheet({super.key, required this.store});

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("欢迎来到《另一个我》", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text("${Copy.hookA}\n${Copy.hookB}\n${Copy.hookC}", style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFF0B1020),
                border: Border.all(color: const Color(0xFF2A3350)),
              ),
              child: Text(Copy.whyLetter, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 12),
            Text("一句话懂规则", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(Copy.micro, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await store.markSeen();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("我明白了"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class RulesSheet extends StatelessWidget {
  final LocalStore store;
  const RulesSheet({super.key, required this.store});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("规则与隐私", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text("${Copy.hookA}\n${Copy.hookB}\n${Copy.hookC}", style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text("写信比微信更有分量", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(Copy.whyLetter, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text(Copy.flowTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...Copy.flow.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("•  ", style: TextStyle(fontWeight: FontWeight.w900)),
                        Expanded(child: Text(s, style: Theme.of(context).textTheme.bodyMedium)),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              Text("隐私", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(Copy.privacy, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.tonalFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("关闭"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

/* ===================== 出生坐标页 ===================== */

class ProfilePage extends StatefulWidget {
  final LocalStore store;
  const ProfilePage({super.key, required this.store});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late BirthProfile p;
  static const branches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"];

  @override
  void initState() {
    super.initState();
    p = widget.store.profile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("命运坐标")),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          FateCard(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("同年同月同日", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFF0B1020),
                            border: Border.all(color: const Color(0xFF2A3350)),
                          ),
                          child: Text(p.ymd, style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.tonal(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: DateTime(1950, 1, 1),
                            lastDate: DateTime(now.year + 1, 12, 31),
                          );
                          if (picked == null) return;
                          final y = picked.year.toString().padLeft(4, "0");
                          final m = picked.month.toString().padLeft(2, "0");
                          final d = picked.day.toString().padLeft(2, "0");
                          setState(() => p = BirthProfile(ymd: "$y-$m-$d", hourBranch: p.hourBranch));
                        },
                        child: const Text("选日期"),
                      )
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text("时辰", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: branches.contains(p.hourBranch) ? p.hourBranch : "子",
                    items: branches.map((b) => DropdownMenuItem(value: b, child: Text("$b时"))).toList(),
                    onChanged: (v) => setState(() => p = BirthProfile(ymd: p.ymd, hourBranch: v ?? "子")),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0B1020),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      await widget.store.setProfile(p);
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("保存"),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
