// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import '../../app_router.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

bool _validateNIFLocal(String nif) {
  // NIF (Portugal) validation: 9 digits, checksum on first 8 digits
  if (!RegExp(r'^\d{9}$').hasMatch(nif)) return false;
  final digits = nif.split('').map(int.parse).toList();
  final weights = [9, 8, 7, 6, 5, 4, 3, 2];
  var sum = 0;
  for (var i = 0; i < 8; i++) { sum += digits[i] * weights[i]; }
  final remainder = sum % 11;
  var check = 11 - remainder;
  if (check >= 10) check = 0;
  return check == digits[8];
}

class RegisterOrgScreenFixed extends StatefulWidget {
  const RegisterOrgScreenFixed({super.key});

  @override
  State<RegisterOrgScreenFixed> createState() => _RegisterOrgScreenFixedState();
}

class _RegisterOrgScreenFixedState extends State<RegisterOrgScreenFixed> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _nifCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final nif = _nifCtrl.text.trim();
    String? message;
    try {
      if (!_validateNIFLocal(nif)) throw Exception('NIF inválido');
      await _auth.signUpEmail(email, pass);
      // Persist desired role locally so after email confirmation + login
      // the AppState can fall back to this saved role if server metadata
      // is not present.
      await SessionService.saveRole('org');
      // Also save the organization info (name + nif) so we can create the
      // row in the `organizations` table on first real login (when session
      // exists and server-side writes are possible).
      await SessionService.saveOrgInfo(_nameCtrl.text.trim(), nif);

      // If signUp produced a session/currentUser (some Supabase setups do),
      // attempt to persist the role immediately server-side so other
      // devices will see it.
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // Update auth user metadata
          try {
            await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'role': 'org', 'nif': nif}));
          } catch (_) {}

          // Insert into organizations table linking user_id (if schema allows)
          try {
            final insertData = {
              'name': _nameCtrl.text.trim(),
              'nif': nif,
              'user_id': user.id,
            };
            await Supabase.instance.client.from('organizations').insert(insertData);
            // If successful, clear local org info
            await SessionService.clearOrgInfo();
          } catch (_) {}
        }
        // Also insert a pending registration record so the DB can later
        // associate the org to the auth user when the email is confirmed.
        // This allows server-side triggers to create the organization and
        // set user metadata even if signUp did not produce a session.
        try {
          await Supabase.instance.client.from('pending_registrations').insert({
            'email': email,
            'name': _nameCtrl.text.trim(),
            'nif': nif,
            'role': 'org',
          });
        } catch (_) {}
      } catch (_) {}
      final user = _auth.currentUser();
      if (user == null) {
        message = 'Registo efetuado. Verifique o seu email para confirmar a conta.';
      } else {
        final app = context.read<AppState>();
        app.login(UserRole.org);
        router.go('/o/home');
      }
    } catch (e) {
      message = e.toString();
    } finally {
      if (context.mounted) {
        if (message != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primary = colors.primary;

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
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset('lib/assets/NestPet_logo.png', fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Criar Conta (Instituição)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primary)),
                      const SizedBox(height: 16),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: InputDecoration(
                                labelText: 'Nome da Instituição',
                                filled: true,
                                fillColor: colors.background,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Nome requerido' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailCtrl,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                filled: true,
                                fillColor: colors.background,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Email requerido' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passCtrl,
                              decoration: InputDecoration(
                                labelText: 'Palavra-passe',
                                filled: true,
                                fillColor: colors.background,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              obscureText: true,
                              validator: (v) => (v == null || v.length < 6) ? 'Password min 6' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmCtrl,
                              decoration: InputDecoration(
                                labelText: 'Confirmar palavra-passe',
                                filled: true,
                                fillColor: colors.background,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              obscureText: true,
                              validator: (v) => (v == null || v != _passCtrl.text) ? 'As passwords não coincidem' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _nifCtrl,
                              decoration: InputDecoration(
                                labelText: 'NIF (9 dígitos)',
                                filled: true,
                                fillColor: colors.background,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'NIF requerido';
                                if (!_validateNIFLocal(v.trim())) return 'NIF inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            SizedBox(
                              width: 280,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: primary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('Criar como Instituição', style: TextStyle(fontSize: 16, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
