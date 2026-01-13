bool containsExternalContact(String s) {
  final lower = s.toLowerCase();
  // very simple blockers for MVP
  final patterns = <RegExp>[
    RegExp(r'https?://'),
    RegExp(r'www\.'),
    RegExp(r'\b\d{7,}\b'), // long numbers
    RegExp(r'微信|vx|v信|wechat', caseSensitive: false),
    RegExp(r'qq\s*[:：]?\s*\d+', caseSensitive: false),
    RegExp(r'@'), // email symbol (optional)
  ];
  return patterns.any((p) => p.hasMatch(lower));
}
