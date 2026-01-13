class Profile {
  final String birthDate; // YYYY-MM-DD
  final String shichen;   // one of shichenList
  final String email;     // private, not shown to other users
  final int createdAt;    // epoch ms
  final int emailUpdatedAt; // epoch ms
  final bool locked;        // lock birth/shichen after initial window

  Profile({
    required this.birthDate,
    required this.shichen,
    required this.email,
    required this.createdAt,
    required this.emailUpdatedAt,
    required this.locked,
  });

  Map<String, dynamic> toJson() => {
    'birthDate': birthDate,
    'shichen': shichen,
    'email': email,
    'createdAt': createdAt,
    'emailUpdatedAt': emailUpdatedAt,
    'locked': locked,
  };

  static Profile? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    return Profile(
      birthDate: (json['birthDate'] ?? '').toString(),
      shichen: (json['shichen'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? now) is int ? (json['createdAt'] ?? now) as int : now,
      emailUpdatedAt: (json['emailUpdatedAt'] ?? now) is int ? (json['emailUpdatedAt'] ?? now) as int : now,
      locked: (json['locked'] ?? false) as bool,
    );
  }

  String get fateKey => '$birthDate|$shichen';
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
    createdAt: (json['createdAt'] ?? 0) is int ? (json['createdAt'] ?? 0) as int : 0,
    templateState: (json['templateState'] ?? '').toString(),
    templatePace: (json['templatePace'] ?? '').toString(),
    extraLine: (json['extraLine'] ?? '').toString(),
  );
}

class MailItem {
  final String id;
  final String peerFateKey;
  final String state;
  final String pace;
  final String text;
  final int createdAt; // epoch ms

  MailItem({
    required this.id,
    required this.peerFateKey,
    required this.state,
    required this.pace,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'peerFateKey': peerFateKey,
    'state': state,
    'pace': pace,
    'text': text,
    'createdAt': createdAt,
  };

  static MailItem fromJson(Map<String, dynamic> json) => MailItem(
    id: (json['id'] ?? '').toString(),
    peerFateKey: (json['peerFateKey'] ?? '').toString(),
    state: (json['state'] ?? '').toString(),
    pace: (json['pace'] ?? '').toString(),
    text: (json['text'] ?? '').toString(),
    createdAt: (json['createdAt'] ?? 0) is int ? (json['createdAt'] ?? 0) as int : 0,
  );
}
