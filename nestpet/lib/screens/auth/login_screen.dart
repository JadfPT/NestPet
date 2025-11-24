// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import '../../app_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/auth_service.dart';

bool _validateNIF(String nif) {
  // NIF (Portugal) validation: 9 digits, checksum on first 8 digits
  if (!RegExp(r'^\d{9}4').hasMatch(nif)) return false;
  final digits = nif.split('').map(int.parse).toList();
  final weights = [9,8,7,6,5,4,3,2];
  var sum = 0;
  for (var i = 0; i < 8; i++) { sum += digits[i] * weights[i]; }
  final remainder = sum % 11;
  var check = 11 - remainder;
  if (check >= 10) check = 0;
  return check == digits[8];
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nifCtrl = TextEditingController();
  bool _isRegister = false;
  UserRole _role = UserRole.user;
  final _auth = AuthService();
  bool _loading = false;
  bool _checkedQuery = false;

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
        if (_role == UserRole.org) {
          final nif = _nifCtrl.text.trim();
          if (!_validateNIF(nif)) throw Exception('NIF inválido');
        }
        // Tentar registar; Supabase pode requerer confirmação por email.
        await _auth.signUpEmail(email, pass);
        final user = _auth.currentUser();
        if (user == null) {
          // Registo criado, mas sem sessão ativa — informar utilizador.
          snackMessage = 'Registo efetuado. Verifique o seu email para confirmar a conta antes de iniciar sessão.';
        } else {
          performLogin = true;
        }
      } else {
        await _auth.signInEmail(email, pass);
        final user = _auth.currentUser();
        if (user == null) throw Exception('Login falhou');
        performLogin = true;
      }

      if (performLogin) {
        // Prefer server-side role metadata when available, otherwise use chosen _role
        final user = _auth.currentUser();
        String chosen = 'user';
        try {
          final meta = user?.userMetadata;
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
          app.login(_role);
          router.go(targetPath!);
        }
        setState(() { _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check for a `register` query parameter once and toggle register mode.
    if (!_checkedQuery) {
      _checkedQuery = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final q = Uri.base.queryParameters['register'];
        if (q == 'true' && !_isRegister) {
          setState(() { _isRegister = true; });
        }
      });
    }
    final colors = Theme.of(context).colorScheme;
    final primary = colors.primary;
    final surface = colors.surface;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  // Card container that matches the wireframe
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
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
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: InputDecoration(
                            labelText: 'email',
                            filled: true,
                            fillColor: colors.background,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primary.withOpacity(0.35))),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Email requerido' : null,
                        ),
                        const SizedBox(height: 12),

                        // Password field
                        TextFormField(
                          controller: _passCtrl,
                          decoration: InputDecoration(
                            labelText: 'palavra-passe',
                            filled: true,
                            fillColor: colors.background,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primary.withOpacity(0.35))),
                            suffixIcon: Icon(Icons.visibility_off, color: primary.withOpacity(0.6)),
                          ),
                          obscureText: true,
                          validator: (v) => (v == null || v.length < 6) ? 'Password min 6' : null,
                        ),
                        const SizedBox(height: 18),

                        // Entrar button
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
