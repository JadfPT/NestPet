/*
Propósito: Ecrã de boas-vindas com acesso à autenticação e registo.
- Apresenta o logo e oferece opções para entrar, criar conta ou entrar como convidado.
- Adapta largura de botões ao ecrã para boa usabilidade.

Observações:
- Usa `router` para navegação e `AppState` para login rápido de convidado.
- Estilização baseada em `Theme.of(context).colorScheme` para consistência visual.
*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../app_router.dart';

// Ecrã estático de boas-vindas.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Cores do tema atual.
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
                // Logo da aplicação.
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
                // Título.
                Text('NestPet', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: primary)),
                const SizedBox(height: 12),

                // Ajusta largura dos botões conforme o espaço disponível.
                LayoutBuilder(builder: (context, constraints) {
                  final buttonWidth = (constraints.maxWidth * 0.72).clamp(240.0, 380.0);
                  return Column(
                    children: [
                      // Botão "Entrar" para ir ao fluxo de autenticação.
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
                        // Botão para criar nova conta de utilizador.
                        SizedBox(
                        width: buttonWidth,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primary,
                            side: BorderSide(color: primary.withAlpha((0.9*255).round())),
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
                      // Entrar como convidado: define papel e navega para home de utilizador.
                      SizedBox(
                        width: buttonWidth,
                        child: TextButton(
                          onPressed: () {
                            final app = Provider.of<AppState>(context, listen: false);
                            app.login(UserRole.user);
                            router.go('/u/home');
                          },
                          child: Text('Entrar como Convidado', style: TextStyle(color: primary.withAlpha((0.9*255).round()))),
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
