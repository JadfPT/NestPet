import 'package:shared_preferences/shared_preferences.dart';

/// Small helper to persist the last logged-in role so the UI can restore
/// the correct app shell after the app restarts.
class SessionService {
  static const _roleKey = 'nestpet_role';

  /// Save the role string ('user' or 'org')
  static Future<void> saveRole(String role) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_roleKey, role);
  }

  /// Clear saved role
  static Future<void> clearRole() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_roleKey);
  }

  /// Return the saved role, or null if none
  static Future<String?> loadRole() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_roleKey);
  }
}
