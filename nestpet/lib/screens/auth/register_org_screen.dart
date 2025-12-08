/*
Propósito: Ecrã de registo para criar uma conta de instituição (organização).
- Recolhe nome, email, password e NIF com validação específica.
- Inicia fluxo de registo, marca papel como org e cria registos auxiliares.

Observações:
- Usa `AuthService`/Supabase para registar e guardar dados em `organizations`/`pending_registrations`.
- Guarda papel e info temporária via `SessionService` durante o processo.
- Controla estado de carregamento e visibilidade de passwords.
*/
// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import '../../app_router.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



// Ecrã de registo de instituição.
class RegisterOrgScreenFixed extends StatefulWidget {
  const RegisterOrgScreenFixed({super.key});

  @override
  State<RegisterOrgScreenFixed> createState() => _RegisterOrgScreenFixedState();
}

class _RegisterOrgScreenFixedState extends State<RegisterOrgScreenFixed> {
  // Form e controladores de campos.
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _nifCtrl = TextEditingController();
  // Serviço de autenticação e estado de carregamento.
  final _auth = AuthService();
  bool _loading = false;
  // Visibilidade das passwords.
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // Submete: valida NIF, regista conta, define papel org e cria registos auxiliares.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final nif = _nifCtrl.text.trim();
    String? message;
    try {
      // Validações simples do NIF: 9 dígitos e começar por 5 ou 6.
      if (!RegExp(r'^\d{9}$').hasMatch(nif)) throw Exception('NIF deve ter 9 dígitos');
      if (!RegExp(r'^[56]').hasMatch(nif)) throw Exception('NIF deve começar por 5 ou 6');
      final res = await _auth.signUpEmail(email, pass);

      // Guarda papel e info da org na sessão (temporário).
      await SessionService.saveRole('org');

      await SessionService.saveOrgInfo(_nameCtrl.text.trim(), nif);


      try {
        final user = res.user ?? Supabase.instance.client.auth.currentUser;
        if (user != null) {
          try {
            // Atualiza metadados com papel e NIF.
            await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'role': 'org', 'nif': nif}));
          } catch (_) {}

          try {
            // Cria registo na tabela organizations.
            final insertData = {
              'name': _nameCtrl.text.trim(),
              'nif': nif,
              'user_id': user.id,
            };
            await Supabase.instance.client.from('organizations').insert(insertData);
            await SessionService.clearOrgInfo();
          } catch (_) {}
          try {
            // Limpa perfis anteriores para evitar conflito.
            await Supabase.instance.client.from('profiles').delete().eq('id', user.id);
          } catch (_) {}
        }

        try {
          // Marca registo pendente auxiliar.
          await Supabase.instance.client.from('pending_registrations').insert({
            'email': email,
            'name': _nameCtrl.text.trim(),
            'nif': nif,
            'role': 'org',
          });
        } catch (_) {}
      } catch (_) {}

      // Navega e informa para confirmação por email.
      router.go('/');
      message = 'Registo efetuado. Verifique o seu email para confirmar a conta.';
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
    // Cores do tema.
    final colors = Theme.of(context).colorScheme;
    final primary = colors.primary;

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
                      // Logo e título.
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

                      // Formulário de registo da instituição.
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Nome da instituição.
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
                            // Email.
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
                            // Palavra-passe com alternância de visibilidade.
                            TextFormField(
                              controller: _passCtrl,
                              decoration: InputDecoration(
                                labelText: 'Palavra-passe',
                                filled: true,
                                fillColor: colors.background,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                ),
                              ),
                              obscureText: _obscurePass,
                              validator: (v) => (v == null || v.length < 6) ? 'Password min 6' : null,
                            ),
                            const SizedBox(height: 12),
                            // Confirmar palavra-passe.
                            TextFormField(
                              controller: _confirmCtrl,
                              decoration: InputDecoration(
                                labelText: 'Confirmar palavra-passe',
                                filled: true,
                                fillColor: colors.background,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              obscureText: _obscureConfirm,
                              validator: (v) => (v == null || v != _passCtrl.text) ? 'As passwords não coincidem' : null,
                            ),
                            const SizedBox(height: 12),
                            // NIF com validação específica.
                            TextFormField(
                              controller: _nifCtrl,
                              decoration: InputDecoration(
                                labelText: 'NIF',
                                filled: true,
                                fillColor: colors.background,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'NIF requerido';
                                final t = v.trim();
                                if (t.length != 9) return 'NIF deve ter 9 dígitos';
                                if (!RegExp(r'^\d{9}$').hasMatch(t)) return 'NIF inválido';
                                if (!(t.startsWith('5') || t.startsWith('6'))) return 'NIF deve começar por 5 ou 6';
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Botão de criar como instituição.
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
