// Propósito geral: Serviço de sessão que persiste e recupera dados simples do utilizador
// (papel/role, info de organização, preferências de notificações) usando SharedPreferences.
// Observações:
// - Guarda apenas informação não sensível; segredos e tokens devem usar armazenamento seguro.
// - Chaves são namespaced com prefixo 'nestpet_' para evitar colisões.
// - Todas as operações são assíncronas e devem ser aguardadas.

import 'package:shared_preferences/shared_preferences.dart';

// API estática para ler/escrever preferências de sessão da aplicação.
class SessionService {
  // Chaves usadas no armazenamento local.
  static const _roleKey = 'nestpet_role';
  static const _orgNameKey = 'nestpet_org_name';
  static const _orgNifKey = 'nestpet_org_nif';
  static const _notifyKey = 'nestpet_notify_enabled';

  // Guarda o papel do utilizador.
  static Future<void> saveRole(String role) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_roleKey, role);
  }

  // Limpa o papel guardado.
  static Future<void> clearRole() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_roleKey);
  }

  // Guarda informação da organização temporariamente (nome e NIF) para uso pós-login.
  static Future<void> saveOrgInfo(String name, String nif) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_orgNameKey, name);
    await sp.setString(_orgNifKey, nif);
  }

  // Carrega a informação da organização (pode devolver null se não existir).
  static Future<Map<String, String?>> loadOrgInfo() async {
    final sp = await SharedPreferences.getInstance();
    return {
      'name': sp.getString(_orgNameKey),
      'nif': sp.getString(_orgNifKey),
    };
  }

  // Limpa informação de organização armazenada.
  static Future<void> clearOrgInfo() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_orgNameKey);
    await sp.remove(_orgNifKey);
  }

  // Lê o papel do utilizador guardado.
  static Future<String?> loadRole() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_roleKey);
  }

  // Guarda preferência de notificações (ativado/desativado).
  static Future<void> saveNotificationsEnabled(bool enabled) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_notifyKey, enabled);
  }

  // Lê preferência de notificações; pode devolver null se nunca foi definida.
  static Future<bool?> loadNotificationsEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_notifyKey);
  }
}
