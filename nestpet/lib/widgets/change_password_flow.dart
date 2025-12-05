import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// email reset removed; no redirect config needed here

/// Reusable change-password flow.
/// Call `ChangePasswordFlow.show(context)` to present options to the user.
class ChangePasswordFlow {
  static Future<void> show(BuildContext context) async {
    // Direct in-app change: ask for current password + new password + confirm
    final formKey = GlobalKey<FormState>();
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    var obscureCurrent = true;
    var obscureNew = true;
    var obscureConfirm = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setState) {
          // Use local variables declared above so their state is preserved across rebuilds
          return AlertDialog(
            title: const Text('Alterar password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentCtrl,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Password atual',
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Insira a password atual' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: newCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Nova password',
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => obscureNew = !obscureNew),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 8) ? 'A password deve ter pelo menos 8 caracteres' : null,
                  ),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirmar password',
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                    validator: (v) => v != newCtrl.text ? 'Passwords não coincidem' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) Navigator.pop(c, true);
                },
                child: const Text('Alterar'),
              ),
            ],
          );
        },
      ),
    );

    final newPassword = newCtrl.text;
    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
    if (ok != true) return;

    final supa = Supabase.instance.client.auth.currentUser;
    final email = supa?.email;
    if (email == null) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email da conta não disponível.')));
      return;
    }

    try {
      // Wait a moment to allow the dialog to fully dispose and the framework
      // to settle before making auth changes which can emit auth state events.
      await Future.delayed(const Duration(milliseconds: 250));

      // Optionally show a short-lived loading indicator while the request runs.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A atualizar password...')));
      }

      // Update the password directly for the current authenticated user.
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: newPassword));

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password alterada com sucesso')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alterar password: $e')));
      }
    }
  }
}
