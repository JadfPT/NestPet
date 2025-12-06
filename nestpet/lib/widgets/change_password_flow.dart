import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reusable change-password flow.
/// Call `ChangePasswordFlow.show(context)` to present options to the user.
class ChangePasswordFlow {
  static Future<void> show(BuildContext context) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (c) => const _ChangePasswordDialog(),
    );

    if (result == null) return;

    final currentPassword = result['current']!;
    final newPassword = result['new']!;

    // Wait for dialog to fully close and widget tree to settle
    await Future.delayed(const Duration(milliseconds: 800));

    final supa = Supabase.instance.client.auth.currentUser;
    final email = supa?.email;
    if (email == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email da conta não disponível.')),
        );
      }
      return;
    }

    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A validar password...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Validate current password by attempting to reauthenticate
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: currentPassword,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password atual inválida'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Password is valid, now update it
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A atualizar password...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password alterada com sucesso'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar password: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alterar password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentCtrl,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: 'Password atual',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureCurrent = !_obscureCurrent);
                  },
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Insira a password atual' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _newCtrl,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'Nova password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureNew = !_obscureNew);
                  },
                ),
              ),
              validator: (v) => (v == null || v.length < 8)
                  ? 'A password deve ter pelo menos 8 caracteres'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirmar password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  },
                ),
              ),
              validator: (v) =>
                  v != _newCtrl.text ? 'Passwords não coincidem' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(null),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context, rootNavigator: true).pop({
                'current': _currentCtrl.text,
                'new': _newCtrl.text,
              });
            }
          },
          child: const Text('Alterar'),
        ),
      ],
    );
  }
}
