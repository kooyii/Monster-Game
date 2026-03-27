import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  late Dio _dio;
  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('server_url') ?? 'http://192.168.1.1:3000';
    _token = await _storage.read(key: 'jwt_token');
    _dio = Dio(BaseOptions(
      baseUrl: '$baseUrl/api',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) options.headers['Authorization'] = 'Bearer $_token';
        handler.next(options);
      },
    ));
  }

  Future<void> reinit() async => init();

  // ── Auth ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _dio.post('/auth/login', data: {'username': username, 'password': password});
    _token = res.data['token'];
    await _storage.write(key: 'jwt_token', value: _token);
    await _storage.write(key: 'parent_username', value: username);
    await _storage.write(key: 'parent_password', value: password);
    _dio.options.headers['Authorization'] = 'Bearer $_token';
    return res.data;
  }

  Future<bool> relogin() async {
    try {
      final u = await _storage.read(key: 'parent_username');
      final p = await _storage.read(key: 'parent_password');
      if (u == null || p == null) return false;
      await login(u, p);
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    _token = null;
    _storage.delete(key: 'jwt_token');
  }

  bool get isLoggedIn => _token != null;

  // ── Public (no auth) ──────────────────────────────────────────────────
  Future<List<Child>> getPublicChildren() async {
    final res = await _dio.get('/public/children');
    return (res.data as List).map((e) => Child.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getPublicChild(int id) async {
    final res = await _dio.get('/public/children/$id');
    return res.data;
  }

  Future<List<Reward>> getPublicRewards() async {
    final res = await _dio.get('/public/rewards');
    return (res.data as List).map((e) => Reward.fromJson(e)).toList();
  }

  // ── Children (parent auth) ────────────────────────────────────────────
  Future<List<Child>> getChildren() async {
    final res = await _dio.get('/users/children');
    return (res.data as List).map((e) => Child.fromJson(e)).toList();
  }

  Future<void> createChild(String name, String username, String password, String avatarEmoji) async {
    await _dio.post('/users/children', data: {
      'name': name, 'username': username, 'password': password, 'avatar_emoji': avatarEmoji,
    });
  }

  Future<void> updateChild(int id, Map<String, dynamic> data) async {
    await _dio.put('/users/$id', data: data);
  }

  Future<void> deleteChild(int id) async {
    await _dio.delete('/users/$id');
  }

  // ── Points ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> awardPoints(int childId, int points, String description) async {
    final res = await _dio.post('/points/award', data: {'child_id': childId, 'points': points, 'description': description});
    return res.data;
  }

  Future<List<PointTransaction>> getTransactions({int? childId, int limit = 30}) async {
    final params = <String, dynamic>{'limit': limit};
    if (childId != null) params['child_id'] = childId;
    final res = await _dio.get('/points/transactions', queryParameters: params);
    return (res.data as List).map((e) => PointTransaction.fromJson(e)).toList();
  }

  // ── Rewards ───────────────────────────────────────────────────────────
  Future<List<Reward>> getRewards({bool all = true}) async {
    final res = await _dio.get('/rewards', queryParameters: all ? {'all': 1} : {});
    return (res.data as List).map((e) => Reward.fromJson(e)).toList();
  }

  Future<void> createReward(String name, int pointsCost, String emoji, {String? description}) async {
    await _dio.post('/rewards', data: {'name': name, 'points_cost': pointsCost, 'emoji': emoji, 'description': description});
  }

  Future<void> updateReward(int id, Map<String, dynamic> data) async {
    await _dio.put('/rewards/$id', data: data);
  }

  Future<void> deleteReward(int id) async {
    await _dio.delete('/rewards/$id');
  }

  // ── Redemptions ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> directRedeem(int childId, int rewardId) async {
    final res = await _dio.post('/redemptions/direct', data: {'child_id': childId, 'reward_id': rewardId});
    return res.data;
  }

  Future<List<RedemptionRecord>> getRedemptions() async {
    final res = await _dio.get('/redemptions?status=approved');
    return (res.data as List).map((e) => RedemptionRecord.fromJson(e)).toList();
  }
}
