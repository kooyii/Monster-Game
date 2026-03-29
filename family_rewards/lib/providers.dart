import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import 'models.dart';

// ── Parent auth state ─────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier() : super(false);

  final _storage = const FlutterSecureStorage();

  Future<bool> hasPin() async {
    final pin = await _storage.read(key: 'parent_pin');
    return pin != null && pin.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: 'parent_pin', value: pin);
  }

  Future<bool> checkPin(String pin) async {
    final stored = await _storage.read(key: 'parent_pin');
    return stored == pin;
  }

  Future<bool> loginWithPin(String pin) async {
    final ok = await checkPin(pin);
    if (!ok) return false;
    state = true;
    return true;
  }

  Future<void> loginWithCredentials(String username, String password) async {
    await ApiService().login(username, password);
    state = true;
  }

  void logout() {
    state = false;
    ApiService().logout();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref) => AuthNotifier());

// ── Data providers ────────────────────────────────────────────────────────────
final childrenProvider = FutureProvider.autoDispose<List<Child>>((ref) async {
  ref.watch(authProvider);
  return ApiService().getChildren();
});

final publicChildrenProvider = FutureProvider.autoDispose<List<Child>>((ref) async {
  return ApiService().getPublicChildren();
});

final rewardsProvider = FutureProvider.autoDispose<List<Reward>>((ref) async {
  ref.watch(authProvider);
  return ApiService().getRewards();
});

final transactionsProvider = FutureProvider.autoDispose<List<PointTransaction>>((ref) async {
  ref.watch(authProvider);
  return ApiService().getTransactions(limit: 30);
});

// ── Parent account helpers ────────────────────────────────────────────────────
Future<bool> hasParentAccount() async {
  const storage = FlutterSecureStorage();
  final user = await storage.read(key: 'parent_username');
  return user != null && user.isNotEmpty;
}

Future<void> saveParentAccount(String username, String password) async {
  const storage = FlutterSecureStorage();
  await storage.write(key: 'parent_username', value: username);
  await storage.write(key: 'parent_password', value: password);
}
