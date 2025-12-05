import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../app_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primary = colors.primary;
    final background = colors.surface;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                // App logo
                SizedBox(
                  width: 160,
                  height: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      'lib/assets/NestPet_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('NestPet', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: primary)),
                const SizedBox(height: 12),

                // Buttons: make them narrower and centered using LayoutBuilder
                LayoutBuilder(builder: (context, constraints) {
                  final buttonWidth = (constraints.maxWidth * 0.72).clamp(240.0, 380.0);
                  return Column(
                    children: [
                      SizedBox(
                        width: buttonWidth,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => router.go('/'),
                          child: const Text('Entrar', style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 12),
                        SizedBox(
                        width: buttonWidth,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primary,
                            side: BorderSide(color: primary.withOpacity(0.9)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            router.go('/register/user');
                          },
                          child: const Text('Criar Conta', style: TextStyle(fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: buttonWidth,
                        child: TextButton(
                          onPressed: () {
                            final app = Provider.of<AppState>(context, listen: false);
                            app.login(UserRole.user);
                            router.go('/u/home');
                          },
                          child: Text('Entrar como Convidado', style: TextStyle(color: primary.withOpacity(0.9))),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
