class Profile {
  /// YYYY-MM-DD
  final String birthDate;

  /// One of shichenList
  final String shichen;

  /// When the fate coordinate was first bound (epoch ms).
  final int boundAt;

  /// How many edits are left for fate coordinate. Default: 1.
  /// Rule: within 24h after first bind, can edit at most once.
  final int fateEditsLeft;

  /// Optional notification mailbox (never shown to the peer unless both sides agree in the future).
  final String notifyEmail;

  /// Last time the notifyEmail was updated (epoch ms). 0 means never set.
  final int emailUpdatedAt;

  const Profile({
    required this.birthDate,
    required this.shichen,
    required this.boundAt,
    required this.fateEditsLeft,
    required this.notifyEmail,
    required this.emailUpdatedAt,
  });

  Profile copyWith({
    String? birthDate,
    String? shichen,
    int? boundAt,
    int? fateEditsLeft,
    String? notifyEmail,
    int? emailUpdatedAt,
  }) {
    return Profile(
      birthDate: birthDate ?? this.birthDate,
      shichen: shichen ?? this.shichen,
      boundAt: boundAt ?? this.boundAt,
      fateEditsLeft: fateEditsLeft ?? this.fateEditsLeft,
      notifyEmail: notifyEmail ?? this.notifyEmail,
      emailUpdatedAt: emailUpdatedAt ?? this.emailUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'birthDate': birthDate,
        'shichen': shichen,
        'boundAt': boundAt,
        'fateEditsLeft': fateEditsLeft,
        'notifyEmail': notifyEmail,
        'emailUpdatedAt': emailUpdatedAt,
      };

  static Profile? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final birthDate = (json['birthDate'] ?? '').toString();
    final shichen = (json['shichen'] ?? '').toString();

    // Backward compatible defaults
    final boundAt = (json['boundAt'] is int)
        ? (json['boundAt'] as int)
        : (json['boundAt'] is String)
            ? int.tryParse(json['boundAt'] as String) ?? 0
            : 0;

    final fateEditsLeft = (json['fateEditsLeft'] is int)
        ? (json['fateEditsLeft'] as int)
        : (json['fateEditsLeft'] is String)
            ? int.tryParse(json['fateEditsLeft'] as String) ?? 0
            : (json['locked'] == true ? 0 : 1); // old field: locked

    final notifyEmail = (json['notifyEmail'] ?? '').toString();

    final emailUpdatedAt = (json['emailUpdatedAt'] is int)
        ? (json['emailUpdatedAt'] as int)
        : (json['emailUpdatedAt'] is String)
            ? int.tryParse(json['emailUpdatedAt'] as String) ?? 0
            : 0;

    return Profile(
      birthDate: birthDate,
      shichen: shichen,
      boundAt: boundAt,
      fateEditsLeft: fateEditsLeft,
      notifyEmail: notifyEmail,
      emailUpdatedAt: emailUpdatedAt,
    );
  }
}

class StampWallet {
  final int stamps;
  const StampWallet(this.stamps);

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
  final String? userId;
  final String? direction;
  final String templateState;
  final String templatePace;
  final String extraLine;

  const MailRequest({
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

  MailRequest copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? fateKey,
    String? status,
    int? createdAt,
    String? templateState,
    String? templatePace,
    String? extraLine,
  }) {
    return MailRequest(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      fateKey: fateKey ?? this.fateKey,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      templateState: templateState ?? this.templateState,
      templatePace: templatePace ?? this.templatePace,
      extraLine: extraLine ?? this.extraLine,
    );
  }

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
  final String? userId;
  final String? direction;

  const MailItem({
    required this.id,
    required this.requestId,
    required this.fromUserId,
    required this.toUserId,
    required this.body,
    required this.createdAt,
    this.userId,
    this.direction,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestId': requestId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'body': body,
        'createdAt': createdAt,
        if (userId != null) 'userId': userId,
        if (direction != null) 'direction': direction,
      };

  static MailItem fromJson(Map<String, dynamic> json) => MailItem(
        id: (json['id'] ?? '').toString(),
        requestId: (json['requestId'] ?? '').toString(),
        fromUserId: (json['fromUserId'] ?? '').toString(),
        toUserId: (json['toUserId'] ?? '').toString(),
        body: (json['body'] ?? '').toString(),
        createdAt: (json['createdAt'] ?? 0) as int,
        userId: json['userId']?.toString(),
        direction: json['direction']?.toString(),
      );
}
