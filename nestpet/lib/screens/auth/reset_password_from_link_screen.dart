import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../supabase_config.dart';

class ResetPasswordFromLinkScreen extends StatefulWidget {
  // Accept token via constructor (when navigating internally) or via query params
  final String? token;
  const ResetPasswordFromLinkScreen({super.key, this.token});

  @override
  State<ResetPasswordFromLinkScreen> createState() => _ResetPasswordFromLinkScreenState();
}

class _ResetPasswordFromLinkScreenState extends State<ResetPasswordFromLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _token;

  @override
  void initState() {
    super.initState();
    _token = widget.token;
  }

  @override
  void dispose() {
    _passwordCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_token == null || _token!.isEmpty) {
      setState(() => _error = 'Token inválido ou em falta. Reabra o link enviado por email.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final url = Uri.parse('${SupabaseConfig.url.replaceAll(RegExp(r'\/$'), '')}/auth/v1/user');
      final res = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer ${_token!}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'password': _passwordCtl.text}),
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Senha alterada'),
            content: const Text('A sua palavra-passe foi alterada com sucesso. Pode agora fazer login.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
        setState(() => _error = body != null && body['message'] != null ? body['message'] : 'Falha ao alterar a palavra-passe');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_token == null) ...[
              const Text('A abrir link... Se nada acontecer, reabra o link enviado para o e‑mail.'),
              const SizedBox(height: 12),
            ],
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _passwordCtl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Nova palavra-passe'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Insira uma palavra-passe';
                      if (v.length < 8) return 'A palavra-passe deve ter pelo menos 8 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Alterar palavra-passe'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
