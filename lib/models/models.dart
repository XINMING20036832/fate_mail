class Profile {
  final String birthDate; // YYYY-MM-DD
  final String shichen;   // one of shichenList
  final String email;     // user email for receipt (hidden to others)
  final int createdAt;    // epoch ms
  final int profileEditsUsed; // within first 24h
  final int lastEmailChangeAt; // epoch ms

  Profile({
    required this.birthDate,
    required this.shichen,
    required this.email,
    required this.createdAt,
    required this.profileEditsUsed,
    required this.lastEmailChangeAt,
  });

  Map<String, dynamic> toJson() => {
    'birthDate': birthDate,
    'shichen': shichen,
    'email': email,
    'createdAt': createdAt,
    'profileEditsUsed': profileEditsUsed,
    'lastEmailChangeAt': lastEmailChangeAt,
  };

  static Profile? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return Profile(
      birthDate: (json['birthDate'] ?? '').toString(),
      shichen: (json['shichen'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? 0) as int,
      profileEditsUsed: (json['profileEditsUsed'] ?? 0) as int,
      lastEmailChangeAt: (json['lastEmailChangeAt'] ?? 0) as int,
    );
  }
}

class StampWallet {
  final int stamps;
  StampWallet(this.stamps);

  Map<String, dynamic> toJson() => {'stamps': stamps};
  static StampWallet fromJson(Map<String, dynamic>? json) => StampWallet((json?['stamps'] ?? 0) as int);
}

enum RequestStatus { pending, incoming, accepted, rejected, canceled }

class MailRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String mood;     // 我现在的状态
  final String pace;     // 我希望的互动节奏
  final String extraLine;
  final int createdAt;   // epoch ms
  final String note;     // short note shown to receiver
  final RequestStatus status;

  MailRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.mood,
    required this.pace,
    required this.extraLine,
    required this.createdAt,
    required this.note,
    required this.status,
  });

  MailRequest copyWith({RequestStatus? status}) => MailRequest(
    id: id,
    fromUserId: fromUserId,
    toUserId: toUserId,
    mood: mood,
    pace: pace,
    extraLine: extraLine,
    createdAt: createdAt,
    note: note,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromUserId': fromUserId,
    'toUserId': toUserId,
    'mood': mood,
    'pace': pace,
    'extraLine': extraLine,
    'createdAt': createdAt,
    'note': note,
    'status': status.name,
  };

  static MailRequest fromJson(Map<String, dynamic> json) => MailRequest(
    id: (json['id'] ?? '').toString(),
    fromUserId: (json['fromUserId'] ?? '').toString(),
    toUserId: (json['toUserId'] ?? '').toString(),
    mood: (json['mood'] ?? '').toString(),
    pace: (json['pace'] ?? '').toString(),
    extraLine: (json['extraLine'] ?? '').toString(),
    createdAt: (json['createdAt'] ?? 0) as int,
    note: (json['note'] ?? '').toString(),
    status: RequestStatus.values.firstWhere(
      (e) => e.name == (json['status'] ?? 'pending'),
      orElse: () => RequestStatus.pending,
    ),
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
