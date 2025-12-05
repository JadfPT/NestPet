import 'package:shared_preferences/shared_preferences.dart';

/// Small helper to persist the last logged-in role so the UI can restore
/// the correct app shell after the app restarts.
class SessionService {
  static const _roleKey = 'nestpet_role';
  static const _orgNameKey = 'nestpet_org_name';
  static const _orgNifKey = 'nestpet_org_nif';
  static const _notifyKey = 'nestpet_notify_enabled';

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

  /// Save organization name + NIF temporarily so it can be synced to server
  static Future<void> saveOrgInfo(String name, String nif) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_orgNameKey, name);
    await sp.setString(_orgNifKey, nif);
  }

  static Future<Map<String, String?>> loadOrgInfo() async {
    final sp = await SharedPreferences.getInstance();
    return {
      'name': sp.getString(_orgNameKey),
      'nif': sp.getString(_orgNifKey),
    };
  }

  static Future<void> clearOrgInfo() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_orgNameKey);
    await sp.remove(_orgNifKey);
  }

  /// Return the saved role, or null if none
  static Future<String?> loadRole() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_roleKey);
  }

  static Future<void> saveNotificationsEnabled(bool enabled) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_notifyKey, enabled);
  }

  static Future<bool?> loadNotificationsEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_notifyKey);
  }
}
