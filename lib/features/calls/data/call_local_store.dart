import 'package:shared_preferences/shared_preferences.dart';

class CallLocalStore {
  static const _activeCallIdKey = 'active_call_id';

  Future<void> saveActiveCallId(int callId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeCallIdKey, callId);
  }

  Future<int?> getActiveCallId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activeCallIdKey);
  }

  Future<void> clearActiveCallId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeCallIdKey);
  }
}
