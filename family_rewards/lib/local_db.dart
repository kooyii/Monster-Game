import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class LocalDb {
  static final LocalDb _instance = LocalDb._internal();
  factory LocalDb() => _instance;
  LocalDb._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'family_rewards.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE children (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            avatar_emoji TEXT DEFAULT '😊',
            points INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE rewards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            points_cost INTEGER NOT NULL,
            emoji TEXT DEFAULT '🎁',
            is_active INTEGER DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE point_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            child_id INTEGER NOT NULL,
            points INTEGER NOT NULL,
            description TEXT NOT NULL,
            type TEXT DEFAULT 'earn',
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE redemptions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            child_id INTEGER NOT NULL,
            reward_id INTEGER NOT NULL,
            points_cost INTEGER NOT NULL,
            status TEXT DEFAULT 'approved',
            created_at TEXT NOT NULL
          )
        ''');
        await _createPunishmentsTable(db);
        await _insertDefaultPunishments(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createPunishmentsTable(db);
          await _insertDefaultPunishments(db);
        }
      },
    );
  }

  static Future<void> _createPunishmentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS punishments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        emoji TEXT DEFAULT '😅',
        title TEXT NOT NULL,
        points_delta INTEGER DEFAULT 0
      )
    ''');
  }

  static Future<void> _insertDefaultPunishments(Database db) async {
    final defaults = [
      {'emoji': '😅', 'title': '扣1积分', 'points_delta': -1},
      {'emoji': '😬', 'title': '扣2积分', 'points_delta': -2},
      {'emoji': '🏃', 'title': '做20个深蹲', 'points_delta': 0},
      {'emoji': '🍽️', 'title': '帮忙洗碗一次', 'points_delta': 0},
      {'emoji': '📚', 'title': '额外读书20分钟', 'points_delta': 0},
      {'emoji': '🌙', 'title': '今晚早睡30分钟', 'points_delta': 0},
    ];
    for (final p in defaults) {
      await db.insert('punishments', p);
    }
  }

  // ── Punishments ───────────────────────────────────────────────────────────
  Future<List<Punishment>> getPunishments() async {
    final d = await db;
    final rows = await d.query('punishments', orderBy: 'id ASC');
    return rows.map((r) => Punishment(
      id: r['id'] as int,
      emoji: r['emoji'] as String? ?? '😅',
      title: r['title'] as String,
      pointsDelta: r['points_delta'] as int? ?? 0,
    )).toList();
  }

  Future<void> createPunishment(String emoji, String title, int pointsDelta) async {
    final d = await db;
    await d.insert('punishments', {'emoji': emoji, 'title': title, 'points_delta': pointsDelta});
  }

  Future<void> updatePunishment(int id, String emoji, String title, int pointsDelta) async {
    final d = await db;
    await d.update('punishments', {'emoji': emoji, 'title': title, 'points_delta': pointsDelta},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePunishment(int id) async {
    final d = await db;
    await d.delete('punishments', where: 'id = ?', whereArgs: [id]);
  }

  // ── Children ──────────────────────────────────────────────────────────────
  Future<List<Child>> getChildren() async {
    final d = await db;
    final rows = await d.query('children', orderBy: 'points DESC');
    return rows.map((r) => Child(
      id: r['id'] as int,
      name: r['name'] as String,
      avatarEmoji: r['avatar_emoji'] as String? ?? '😊',
      points: r['points'] as int? ?? 0,
    )).toList();
  }

  Future<Child?> getChild(int id) async {
    final d = await db;
    final rows = await d.query('children', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Child(
      id: r['id'] as int,
      name: r['name'] as String,
      avatarEmoji: r['avatar_emoji'] as String? ?? '😊',
      points: r['points'] as int? ?? 0,
    );
  }

  Future<void> createChild(String name, String avatarEmoji) async {
    final d = await db;
    await d.insert('children', {'name': name, 'avatar_emoji': avatarEmoji, 'points': 0});
  }

  Future<void> updateChild(int id, Map<String, dynamic> data) async {
    final d = await db;
    await d.update('children', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteChild(int id) async {
    final d = await db;
    await d.delete('point_transactions', where: 'child_id = ?', whereArgs: [id]);
    await d.delete('redemptions', where: 'child_id = ?', whereArgs: [id]);
    await d.delete('children', where: 'id = ?', whereArgs: [id]);
  }

  // ── Points ────────────────────────────────────────────────────────────────
  Future<int> awardPoints(int childId, int points, String description) async {
    final d = await db;
    final now = DateTime.now().toIso8601String();
    await d.insert('point_transactions', {
      'child_id': childId,
      'points': points,
      'description': description,
      'type': points > 0 ? 'earn' : 'redeem',
      'created_at': now,
    });
    await d.rawUpdate('UPDATE children SET points = points + ? WHERE id = ?', [points, childId]);
    final rows = await d.query('children', columns: ['points'], where: 'id = ?', whereArgs: [childId]);
    return rows.first['points'] as int;
  }

  Future<List<PointTransaction>> getTransactions({int? childId, int limit = 30}) async {
    final d = await db;
    final args = <dynamic>[];
    var sql = '''
      SELECT pt.*, c.name as child_name, c.avatar_emoji
      FROM point_transactions pt
      JOIN children c ON pt.child_id = c.id
    ''';
    if (childId != null) {
      sql += ' WHERE pt.child_id = ?';
      args.add(childId);
    }
    sql += ' ORDER BY pt.created_at DESC LIMIT ?';
    args.add(limit);
    final rows = await d.rawQuery(sql, args);
    return rows.map((r) => PointTransaction(
      id: r['id'] as int,
      points: r['points'] as int,
      description: r['description'] as String,
      type: r['type'] as String? ?? 'earn',
      createdAt: r['created_at'] as String,
      childName: r['child_name'] as String?,
      avatarEmoji: r['avatar_emoji'] as String?,
    )).toList();
  }

  // ── Rewards ───────────────────────────────────────────────────────────────
  Future<List<Reward>> getRewards({bool allRewards = true}) async {
    final d = await db;
    final rows = allRewards
        ? await d.query('rewards', orderBy: 'points_cost ASC')
        : await d.query('rewards', where: 'is_active = 1', orderBy: 'points_cost ASC');
    return rows.map((r) => Reward(
      id: r['id'] as int,
      name: r['name'] as String,
      description: r['description'] as String?,
      pointsCost: r['points_cost'] as int,
      emoji: r['emoji'] as String? ?? '🎁',
      isActive: (r['is_active'] as int? ?? 1) == 1,
    )).toList();
  }

  Future<void> createReward(String name, int pointsCost, String emoji, {String? description}) async {
    final d = await db;
    await d.insert('rewards', {
      'name': name, 'points_cost': pointsCost, 'emoji': emoji,
      'description': description, 'is_active': 1,
    });
  }

  Future<void> updateReward(int id, Map<String, dynamic> data) async {
    final d = await db;
    await d.update('rewards', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteReward(int id) async {
    final d = await db;
    await d.delete('rewards', where: 'id = ?', whereArgs: [id]);
  }

  // ── Redemptions ───────────────────────────────────────────────────────────
  Future<int> directRedeem(int childId, int rewardId) async {
    final d = await db;
    final rewardRows = await d.query('rewards', where: 'id = ?', whereArgs: [rewardId]);
    if (rewardRows.isEmpty) throw Exception('奖励不存在');
    final reward = rewardRows.first;
    final pointsCost = reward['points_cost'] as int;
    final rewardName = reward['name'] as String;

    final childRows = await d.query('children', where: 'id = ?', whereArgs: [childId]);
    if (childRows.isEmpty) throw Exception('孩子不存在');
    final currentPoints = childRows.first['points'] as int;
    if (currentPoints < pointsCost) throw Exception('积分不足');

    final now = DateTime.now().toIso8601String();
    await d.rawUpdate('UPDATE children SET points = points - ? WHERE id = ?', [pointsCost, childId]);
    await d.insert('point_transactions', {
      'child_id': childId, 'points': -pointsCost,
      'description': '兑换 $rewardName', 'type': 'redeem', 'created_at': now,
    });
    await d.insert('redemptions', {
      'child_id': childId, 'reward_id': rewardId,
      'points_cost': pointsCost, 'status': 'approved', 'created_at': now,
    });

    final updated = await d.query('children', columns: ['points'], where: 'id = ?', whereArgs: [childId]);
    return updated.first['points'] as int;
  }

  Future<List<RedemptionRecord>> getRedemptions() async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT r.*, c.name as child_name, rw.name as reward_name, rw.emoji as reward_emoji
      FROM redemptions r
      JOIN children c ON r.child_id = c.id
      JOIN rewards rw ON r.reward_id = rw.id
      ORDER BY r.created_at DESC
    ''');
    return rows.map((r) => RedemptionRecord(
      id: r['id'] as int,
      childName: r['child_name'] as String? ?? '',
      rewardName: r['reward_name'] as String? ?? '',
      rewardEmoji: r['reward_emoji'] as String? ?? '🎁',
      pointsCost: r['points_cost'] as int,
      status: r['status'] as String? ?? 'approved',
      createdAt: r['created_at'] as String,
    )).toList();
  }

  Future<Map<String, dynamic>> getChildDetail(int id) async {
    final child = await getChild(id);
    if (child == null) throw Exception('孩子不存在');
    final transactions = await getTransactions(childId: id, limit: 20);
    return {
      'id': child.id,
      'name': child.name,
      'avatar_emoji': child.avatarEmoji,
      'points': child.points,
      'transactions': transactions.map((t) => {
        'id': t.id, 'points': t.points, 'description': t.description,
        'type': t.type, 'created_at': t.createdAt,
      }).toList(),
    };
  }
}
