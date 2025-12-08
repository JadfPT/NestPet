/*
Propósito: Ecrã de autenticação para iniciar sessão ou registar.
- Permite login com email/password e opcionalmente registo no mesmo fluxo.
- Ajusta destino e papel (utilizador/instituição) conforme metadados.

Observações:
- Usa `AuthService` e Supabase para autenticação e leitura de utilizador.
- Validação de NIF incluída para registos de instituição.
- Navegação via `router` para `/u/home` ou `/o/home` após login.
*/
// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import '../../app_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_state.dart';
import '../../services/auth_service.dart';

// Valida um NIF: 9 dígitos com verificação do dígito de controlo.
bool _validateNIF(String nif) {
  if (!RegExp(r'^\d{9}$').hasMatch(nif)) return false;
  final digits = nif.split('').map(int.parse).toList();
  final weights = [9,8,7,6,5,4,3,2];
  var sum = 0;
  for (var i = 0; i < 8; i++) { sum += digits[i] * weights[i]; }
  final remainder = sum % 11;
  var check = 11 - remainder;
  if (check >= 10) check = 0;
  return check == digits[8];
}

// Ecrã de login/registo.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form e controladores.
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nifCtrl = TextEditingController();
  // Modo registo vs login e papel preferido.
  bool _isRegister = false;
  final UserRole _role = UserRole.user;
  // Serviço de autenticação e estados.
  final _auth = AuthService();
  bool _loading = false;
  bool _checkedQuery = false;
  bool _obscurePassword = true;

  // Submete: login ou registo, define papel e navega.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; });
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    String? snackMessage;
    bool performLogin = false;
    String? targetPath;

    try {
      if (_isRegister) {
        // Em registo de org, valida NIF.
        if (_role == UserRole.org) {
          final nif = _nifCtrl.text.trim();
          if (!_validateNIF(nif)) throw Exception('NIF inválido');
        }
        await _auth.signUpEmail(email, pass);
        final user = _auth.currentUser();
        if (user == null) {
          snackMessage = 'Registo efetuado. Verifique o seu email para confirmar a conta antes de iniciar sessão.';
        } else {
          performLogin = true;
        }
      } else {
        // Fluxo de login.
        await _auth.signInEmail(email, pass);
        final user = _auth.currentUser();
        if (user == null) throw Exception('Login falhou');
        performLogin = true;
      }

      if (performLogin) {

        User? sdkUser;
        try {
          final resp = await Supabase.instance.client.auth.getUser();
          sdkUser = resp.user ?? _auth.currentUser();
        } catch (_) {
          sdkUser = _auth.currentUser();
        }

        // Determina papel final a partir dos metadados; default para `_role`.
        String chosen = 'user';
        try {
          final meta = sdkUser?.userMetadata;
          if (meta != null && meta['role'] != null) chosen = meta['role'] as String;
        } catch (_) {}

        final finalRole = (chosen == 'org') ? UserRole.org : _role;
        targetPath = finalRole == UserRole.org ? '/o/home' : '/u/home';
      }
    } catch (e) {
      snackMessage = e.toString();
    } finally {
      if (context.mounted) {
        if (snackMessage != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snackMessage)));
        if (performLogin) {
          final app = context.read<AppState>();
          try {
            User? sdkUser;
            try {
              final resp = await Supabase.instance.client.auth.getUser();
              sdkUser = resp.user ?? _auth.currentUser();
            } catch (_) {
              sdkUser = _auth.currentUser();
            }

            String chosen = 'user';
            try {
              final meta = sdkUser?.userMetadata;
              if (meta != null && meta['role'] != null) chosen = meta['role'] as String;
            } catch (_) {}
            final finalRole = (chosen == 'org') ? UserRole.org : _role;
            app.login(finalRole);
          } catch (_) {
            app.login(_role);
          }
          // Navega para o ecrã inicial do papel escolhido.
          router.go(targetPath!);
        }
        setState(() { _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lê query `register=true` para ativar modo registo.
    if (!_checkedQuery) {
      _checkedQuery = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final q = Uri.base.queryParameters['register'];
        if (q == 'true' && !_isRegister) {
          setState(() { _isRegister = true; });
        }
      });
    }
    // Cores de estilo.
    final colors = Theme.of(context).colorScheme;
    final primary = colors.primary;
    final surface = colors.surface;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Botão voltar.
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => router.go('/welcome'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo e título.
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.asset('lib/assets/NestPet_logo.png', fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('NestPet', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: primary)),
                        const SizedBox(height: 12),
                        // Campo email.
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: InputDecoration(
                            labelText: 'email',
                            filled: true,
                            fillColor: colors.background,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primary.withAlpha((0.35*255).round()))),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Email requerido' : null,
                        ),
                        const SizedBox(height: 12),

                        // Campo password com alternância de visibilidade.
                        TextFormField(
                          controller: _passCtrl,
                          decoration: InputDecoration(
                            labelText: 'palavra-passe',
                            filled: true,
                            fillColor: colors.background,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primary.withAlpha((0.35*255).round()))),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: primary.withAlpha((0.6*255).round())),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (v) => (v == null || v.length < 6) ? 'Password min 6' : null,
                        ),
                        const SizedBox(height: 18),

                        // Botão de ação principal.
                        SizedBox(
                          width: 260,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Entrar', style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
