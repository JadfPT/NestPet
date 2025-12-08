// Propósito geral: Serviço de autenticação que encapsula operações básicas com o
// Supabase (registo, login, logout, leitura de utilizador atual e stream de alterações).
// Observações:
// - Usa o cliente global de Supabase inicializado na app.
// - Métodos são assíncronos onde aplicável; lidar com erros/validar inputs fora deste serviço.
// - `authChanges` emite o utilizador atual após cada alteração de estado.

import 'package:supabase_flutter/supabase_flutter.dart';

// API simples para autenticação com email/password em Supabase.
class AuthService {
  // Referência ao cliente Supabase para chamadas de auth.
  final _client = Supabase.instance.client;

  // Registo com email e password. Pode disparar verificação por email se configurado.
  Future<AuthResponse> signUpEmail(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }


  // Login com email e password. Retorna AuthResponse com sessão/utente.
  Future<AuthResponse> signInEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  // Termina sessão do utilizador atual.
  Future<void> signOut() async => await _client.auth.signOut();

  // Devolve o utilizador atual (ou null se não autenticado).
  User? currentUser() => _client.auth.currentUser;

  // Stream que reflete alterações de estado de auth e mapeia para o utilizador atual.
  Stream<User?> authChanges() => _client.auth.onAuthStateChange.map((_) => _client.auth.currentUser);
}
