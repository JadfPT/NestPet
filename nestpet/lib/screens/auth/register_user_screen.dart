/*
Propósito: Ecrã de registo para criar uma conta de utilizador.
- Recolhe email e password, valida e inicia fluxo de registo.
- Mostra feedback e oferece atalho para registar como instituição.

Observações:
- Usa `AuthService`/Supabase para registar e cria entradas auxiliares.
- Controla estado de carregamento e visibilidade de passwords.
- Navegação via `router` após ações.
*/
// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import '../../app_router.dart';
import '../../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Ecrã de registo de utilizador.
class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  // Chave do formulário e controladores dos campos.
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  // Serviço de autenticação e estado de carregamento.
  final _auth = AuthService();
  bool _loading = false;

  // Estado de visibilidade das passwords.
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  // Submete o formulário: valida, regista e navega.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    String? message;
    try {
      final res = await _auth.signUpEmail(email, pass);
      final userId = res.user?.id ?? Supabase.instance.client.auth.currentUser?.id;

      try {
        // Marca registo pendente (auxiliar) com papel user.
        await Supabase.instance.client.from('pending_registrations').insert({
          'email': email,
          'role': 'user',
        });
      } catch (_) {}

      if (userId != null) {
        try {
          // Limpa perfis anteriores para evitar conflito.
          await Supabase.instance.client.from('profiles').delete().eq('id', userId);
        } catch (_) {}
      }

      // Volta ao ecrã principal e avisa para confirmar email.
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
    // Cores do tema para estilização.
    final colors = Theme.of(context).colorScheme;
    final primary = colors.primary;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Botão voltar para o ecrã de boas-vindas.
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
                      Text('Criar Conta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primary)),
                      const SizedBox(height: 16),

                      // Formulário de registo com validações.
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
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
                            const SizedBox(height: 18),

                            // Botão de criar como utilizador.
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
                                    : const Text('Criar como Utilizador', style: TextStyle(fontSize: 16, color: Colors.white)),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Atalho para registar como instituição.
                            TextButton(
                              onPressed: () => router.go('/register/org'),
                              child: Text('Criar como Instituição', style: TextStyle(color: primary.withAlpha((0.9*255).round()))),
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
