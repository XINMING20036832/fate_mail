import 'package:flutter/material.dart';

void showRulesSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RulesSheet(),
  );
}

class _RulesSheet extends StatelessWidget {
  const _RulesSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (ctx, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  const Text('另一个我 · 规则与氛围', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              _para('你来这里，不是为了“认识陌生人”。而是为了找到那个在同一刻来到世上的 —— 另一个你。'),
              _title('为什么值得相信？'),
              _para('同年同月同日同一时辰出生的人，常常会在性格底色、情绪起伏、人生节点上出现惊人的相似。你不需要证明给谁看：你只需要试一次，就能知道那种“被懂”的感觉。'),
              _title('它怎么沟通？'),
              _bullets([
                '你先绑定出生日期与时辰（24小时内允许改一次，之后锁定）。',
                '写一封信，消耗 1 张邮票（邮票=寄信权）。',
                '对方可以选择接受或拒绝：拒绝/超时 → 邮票自动退回（MVP里用按钮演示）。',
                '我们只做“临时信箱”：双方默认不显示真实邮箱；只有当对方明确同意，才会开放进一步联系。',
              ]),
              _title('为什么比微信更“有感觉”？'),
              _para('微信太快，快到情绪还没成形就被打断；这里的信，是你把一段人生放进信封里。等待本身，就是一种支撑：在你脆弱或高光的时刻，你知道远处有个“同一刻出生的人”会认真读完。'),
              _title('禁忌（为了让这段关系更干净）'),
              _bullets([
                '信里不要放微信/QQ/手机号/链接/邮箱等外部联系方式。',
                '不要撒网式群发：同一时间只允许等待 1 个决定。',
                '尊重对方的边界：拒绝就是拒绝。',
              ]),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('我明白了'),
              ),
              const SizedBox(height: 8),
              Text(
                '提示：当前为 MVP 演示版（本地模拟）。上线前会补齐隐私政策/用户协议、后端超时退回、举报与封禁。',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.65)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _title(String s) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(s, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      );

  Widget _para(String s) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(s, style: const TextStyle(height: 1.55, fontSize: 14)),
      );

  Widget _bullets(List<String> xs) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          children: xs
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  ', style: TextStyle(height: 1.55, fontSize: 14)),
                      Expanded(child: Text(e, style: const TextStyle(height: 1.55, fontSize: 14))),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      );
}
