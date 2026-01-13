import 'package:flutter/material.dart';

class RulesSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.black.withOpacity(0.92),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 6),
                Text('另一个我｜规则与隐私', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 10),
                Text(
                  '我们相信：同年同月同日同一时辰出生的人，人生会在很多地方“重叠”。\n'
                  '你不是来聊天的。你是来把一段话寄给另一个自己。\n',
                  style: TextStyle(height: 1.4),
                ),
                SizedBox(height: 10),
                _Bullet('一对一：每次只等待一个人做决定。接受后才能读内容。'),
                _Bullet('不加微信、不留号码：信里禁止外部联系方式，避免“撒网”。'),
                _Bullet('邮票制：寄出用 1 枚邮票。对方拒绝/超时 → 邮票退回。'),
                _Bullet('我们不参与内容：不公开、不推荐、不广场；只做临时信箱。'),
                _Bullet('隐私：你的真实邮箱仅用于系统通知/找回，不会展示给对方；对方看到的是临时转寄地址（后端上线后生效）。'),
                SizedBox(height: 12),
                Text('为什么不直接微信？', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text(
                  '因为“等待”本身就是一种力量。\n'
                  '你曾经也许在某个艰难的日子里，靠一封信的到来撑过一段路。\n'
                  '这里把那种感觉留住：慢一点、更安全、更有分寸，也更浪漫。',
                  style: TextStyle(height: 1.45),
                ),
                SizedBox(height: 12),
                Text('提示', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text(
                  '本版本仍是本地演示（MVP）：匹配/转寄逻辑在后端上线后会完整启用。\n'
                  '你现在看到的流程与界面，会按最终上架的体验设计。',
                  style: TextStyle(height: 1.45, fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 16, height: 1.35)),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}
