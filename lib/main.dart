import "dart:convert";
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
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C63FF),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.1),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(fontSize: 14, height: 1.35),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false, // ③ 取消右上角 DEBUG 斜条（debug 也不显示）
      title: "另一个我",
      theme: theme,
      home: MainShell(store: store),
    );
  }
}

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
      final seen = widget.store.hasSeenOnboarding;
      if (!seen && mounted) {
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
      ComposePage(store: widget.store),
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

/* ===================== 数据与存储 ===================== */

class BirthProfile {
  final String ymd; // YYYY-MM-DD
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

  int get stampBalance => sp.getInt(_kStamp) ?? 1; // 给用户 1 张试用邮票，更容易“冲动一试”
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

  // 72小时超时：邮票自动退回待用
  Future<bool> autoExpireIfNeeded() async {
    final p = pending;
    if (p == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final due = p.createdAtMs + const Duration(hours: 72).inMilliseconds;
    if (now >= due) {
      // 退回锁定邮票
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

/* ===================== 组件：通用卡片/按钮 ===================== */

class GlassHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  const GlassHeader({super.key, required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 46, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFFB8B3FF)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Colors.white)),
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white.withOpacity(0.92))),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
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

/* ===================== 规则文案（你要的“迅速上头”版） ===================== */

class RuleCopy {
  static const hook1 = "同年同月同日同一刻出生的人，像被投进同一条时间河。";
  static const hook2 = "你走的是你的路，但很多拐点，会出现惊人的重合。";
  static const hook3 = "所以你写下的，也许正是“另一个我”正在经历的。";

  static const letterVsWechat = "微信太快，情绪常常来不及被认真对待。信件慢一点，却更像陪伴：\n"
      "你把话放进时间里，等它在远处回响。很多人曾把“等一封信”当作精神支撑——"
      "不是因为慢，而是因为那份郑重。";

  static const flowTitle = "你会经历的沟通过程";
  static const flowBullets = [
    "每封信 = 1 张邮票（一次结缘尝试）。",
    "你投递后先进入同命等待池：对方看到的是“接受/拒绝”，不是你的内容。",
    "对方点“接受”，首封才真正送达，并建立 1 对 1 匿名信箱。",
    "对方拒绝或 72 小时未处理：邮票自动退回余额，继续待用。",
    "你随时可以撤回：邮票立刻退回。",
    "联系方式默认隐藏；只有双方都点“同意交换”才会显示（后续版本上线）。",
    "我们只做站内投递与临时信箱：不把你的邮箱/手机号展示给任何人。",
  ];

  static const microRule = "提示：对方先同意，信才会到达；未同意，邮票原路退回。";
}

/* ===================== 4 个主页面 ===================== */

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
    final p = widget.store.profile;
    final bal = widget.store.stampBalance;
    final locked = widget.store.stampLocked;

    return Column(
      children: [
        GlassHeader(
          title: "另一个我",
          subtitle: "写一封信，投递给同一刻出生的那个人。\n${RuleCopy.microRule}",
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
              Card(
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
                          color: const Color(0xFFF3F4FF),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place_rounded),
                            const SizedBox(width: 10),
                            Expanded(child: Text("${p.ymd} · ${p.hourBranch}时", style: const TextStyle(fontWeight: FontWeight.w800))),
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
                      Text(RuleCopy.hook1, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(RuleCopy.hook2, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(RuleCopy.hook3, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("邮票余额", style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text("可用：$bal   锁定：$locked",
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text("锁定=正在等待对方确认的那一封。\n拒绝/超时/撤回都会退回。",
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      const Icon(Icons.local_post_office_rounded, size: 34),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
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
                  label: const Text("购买邮票 / 增加次数"),
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

class ComposePage extends StatefulWidget {
  final LocalStore store;
  const ComposePage({super.key, required this.store});

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
        GlassHeader(
          title: "写给另一个我",
          subtitle: "不是聊天，是一封郑重的信。\n${RuleCopy.microRule}",
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
              if (pending != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("你已经有一封正在等待确认的信", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Text("同一时刻只允许 1 封进行中，避免撒网，也更像命运的“一对一”。",
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () async {
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => InboxPage(store: widget.store)));
                            setState(() {});
                          },
                          child: const Text("去信箱查看状态"),
                        )
                      ],
                    ),
                  ),
                ),
              Card(
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
                      Text("写下你想对“另一个我”说的话", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      TextField(
                        controller: ctrl,
                        minLines: 6,
                        maxLines: 10,
                        decoration: InputDecoration(
                          hintText: "写具体一点：你在经历什么？你最想被理解的一句话是什么？",
                          filled: true,
                          fillColor: const Color(0xFFF3F4FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(RuleCopy.microRule, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              text: pending == null ? "投递到同命等待池（锁定 1 张邮票）" : "已有进行中的信",
                              onPressed: () async {
                                if (pending != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("你已有一封进行中的信。")));
                                  return;
                                }
                                final txt = ctrl.text.trim();
                                if (txt.length < 10) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("写 10 个字以上，更容易同频。")));
                                  return;
                                }
                                if (bal <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("邮票不足，先去购买/增加次数。")));
                                  return;
                                }
                                await widget.store.setStampBalance(bal - 1);
                                await widget.store.setStampLocked(1);
                                await widget.store.setPending(PendingRequest(
                                  createdAtMs: DateTime.now().millisecondsSinceEpoch,
                                  mood: mood,
                                  content: txt,
                                ));
                                ctrl.clear();
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已投递：对方先同意，信才会到达。拒绝/超时邮票自动退回。")));
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("为什么写信比微信更有感觉", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Text(RuleCopy.letterVsWechat, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("72 小时超时未被处理：邮票已自动退回。")));
        setState(() {});
      }
    });
  }

  String _remainText(PendingRequest p) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final due = p.createdAtMs + const Duration(hours: 72).inMilliseconds;
    final ms = (due - now).clamp(0, 1 << 62);
    final d = Duration(milliseconds: ms);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return "${h}小时${m}分";
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.store.pending;
    final bal = widget.store.stampBalance;
    final locked = widget.store.stampLocked;

    return Column(
      children: [
        GlassHeader(
          title: "信箱",
          subtitle: "你不需要暴露任何联系方式。\n对方先同意，信才会到达。",
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
              Card(
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
                            Text("锁定=已投递，等待对方确认。\n拒绝/超时/撤回都会退回。", style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      const Icon(Icons.local_post_office_rounded, size: 34),
                    ],
                  ),
                ),
              ),
              if (pending == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("暂无进行中的投递", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Text("想说的话，写成一封信。\n你越真实，越容易同频。", style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("去写一封"),
                        )
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("已进入同命等待池", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Text("状态：等待对方“接受/拒绝”\n剩余：${_remainText(pending)}（超时自动退回邮票）",
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFFF3F4FF),
                          ),
                          child: Text("【${pending.mood}】\n${pending.content}", style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  // 撤回：立刻退回锁定邮票
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
                              child: FilledButton(
                                onPressed: () async {
                                  await showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => RulesSheet(store: widget.store),
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text("查看规则"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("回信为什么值得等", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Text("你等的不是消息，而是“另一个我”的回应。\n"
                          "它可能来自成功的喜悦，也可能来自失落的无助。\n"
                          "你们人生的相似处，会让一句话变得更有重量。",
                          style: Theme.of(context).textTheme.bodyMedium),
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

/* ===================== 5) 邮票购买：可加可减可清空 ===================== */

class StampStorePage extends StatefulWidget {
  final LocalStore store;
  const StampStorePage({super.key, required this.store});

  @override
  State<StampStorePage> createState() => _StampStorePageState();
}

class _StampStorePageState extends State<StampStorePage> {
  int qty = 1;

  @override
  Widget build(BuildContext context) {
    final bal = widget.store.stampBalance;
    final locked = widget.store.stampLocked;

    return Column(
      children: [
        GlassHeader(
          title: "邮票",
          subtitle: "邮票=一次结缘投递。\n对方接受才真正消耗；拒绝/超时自动退回。",
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
              Card(
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
                            Text("锁定=正在等待对方确认的那封信。", style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      const Icon(Icons.confirmation_number_rounded, size: 34),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("选择购买数量", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      StampStepper(
                        value: qty,
                        min: 0,
                        max: 999,
                        onChanged: (v) => setState(() => qty = v),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _quick("一封", 1),
                          _quick("三封", 3),
                          _quick("十封", 10),
                          _quick("清空", 0),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: qty <= 0
                            ? null
                            : () async {
                                // 这里先做“演示充值”：直接加到余额
                                // 支付接入时，把这段替换为支付成功回调后再加
                                await widget.store.setStampBalance(widget.store.stampBalance + qty);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("已增加 $qty 张邮票（演示）。")));
                                setState(() {});
                              },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("确认购买（演示）"),
                      ),
                      const SizedBox(height: 10),
                      Text("正式版接入支付后：仍然按同一规则——对方接受才真正消耗；拒绝/超时退回待用。",
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(RuleCopy.flowTitle, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      ...RuleCopy.flowBullets.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("•  ", style: TextStyle(fontWeight: FontWeight.w900)),
                                Expanded(child: Text(s, style: Theme.of(context).textTheme.bodyMedium)),
                              ],
                            ),
                          )),
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

  Widget _quick(String text, int v) {
    return ActionChip(
      label: Text(text),
      onPressed: () => setState(() => qty = v),
    );
  }
}

class StampStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const StampStepper({super.key, required this.value, required this.onChanged, this.min = 0, this.max = 999});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Colors.white,
          ),
          child: Text("$value", style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: value > 0 ? () => onChanged(0) : null,
          child: const Text("清空"),
        )
      ],
    );
  }
}

/* ===================== 6) 规则页：美观 + 说清楚流程 ===================== */

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
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("欢迎来到《另一个我》", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(RuleCopy.hook1, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(RuleCopy.hook2, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(RuleCopy.hook3, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFFF3F4FF),
              ),
              child: Text(RuleCopy.letterVsWechat, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 12),
            Text("一眼懂规则", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...RuleCopy.flowBullets.take(5).map((s) => Padding(
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
                    child: const Text("我明白了，去写一封"),
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
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("规则与隐私", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text("这不是群聊，不是匹配列表，更不是社交表演。\n这里是“写信给另一个我”。",
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text("我们为什么相信", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text("${RuleCopy.hook1}\n${RuleCopy.hook2}\n${RuleCopy.hook3}",
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text("为什么写信更浪漫、更安全", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(RuleCopy.letterVsWechat, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text(RuleCopy.flowTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...RuleCopy.flowBullets.map((s) => Padding(
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

/* ===================== 个人资料页：出生坐标（同年同月同日 + 时辰） ===================== */

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
          Card(
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
                            color: const Color(0xFFF3F4FF),
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
                        child: const Text("选择日期"),
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
                      fillColor: const Color(0xFFF3F4FF),
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
