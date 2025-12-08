// Propósito geral: Definir e configurar o roteamento (GoRouter) da aplicação NestPet,
// incluindo as rotas para utilizadores e organizações, shells com navegação inferior
// personalizada e regras de redirecionamento com base no papel (role).
// Observações:
// - Usa ShellRoute para fornecer barras de navegação personalizadas por papel.
// - O redirect central impede acesso a rotas não permitidas conforme o estado (role).
// - As rotas com parentNavigatorKey abrem sobreposto ao shell.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import 'providers/app_state.dart';
import 'utils/unsaved_changes_guard.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/register_user_screen.dart';
import 'screens/auth/register_org_screen.dart';

import 'screens/user/user_home_screen.dart';
import 'screens/user/user_favorites_screen.dart';
import 'screens/user/profile_screen.dart';
import 'screens/common/edit_account_screen.dart';
import 'screens/user/animal_detail_screen.dart';
import 'screens/user/chat_screen.dart';
import 'screens/common/messages_screen.dart';

import 'screens/org/my_animals_screen.dart';
import 'screens/org/add_animal_screen.dart';
import 'screens/org/edit_animal_screen.dart';
import 'screens/org/profile_screen.dart';
import 'screens/org/chat_screen.dart';

// Shell para utilizador normal: fornece UI com barra inferior e navegação entre
// favoritos, home e perfil. O conteúdo é passado via `child`.
class _UserShell extends StatelessWidget {
  final Widget child;
  final String location;
  const _UserShell({required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    // Cores e dimensões da "pílula" de navegação.
    final primary = Theme.of(context).colorScheme.primary;
    const pillHeight = 58.0;
    final rawBottom = MediaQuery.of(context).viewPadding.bottom;

    final bottomInset = math.max(rawBottom, 16.0);

    return Scaffold(
      body: Stack(
        children: [
          // Espaço para o conteúdo acima da barra inferior.
          Padding(padding: EdgeInsets.only(bottom: bottomInset + pillHeight + 20), child: child),

          Positioned(
            bottom: bottomInset + 8,
            left: 16,
            right: 16,
            child: SizedBox(
              height: pillHeight,
              child: Container(
                height: pillHeight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.12*255).round()), blurRadius: 12, offset: Offset(0,6))],
                ),
                child: Builder(builder: (ctx) {
                  // Estado da localização atual para ativar ícones.
                  final loc = location;
                  final favActive = loc.startsWith('/u/favorites');
                  final homeActive = loc.startsWith('/u/home');
                  final profActive = loc.startsWith('/u/profile');
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botão favoritos.
                      IconButton(
                        onPressed: () async {
                          final ok = await UnsavedChangesRegistry.instance.maybeConfirmNavigation();
                          if (ok && context.mounted) context.go('/u/favorites');
                        },
                        icon: Icon(favActive ? Icons.star : Icons.star_border),
                        color: Colors.white,
                      ),

                      // Botão home (tap com área maior).
                      GestureDetector(
                        onTap: () async {
                          final ok = await UnsavedChangesRegistry.instance.maybeConfirmNavigation();
                          if (ok && context.mounted) context.go('/u/home');
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(homeActive ? Icons.home : Icons.home_outlined, color: Colors.white, size: 26),
                        ),
                      ),

                      // Botão perfil.
                      IconButton(
                        onPressed: () async {
                          final ok = await UnsavedChangesRegistry.instance.maybeConfirmNavigation();
                          if (ok && context.mounted) context.go('/u/profile');
                        },
                        icon: Icon(profActive ? Icons.person : Icons.person_outline),
                        color: Colors.white,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

// Shell para organizações: barra inferior com atalhos para adicionar, home e perfil.
class _OrgShell extends StatelessWidget {
  final Widget child;
  final String location;
  const _OrgShell({required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const pillHeight = 58.0;

    final rawBottom = MediaQuery.of(context).viewPadding.bottom;
    final bottomInset = math.max(rawBottom, 16.0);

    return Scaffold(
      body: Stack(
        children: [
          Padding(padding: EdgeInsets.only(bottom: bottomInset + pillHeight + 20), child: child),

          Positioned(
            bottom: bottomInset + 8,
            left: 16,
            right: 16,
            child: SizedBox(
              height: pillHeight,
              child: Container(
                height: pillHeight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.12*255).round()), blurRadius: 12, offset: Offset(0,6))],
                ),
                child: Builder(builder: (ctx) {
                  final loc = location;
                  final addActive = loc.startsWith('/o/add');
                  final homeActive = loc.startsWith('/o/home');
                  final profActive = loc.startsWith('/o/profile');
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botão adicionar animal.
                      IconButton(
                        onPressed: () async {
                          final ok = await UnsavedChangesRegistry.instance.maybeConfirmNavigation();
                          if (ok && context.mounted) context.go('/o/add');
                        },
                        icon: Icon(addActive ? Icons.add_box : Icons.add_box_outlined),
                        color: Colors.white,
                      ),

                      // Botão home.
                      GestureDetector(
                        onTap: () async {
                          final ok = await UnsavedChangesRegistry.instance.maybeConfirmNavigation();
                          if (ok && context.mounted) context.go('/o/home');
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
                          child: Icon(homeActive ? Icons.home : Icons.home_outlined, color: Colors.white, size: 26),
                        ),
                      ),

                      // Botão perfil da organização.
                      IconButton(
                        onPressed: () async {
                          final ok = await UnsavedChangesRegistry.instance.maybeConfirmNavigation();
                          if (ok && context.mounted) context.go('/o/profile');
                        },
                        icon: Icon(profActive ? Icons.person : Icons.person_outline),
                        color: Colors.white,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

// Chaves de Navigator para o root e shells, permitindo modais fora dos shells.
final _rootKey = GlobalKey<NavigatorState>();
final _userShellKey = GlobalKey<NavigatorState>();
final _orgShellKey  = GlobalKey<NavigatorState>();

// Instância principal do GoRouter com rotas iniciais, shells e rotas de detalhe/chat.
final router = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/welcome',
  routes: [
  // Rotas públicas iniciais.
  GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
  GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
  GoRoute(path: '/register/user', builder: (context, state) => const RegisterUserScreen()),
  GoRoute(path: '/register/org', builder: (context, state) => const RegisterOrgScreenFixed()),
  GoRoute(path: '/messages', builder: (context, state) => const MessagesScreen()),

    // Shell para utilizadores.
    ShellRoute(
      navigatorKey: _userShellKey,
      builder: (context, state, child) => _UserShell(location: state.fullPath ?? '/', child: child),
      routes: [
        GoRoute(path: '/u/home', builder: (context, state) => const UserHomeScreen()),
        GoRoute(path: '/u/favorites', builder: (context, state) => const UserFavoritesScreen()),
        GoRoute(path: '/u/profile', builder: (context, state) => const UserProfileScreen()),
        GoRoute(path: '/u/edit', builder: (context, state) => const EditAccountScreen()),
      ],
    ),

    // Shell para organizações.
    ShellRoute(
      navigatorKey: _orgShellKey,
      builder: (context, state, child) => _OrgShell(location: state.fullPath ?? '/', child: child),
      routes: [
        GoRoute(path: '/o/home', builder: (context, state) => const MyAnimalsScreen()),
        GoRoute(path: '/o/add', builder: (context, state) => const AddAnimalScreen()),
        GoRoute(path: '/o/profile', builder: (context, state) => const OrgProfileScreen()),
      ],
    ),

    // Rotas que abrem fora dos shells (detalhes/edição/chat em overlays/modais).
    GoRoute(
      path: '/o/edit/:id',
      parentNavigatorKey: _rootKey,
      builder: (ctx, st) => EditAnimalScreen(id: st.pathParameters['id']!),
    ),
    GoRoute(
      path: '/animal/:id',
      parentNavigatorKey: _rootKey,
      builder: (ctx, st) => AnimalDetailScreen(id: st.pathParameters['id']!),
    ),
    GoRoute(
      path: '/chat/:animalId/:userId',
      parentNavigatorKey: _rootKey,
      builder: (ctx, st) => UserChatScreen(animalId: st.pathParameters['animalId']!, userId: st.pathParameters['userId']),
    ),
    GoRoute(
      path: '/org/chat/:animalId/:userId',
      parentNavigatorKey: _rootKey,
      builder: (ctx, st) => OrgChatScreen(animalId: st.pathParameters['animalId']!, userId: st.pathParameters['userId']!),
    ),
  ],
  // Regra de redirecionamento: garante que cada papel vê o seu espaço e bloqueia acessos indevidos.
  redirect: (ctx, st) {
      final role = ctx.read<AppState>().role;
      final loc = st.fullPath ?? '/';
      if (role == null && loc != '/' && loc != '/welcome' && loc != '/register/user' && loc != '/register/org') return '/';
    if (role == UserRole.user && (loc == '/' || loc == '/welcome' || loc.startsWith('/o/'))) return '/u/home';
    if (role == UserRole.org  && (loc == '/' || loc == '/welcome' || loc.startsWith('/u/'))) return '/o/home';
    return null;
  },
);
