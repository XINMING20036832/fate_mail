class Profile {
  final String birthDate; // YYYY-MM-DD
  final String shichen;   // one of shichenList
  final bool locked;

  Profile({required this.birthDate, required this.shichen, required this.locked});

  Map<String, dynamic> toJson() => {
    'birthDate': birthDate,
    'shichen': shichen,
    'locked': locked,
  };

  static Profile? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return Profile(
      birthDate: (json['birthDate'] ?? '').toString(),
      shichen: (json['shichen'] ?? '').toString(),
      locked: (json['locked'] ?? false) == true,
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
  final String status;  // pending/accepted/rejected/expired
  final int createdAt;  // epoch ms
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
