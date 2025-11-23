import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  // Registar um utilizador com email/password
  Future<AuthResponse> signUpEmail(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  // Iniciar sessão com email/password
  Future<AuthResponse> signInEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  // Sair
  Future<void> signOut() async => await _client.auth.signOut();

  // Utilizador atual (pode ser nulo)
  User? currentUser() => _client.auth.currentUser;

  // Stream de alterações de autenticação
  Stream<User?> authChanges() => _client.auth.onAuthStateChange.map((_) => _client.auth.currentUser);
}
