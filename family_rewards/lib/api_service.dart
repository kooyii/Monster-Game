import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'local_db.dart';
import 'models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  bool _loggedIn = false;

  Future<void> init() async {}
  Future<void> reinit() async {}

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String username, String password) async {
    final storedUser = await _storage.read(key: 'parent_username');
    final storedPass = await _storage.read(key: 'parent_password');
    if (storedUser == null || storedPass == null) throw Exception('账号未设置');
    if (username != storedUser || password != storedPass) throw Exception('账号或密码错误');
    _loggedIn = true;
    return {'success': true};
  }

  Future<bool> relogin() async {
    _loggedIn = true;
    return true;
  }

  void logout() => _loggedIn = false;

  bool get isLoggedIn => _loggedIn;

  // ── Public (no auth needed) ───────────────────────────────────────────────
  Future<List<Child>> getPublicChildren() => LocalDb().getChildren();

  Future<Map<String, dynamic>> getPublicChild(int id) => LocalDb().getChildDetail(id);

  Future<List<Reward>> getPublicRewards() => LocalDb().getRewards(allRewards: false);

  // ── Children ──────────────────────────────────────────────────────────────
  Future<List<Child>> getChildren() => LocalDb().getChildren();

  Future<void> createChild(String name, String username, String password, String avatarEmoji) =>
      LocalDb().createChild(name, avatarEmoji);

  Future<void> updateChild(int id, Map<String, dynamic> data) async {
    final dbData = <String, dynamic>{};
    if (data.containsKey('name')) dbData['name'] = data['name'];
    if (data.containsKey('avatar_emoji')) dbData['avatar_emoji'] = data['avatar_emoji'];
    await LocalDb().updateChild(id, dbData);
  }

  Future<void> deleteChild(int id) => LocalDb().deleteChild(id);

  // ── Points ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> awardPoints(int childId, int points, String description) async {
    final newBalance = await LocalDb().awardPoints(childId, points, description);
    return {'new_balance': newBalance};
  }

  Future<List<PointTransaction>> getTransactions({int? childId, int limit = 30}) =>
      LocalDb().getTransactions(childId: childId, limit: limit);

  // ── Rewards ───────────────────────────────────────────────────────────────
  Future<List<Reward>> getRewards({bool all = true}) => LocalDb().getRewards(allRewards: all);

  Future<void> createReward(String name, int pointsCost, String emoji, {String? description}) =>
      LocalDb().createReward(name, pointsCost, emoji, description: description);

  Future<void> updateReward(int id, Map<String, dynamic> data) => LocalDb().updateReward(id, data);

  Future<void> deleteReward(int id) => LocalDb().deleteReward(id);

  // ── Redemptions ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> directRedeem(int childId, int rewardId) async {
    final newBalance = await LocalDb().directRedeem(childId, rewardId);
    return {'new_balance': newBalance};
  }

  Future<List<RedemptionRecord>> getRedemptions() => LocalDb().getRedemptions();
}
