class Profile {
  /// 命运坐标：同年同月同日 + 同一时辰
  final String birthDate; // YYYY-MM-DD
  final String shichen; // one of shichenList

  /// 绑定时间（epoch ms）。用于“24小时内可改一次”的限制。
  final int boundAtMs;

  /// 命运坐标在绑定后的修改次数（不含第一次绑定）。
  final int coordEditCount;

  /// 兼容旧字段：用于快速判断“坐标是否已锁定”。
  final bool locked;

  /// 邮箱（选填），默认隐藏，只有双方都愿意才会互相看到。
  final String email;

  /// 第一次设置邮箱的时间（epoch ms，0 表示从未设置过）。
  final int emailSetAtMs;

  /// 邮箱修改次数（不含第一次设置）。
  final int emailEditCount;

  Profile({
    required this.birthDate,
    required this.shichen,
    required this.boundAtMs,
    required this.coordEditCount,
    required this.locked,
    required this.email,
    required this.emailSetAtMs,
    required this.emailEditCount,
  });

  Profile copyWith({
    String? birthDate,
    String? shichen,
    int? boundAtMs,
    int? coordEditCount,
    bool? locked,
    String? email,
    int? emailSetAtMs,
    int? emailEditCount,
  }) {
    return Profile(
      birthDate: birthDate ?? this.birthDate,
      shichen: shichen ?? this.shichen,
      boundAtMs: boundAtMs ?? this.boundAtMs,
      coordEditCount: coordEditCount ?? this.coordEditCount,
      locked: locked ?? this.locked,
      email: email ?? this.email,
      emailSetAtMs: emailSetAtMs ?? this.emailSetAtMs,
      emailEditCount: emailEditCount ?? this.emailEditCount,
    );
  }

  bool canEditCoord({int? nowMs}) {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    if (boundAtMs <= 0) return true; // 兼容旧数据：允许进入“我的命运坐标”页面，但 UI 会提示谨慎
    final within24h = (now - boundAtMs) <= 24 * 60 * 60 * 1000;
    return within24h && coordEditCount < 1;
  }

  bool canEditEmail({int? nowMs}) {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    if (emailSetAtMs == 0) return true; // 从未设置过，允许首次设置
    final within24h = (now - emailSetAtMs) <= 24 * 60 * 60 * 1000;
    return within24h && emailEditCount < 1;
  }

  Map<String, dynamic> toJson() => {
        'birthDate': birthDate,
        'shichen': shichen,
        'boundAtMs': boundAtMs,
        'coordEditCount': coordEditCount,
        'locked': locked,
        'email': email,
        'emailSetAtMs': emailSetAtMs,
        'emailEditCount': emailEditCount,
      };

  static Profile? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final birth = (json['birthDate'] ?? '').toString();
    final shichen = (json['shichen'] ?? '').toString();

    final boundAtMs = (json['boundAtMs'] ?? 0) as int;
    final coordEditCount = (json['coordEditCount'] ?? 0) as int;

    // 旧版只有 locked：尽量保留不破坏老用户体验
    final locked = (json['locked'] ?? false) == true;

    final email = (json['email'] ?? '').toString();
    final emailSetAtMs = (json['emailSetAtMs'] ?? 0) as int;
    final emailEditCount = (json['emailEditCount'] ?? 0) as int;

    return Profile(
      birthDate: birth,
      shichen: shichen,
      boundAtMs: boundAtMs,
      coordEditCount: coordEditCount,
      locked: locked,
      email: email,
      emailSetAtMs: emailSetAtMs,
      emailEditCount: emailEditCount,
    );
  }
}

class StampWallet {
  final int stamps;
  StampWallet(this.stamps);

  Map<String, dynamic> toJson() => {'stamps': stamps};
  static StampWallet fromJson(Map<String, dynamic> json) =>
      StampWallet((json['stamps'] ?? 0) as int);
}

class MailRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fateKey; // birthDate + shichen
  final String status; // pending/accepted/rejected/expired
  final int createdAt; // epoch ms

  final String templateState;
  final String templatePace;
  final String extraLine;

  MailRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fateKey,
    required this.status,
    required this.createdAt,
    required this.templateState,
    required this.templatePace,
    required this.extraLine,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fateKey': fateKey,
        'status': status,
        'createdAt': createdAt,
        'templateState': templateState,
        'templatePace': templatePace,
        'extraLine': extraLine,
      };

  static MailRequest fromJson(Map<String, dynamic> json) => MailRequest(
        id: (json['id'] ?? '').toString(),
        fromUserId: (json['fromUserId'] ?? '').toString(),
        toUserId: (json['toUserId'] ?? '').toString(),
        fateKey: (json['fateKey'] ?? '').toString(),
        status: (json['status'] ?? 'pending').toString(),
        createdAt: (json['createdAt'] ?? 0) as int,
        templateState: (json['templateState'] ?? '').toString(),
        templatePace: (json['templatePace'] ?? '').toString(),
        extraLine: (json['extraLine'] ?? '').toString(),
      );
}

class MailItem {
  final String id;
  final String requestId;
  final String fromUserId;
  final String toUserId;
  final String body;
  final int createdAt; // epoch ms

  MailItem({
    required this.id,
    required this.requestId,
    required this.fromUserId,
    required this.toUserId,
    required this.body,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestId': requestId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'body': body,
        'createdAt': createdAt,
      };

  static MailItem fromJson(Map<String, dynamic> json) => MailItem(
        id: (json['id'] ?? '').toString(),
        requestId: (json['requestId'] ?? '').toString(),
        fromUserId: (json['fromUserId'] ?? '').toString(),
        toUserId: (json['toUserId'] ?? '').toString(),
        body: (json['body'] ?? '').toString(),
        createdAt: (json['createdAt'] ?? 0) as int,
      );
}
