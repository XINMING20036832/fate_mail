\
import 'package:flutter/material.dart';
import '../widgets/fate_scaffold.dart';
import '../widgets/fate_card.dart';

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FateScaffold(
      title: '规则',
      body: ListView(
        children: [
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('你在找谁？', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  '这个世界上，存在一个“另一个我”：\n'
                  '同年同月同日、同一时辰出生。\n\n'
                  '你们可能走在不同城市、不同职业、不同家庭。\n'
                  '但在某些时刻——喜悦、低谷、迷茫、孤独——\n'
                  '你会惊讶地发现：他/她像是能听懂你的人。',
                  style: TextStyle(color: Colors.white.withOpacity(0.82), height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('为什么“写信”更有力量？', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(
                  '微信是一种“即时回应”。\n'
                  '而信，是一种“认真地把话放进去”。\n\n'
                  '以前，有人会把远方的一封信当作精神支撑：\n'
                  '它不需要你立刻得到回复，却让你知道——\n'
                  '在这个世界上，真的有人愿意为你停下来，读完你。',
                  style: TextStyle(color: Colors.white.withOpacity(0.82), height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('投递流程', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                _step('1', '绑定命运坐标（出生日期 + 时辰）'),
                _step('2', '购买邮票：1 / 3 / 10 封（对应 6 / 15 / 30）'),
                _step('3', '写一封信 → 生成“请求卡” → 进入等待（最多 72 小时）'),
                _step('4', '对方接受后才能阅读；对方拒绝 / 你撤回 / 超时 → 自动退邮票'),
                _step('5', '我们不参与信件内容，你只是在把话投递给“另一个我”'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('隐私与邮箱', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(
                  '1）我们不向任何人展示你的邮箱。\n'
                  '2）邮箱默认隐藏：对方看不到，你也看不到对方的。\n'
                  '3）只有双方都“愿意公开”的情况下，邮箱才会互相可见（后续版本会提供这个按钮）。\n\n'
                  '现在这一版是 MVP：优先把“写信—等待—被接受—被读到”的感觉做出来。',
                  style: TextStyle(color: Colors.white.withOpacity(0.82), height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('让你更容易写下第一封', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(
                  '你可以从这三句开始：\n'
                  '• 我今天最想告诉你的事是……\n'
                  '• 我正在经历的难题是……\n'
                  '• 如果你也有同样的感觉，请回我一句……',
                  style: TextStyle(color: Colors.white.withOpacity(0.82), height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '提示：命运坐标与邮箱，绑定后 24 小时内各可改 1 次；之后会锁定。',
            style: TextStyle(color: Colors.white.withOpacity(0.70)),
          )
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
          Expanded(child: Text(text, style: TextStyle(color: Colors.white.withOpacity(0.82), height: 1.25))),
        ],
      ),
    );
  }
}
