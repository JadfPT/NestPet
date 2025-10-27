import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.note_alt_outlined, size: 96),
              const SizedBox(height: 16),
              Text('Notas Demo', style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('SharedPreferences + SQLite', style: t.bodyMedium),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Entrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
