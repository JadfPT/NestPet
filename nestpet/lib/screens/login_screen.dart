// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import '../app_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';

bool _validateNIF(String nif) {
  // NIF (Portugal) validation: 9 digits, checksum on first 8 digits
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
        targetPath = _role == UserRole.org ? '/o/home' : '/u/home';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Autenticação')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Row(children: [
                  Expanded(child: Text(_isRegister ? 'Criar conta' : 'Entrar', style: const TextStyle(fontSize: 22))),
                  Switch(value: _isRegister, onChanged: (v) => setState(() => _isRegister = v)),
                ]),
                const SizedBox(height: 12),
                TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => (v==null||v.isEmpty)?'Email requerido':null),
                const SizedBox(height: 8),
                TextFormField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: (v) => (v==null||v.length<6)?'Password min 6':null),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: RadioListTile<UserRole>(value: UserRole.user, groupValue: _role, title: const Text('Utilizador'), onChanged: (v)=> setState(()=> _role=v!))),
                  Expanded(child: RadioListTile<UserRole>(value: UserRole.org, groupValue: _role, title: const Text('Instituição'), onChanged: (v)=> setState(()=> _role=v!))),
                ]),
                if (_isRegister && _role==UserRole.org) ...[
                  const SizedBox(height: 8),
                  TextFormField(controller: _nifCtrl, decoration: const InputDecoration(labelText: 'NIF (Instituição)'), validator: (v) { if (v==null||v.isEmpty) return 'NIF requerido'; return _validateNIF(v.trim())?null:'NIF inválido'; }),
                ],
                const SizedBox(height: 20),
                FilledButton(onPressed: _loading?null:_submit, child: _loading?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)): Text(_isRegister?'Criar conta':'Entrar')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
