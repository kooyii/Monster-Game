class Child {
  final int id;
  final String name;
  final String avatarEmoji;
  final int points;

  Child({required this.id, required this.name, required this.avatarEmoji, required this.points});

  factory Child.fromJson(Map<String, dynamic> j) => Child(
        id: j['id'],
        name: j['name'],
        avatarEmoji: j['avatar_emoji'] ?? '😊',
        points: j['points'] ?? 0,
      );
}

class Reward {
  final int id;
  final String name;
  final String? description;
  final int pointsCost;
  final String emoji;
  final bool isActive;

  Reward({required this.id, required this.name, this.description, required this.pointsCost, required this.emoji, this.isActive = true});

  factory Reward.fromJson(Map<String, dynamic> j) => Reward(
        id: j['id'],
        name: j['name'],
        description: j['description'],
        pointsCost: j['points_cost'],
        emoji: j['emoji'] ?? '🎁',
        isActive: (j['is_active'] ?? 1) == 1,
      );
}

class PointTransaction {
  final int id;
  final int points;
  final String description;
  final String type; // 'earn' | 'redeem'
  final String createdAt;
  final String? childName;
  final String? avatarEmoji;

  PointTransaction({required this.id, required this.points, required this.description, required this.type, required this.createdAt, this.childName, this.avatarEmoji});

  factory PointTransaction.fromJson(Map<String, dynamic> j) => PointTransaction(
        id: j['id'],
        points: j['points'],
        description: j['description'] ?? '',
        type: j['type'] ?? 'earn',
        createdAt: j['created_at'] ?? '',
        childName: j['child_name'],
        avatarEmoji: j['avatar_emoji'],
      );
}

class Punishment {
  final int id;
  final String emoji;
  final String title;
  final int pointsDelta; // 0 = task only, negative = deduct points

  Punishment({required this.id, required this.emoji, required this.title, required this.pointsDelta});
}

class RedemptionRecord {
  final int id;
  final String childName;
  final String rewardName;
  final String rewardEmoji;
  final int pointsCost;
  final String status;
  final String createdAt;

  RedemptionRecord({required this.id, required this.childName, required this.rewardName, required this.rewardEmoji, required this.pointsCost, required this.status, required this.createdAt});

  factory RedemptionRecord.fromJson(Map<String, dynamic> j) => RedemptionRecord(
        id: j['id'],
        childName: j['child_name'] ?? '',
        rewardName: j['reward_name'] ?? '',
        rewardEmoji: j['reward_emoji'] ?? '🎁',
        pointsCost: j['points_cost'] ?? 0,
        status: j['status'] ?? 'approved',
        createdAt: j['created_at'] ?? '',
      );
}
