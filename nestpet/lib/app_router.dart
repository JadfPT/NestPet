import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';

// --- AUTH screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/register_user_screen.dart';
import 'screens/auth/register_org_screen.dart';
// reset-by-email/ deep-link screen removed (in-app password change only)
import 'screens/user/user_home_screen.dart';
import 'screens/user/user_favorites_screen.dart';
import 'screens/user/profile_screen.dart';
import 'screens/user/edit_account_screen.dart';
import 'screens/user/animal_detail_screen.dart';
import 'screens/user/chat_screen.dart';
import 'screens/common/messages_screen.dart';

// --- ORG screens
import 'screens/org/my_animals_screen.dart';
import 'screens/org/add_animal_screen.dart';
import 'screens/org/edit_animal_screen.dart';
import 'screens/org/profile_screen.dart';
import 'screens/org/chat_screen.dart';

// Shells de bottom bar (como já tinhas)
class _UserShell extends StatelessWidget {
  final Widget child;
  final String location;
  const _UserShell({required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const pillHeight = 58.0;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // leave space at bottom so content doesn't get hidden by the floating bar
          Padding(padding: EdgeInsets.only(bottom: bottomInset + pillHeight + 20), child: child),

          // bottom floating pill placed above the system inset
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
                  final favActive = loc.startsWith('/u/favorites');
                  final homeActive = loc.startsWith('/u/home');
                  final profActive = loc.startsWith('/u/profile');
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => context.go('/u/favorites'),
                        icon: Icon(favActive ? Icons.star : Icons.star_border),
                        color: Colors.white,
                      ),

                      // center home inside the pill
                      GestureDetector(
                        onTap: () => context.go('/u/home'),
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

                      IconButton(
                        onPressed: () => context.go('/u/profile'),
                        icon: Icon(profActive ? Icons.person : Icons.person_outline),
                        color: Colors.white,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          // no FAB here anymore; home screens will insert an overlay FAB when needed
        ],
      ),
    );
  }
}

class _OrgShell extends StatelessWidget {
  final Widget child;
  final String location;
  const _OrgShell({required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const pillHeight = 58.0;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          Padding(padding: EdgeInsets.only(bottom: bottomInset + pillHeight + 20), child: child),

          // floating pill for org shell above system inset
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
                      IconButton(
                        onPressed: () => context.go('/o/add'),
                        icon: Icon(addActive ? Icons.add_box : Icons.add_box_outlined),
                        color: Colors.white,
                      ),

                      GestureDetector(
                        onTap: () => context.go('/o/home'),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
                          child: Icon(homeActive ? Icons.home : Icons.home_outlined, color: Colors.white, size: 26),
                        ),
                      ),

                      IconButton(
                        onPressed: () => context.go('/o/profile'),
                        icon: Icon(profActive ? Icons.person : Icons.person_outline),
                        color: Colors.white,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          // no FAB here anymore; home screens will insert an overlay FAB when needed
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
  initialLocation: '/welcome',
  routes: [
  GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
  GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
  GoRoute(path: '/register/user', builder: (context, state) => const RegisterUserScreen()),
  GoRoute(path: '/register/org', builder: (context, state) => const RegisterOrgScreenFixed()),
  GoRoute(path: '/messages', builder: (context, state) => const MessagesScreen()),
    // '/auth/reset' route removed — password reset by email disabled

    // USER (shell)
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

    // ORG (shell)
    ShellRoute(
      navigatorKey: _orgShellKey,
      builder: (context, state, child) => _OrgShell(location: state.fullPath ?? '/', child: child),
      routes: [
        GoRoute(path: '/o/home', builder: (context, state) => const MyAnimalsScreen()),
        GoRoute(path: '/o/add', builder: (context, state) => const AddAnimalScreen()),
        GoRoute(path: '/o/edit/:id', builder: (ctx, st) => EditAnimalScreen(id: st.pathParameters['id']!)),
        GoRoute(path: '/o/profile', builder: (context, state) => const OrgProfileScreen()),
      ],
    ),

    // Rotas comuns SEMPRE no root (fora dos shells)
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
  redirect: (ctx, st) {
      final role = ctx.read<AppState>().role;
      final loc = st.fullPath ?? '/';
      // Allow unauthenticated users to visit the welcome and registration screens.
      if (role == null && loc != '/' && loc != '/welcome' && loc != '/register/user' && loc != '/register/org') return '/';
    // If we already have a role restored at startup, allow redirecting from '/' or '/welcome' to the correct shell.
    if (role == UserRole.user && (loc == '/' || loc == '/welcome' || loc.startsWith('/o/'))) return '/u/home';
    if (role == UserRole.org  && (loc == '/' || loc == '/welcome' || loc.startsWith('/u/'))) return '/o/home';
    return null;
  },
);
