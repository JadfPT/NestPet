import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('NestPet')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Entrar como:', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () { app.login(UserRole.user); context.go('/u/home'); },
                child: const Text('Utilizador'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () { app.login(UserRole.org);  context.go('/o/home'); },
                child: const Text('Instituição'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
