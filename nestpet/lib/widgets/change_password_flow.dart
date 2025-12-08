// Propósito geral: Fornece um fluxo de UI para alterar a password do utilizador
// com validação local e operações de autenticação Supabase.
// Observações:
// - Valida a password atual efetuando um sign-in antes de atualizar.
// - Usa SnackBar para feedback ao utilizador e protege chamadas com context.mounted.
// - O diálogo devolve as passwords via Navigator e é obrigatório preencher corretamente.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Classe utilitária com método estático para apresentar o diálogo e executar a alteração.
class ChangePasswordFlow {
  // Abre o diálogo, valida a password atual, atualiza para a nova e dá feedback visual.
  static Future<void> show(BuildContext context) async {
    // Mostra o diálogo e aguarda o resultado (mapa com 'current' e 'new').
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (c) => const _ChangePasswordDialog(),
    );

    if (result == null) return;

    // Extrai passwords fornecidas pelo utilizador.
    final currentPassword = result['current']!;
    final newPassword = result['new']!;

    // Pequeno atraso para UX (permitir ver mensagens sequenciais suavemente).
    await Future.delayed(const Duration(milliseconds: 800));

    // Obtém email do utilizador autenticado; necessário para validar a password atual.
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
      // Notifica que vai validar a password atual.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A validar password...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      try {
        // Tenta iniciar sessão com email + password atual para validar.
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: currentPassword,
        );
      } catch (e) {
        // Password atual inválida: informa e aborta.
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

      // Password atual validada: avisa que vai atualizar.
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A atualizar password...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Atualiza a password do utilizador.
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      // Sucesso: informa utilizador.
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
      // Erro inesperado no processo: mostra mensagem com detalhe.
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

// Diálogo com formulário para recolher a password atual e a nova (com confirmação).
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  // Chave do formulário e controladores dos campos de texto.
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Estado de visibilidade (mostrar/ocultar) de cada campo de password.
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    // Liberta recursos dos controladores.
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Título do diálogo.
      title: const Text('Alterar password'),
      // Conteúdo: formulário com três campos (atual, nova, confirmar).
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Campo: password atual, com toggle de visibilidade e validação obrigatória.
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
            // Campo: nova password com toggle de visibilidade.
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
            // Campo: confirmar password (deve coincidir com a nova).
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
      // Ações do diálogo: cancelar ou enviar (valida antes de fechar).
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
