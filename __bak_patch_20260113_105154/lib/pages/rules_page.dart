import 'package:flutter/material.dart';
import '../widgets/fate_background.dart';
import '../widgets/fate_card.dart';

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('规则与隐私')),
      body: FateBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            FateCard(child: _HeroCopy()),
            SizedBox(height: 12),
            FateCard(child: _HowItWorks()),
            SizedBox(height: 12),
            FateCard(child: _Privacy()),
            SizedBox(height: 12),
            FateCard(child: _Stamps()),
            SizedBox(height: 22),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '提示：这是MVP版本。你现在看到的“收信/等待/回信”演示在本机模拟，后续接入服务器后会真正点对点。',
                style: TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('你在找的，可能不是陌生人。', style: t.headlineSmall),
        const SizedBox(height: 10),
        const Text(
          '同年同月同日、同一时辰出生的人，往往会在一些拐点里重复相似的情绪、选择与困局。\n'
          '你写下的这封信，会被送到“另一个你”。\n\n'
          '它比微信更浪漫：因为要等待；\n'
          '也更安全：因为彼此在同意之前都不会暴露邮箱。',
        ),
      ],
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('沟通过程', style: t.titleMedium),
        const SizedBox(height: 10),
        const _StepRow(n: '1', title: '绑定时间坐标', desc: '只绑定出生日期 + 时辰，用来匹配“同命的人”。'),
        const SizedBox(height: 8),
        const _StepRow(n: '2', title: '写一封信，发出请求卡', desc: '你先付邮票。对方看到的是“请求卡”，可接受或拒绝。'),
        const SizedBox(height: 8),
        const _StepRow(n: '3', title: '对方接受后进入信箱', desc: '双方只在“另一个我”里通信，不允许留外联信息（微信/电话/链接）。'),
        const SizedBox(height: 8),
        const _StepRow(n: '4', title: '当双方都愿意时再继续', desc: '未来版本可在双方都同意后，逐步开放更深的沟通方式。'),
      ],
    );
  }
}

class _Privacy extends StatelessWidget {
  const _Privacy();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('隐私与安全', style: t.titleMedium),
        const SizedBox(height: 10),
        const Text('• 我们不要求你公开邮箱，也不会把邮箱展示给对方。'),
        const SizedBox(height: 6),
        const Text('• 信箱内默认禁止外联信息（手机号/微信/链接/邮箱），避免被骚扰或被引流。'),
        const SizedBox(height: 6),
        const Text('• 我们的角色更像“临时中转站”：只负责把信送达，并尽量减少你在现实世界暴露的成本。'),
      ],
    );
  }
}

class _Stamps extends StatelessWidget {
  const _Stamps();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('邮票规则（让“发信”更有分量）', style: t.titleMedium),
        const SizedBox(height: 10),
        const Text('• 发信会预扣 1 枚邮票（6元/封）：不是随手群发，而是认真选择。'),
        const SizedBox(height: 6),
        const Text('• 对方在 72 小时内接受：邮票扣除，信件进入你的信箱。'),
        const SizedBox(height: 6),
        const Text('• 对方拒绝 / 72 小时未处理 / 你撤回：邮票自动退回待用。'),
        const SizedBox(height: 10),
        const Text(
          '为什么要邮票？\n'
          '因为人会为“付出一点成本”的事情更认真。\n'
          '当你在某个夜里无助、或在某个清晨突然释然，你更需要的是一封能被等待的信。',
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final String n;
  final String title;
  final String desc;
  const _StepRow({required this.n, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            n,
            style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 13, height: 1.2)),
            ],
          ),
        )
      ],
    );
  }
}
