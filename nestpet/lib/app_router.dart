import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';

// --- USER screens
import 'screens/login_screen.dart';
import 'screens/user/user_home_screen.dart';
import 'screens/user/user_favorites_screen.dart';
import 'screens/user/profile_screen.dart';
import 'screens/user/animal_detail_screen.dart';
import 'screens/user/chat_screen.dart';

// --- ORG screens
import 'screens/org/my_animals_screen.dart';
import 'screens/org/add_animal_screen.dart';
import 'screens/org/edit_animal_screen.dart';
import 'screens/org/profile_screen.dart';
import 'screens/org/chat_screen.dart';

// Shells de bottom bar (como já tinhas)
class _UserShell extends StatelessWidget {
  final Widget child;
  const _UserShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final l = GoRouterState.of(context).uri.toString();
    int idx = 1;
    if (l.startsWith('/u/favorites')) idx = 0;
    if (l.startsWith('/u/profile')) idx = 2;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/u/favorites'); break;
            case 1: context.go('/u/home'); break;
            case 2: context.go('/u/profile'); break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favoritos'),
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _OrgShell extends StatelessWidget {
  final Widget child;
  const _OrgShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final l = GoRouterState.of(context).uri.toString();
    int idx = 1;
    if (l.startsWith('/o/add')) idx = 0;
    if (l.startsWith('/o/profile')) idx = 2;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/o/add'); break;
            case 1: context.go('/o/home'); break;
            case 2: context.go('/o/profile'); break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.add_box_outlined), selectedIcon: Icon(Icons.add_box), label: 'Adicionar'),
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.apartment), label: 'Perfil'),
        ],
      ),
    );
  }
}

// ------- Navigator keys (root + shells)
final _rootKey = GlobalKey<NavigatorState>();
final _userShellKey = GlobalKey<NavigatorState>();
final _orgShellKey  = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const LoginScreen()),

    // USER (shell)
    ShellRoute(
      navigatorKey: _userShellKey,
      builder: (_, __, child) => _UserShell(child: child),
      routes: [
        GoRoute(path: '/u/home', builder: (_, __) => const UserHomeScreen()),
        GoRoute(path: '/u/favorites', builder: (_, __) => const UserFavoritesScreen()),
        GoRoute(path: '/u/profile', builder: (_, __) => const UserProfileScreen()),
      ],
    ),

    // ORG (shell)
    ShellRoute(
      navigatorKey: _orgShellKey,
      builder: (_, __, child) => _OrgShell(child: child),
      routes: [
        GoRoute(path: '/o/home', builder: (_, __) => const MyAnimalsScreen()),
        GoRoute(path: '/o/add', builder: (_, __) => const AddAnimalScreen()),
        GoRoute(path: '/o/edit/:id', builder: (ctx, st) => EditAnimalScreen(id: st.pathParameters['id']!)),
        GoRoute(path: '/o/profile', builder: (_, __) => const OrgProfileScreen()),
      ],
    ),

    // Rotas comuns SEMPRE no root (fora dos shells)
    GoRoute(
      path: '/animal/:id',
      parentNavigatorKey: _rootKey,
      builder: (ctx, st) => AnimalDetailScreen(id: st.pathParameters['id']!),
    ),
    GoRoute(
      path: '/chat/:id',
      parentNavigatorKey: _rootKey,
      builder: (ctx, st) => UserChatScreen(animalId: st.pathParameters['id']!),
    ),
    GoRoute(
      path: '/org/chat/:id',
      parentNavigatorKey: _rootKey,
      builder: (ctx, st) => OrgChatScreen(animalId: st.pathParameters['id']!),
    ),
  ],
  redirect: (ctx, st) {
    final role = ctx.read<AppState>().role;
    final loc = st.fullPath ?? '/';
    if (role == null && loc != '/') return '/';
    if (role == UserRole.user && (loc == '/' || loc.startsWith('/o/'))) return '/u/home';
    if (role == UserRole.org  && (loc == '/' || loc.startsWith('/u/'))) return '/o/home';
    return null;
  },
);
