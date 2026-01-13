import 'dart:math';

bool containsExternalContact(String s) {
  final lower = s.toLowerCase();
  // MVP：尽量阻止直接交换外部联系方式（微信/QQ/手机号/链接/邮箱等）
  final patterns = <RegExp>[
    RegExp(r'https?://'),
    RegExp(r'www\.'),
    RegExp(r'\b\d{7,}\b'), // long numbers
    RegExp(r'微信|vx|v信|wechat', caseSensitive: false),
    RegExp(r'qq\s*[:：]?\s*\d+', caseSensitive: false),
    RegExp(r'@'), // email symbol
  ];
  return patterns.any((p) => p.hasMatch(lower));
}

/// 一个稳定的、可复现实验用的“镜像用户ID”（不等于真实匹配逻辑）
/// 目的：本地演示时让“另一个我”看起来稳定存在。
String mirrorUserId(String birthDate, String shichen) {
  final seed = (birthDate + '|' + shichen).codeUnits.fold<int>(0, (a, b) => a * 31 + b) & 0x7fffffff;
  final r = Random(seed);
  const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  final buf = StringBuffer('M-');
  for (int i = 0; i < 10; i++) {
    buf.write(chars[r.nextInt(chars.length)]);
  }
  return buf.toString();
}

String shortId(String s, {int keep = 6}) {
  if (s.length <= keep) return s;
  return s.substring(0, keep);
}
