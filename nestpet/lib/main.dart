import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'app_router.dart';
import 'providers/app_state.dart';
import 'services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    // Inicializa Supabase: preencha `lib/supabase_config.dart` com as suas chaves.
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // ignore: avoid_print
    print(details.exceptionAsString());
  };

  final state = AppState();
  // Inicialização do estado da app — aguardamos para restaurar sessão antes de construir a UI
  try {
    await state.init();
  } catch (e, st) {
    // ignore: avoid_print
    print('AppState.init error: $e');
    // ignore: avoid_print
    print(st);
  }

  // Also listen for Supabase auth state changes and restore role if a session appears.
  Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // prefer server metadata role
      try {
        final meta = user.userMetadata;
        final serverRole = meta != null && meta['role'] != null ? meta['role'] as String? : null;
        if (serverRole != null) {
          state.login(serverRole == 'org' ? UserRole.org : UserRole.user);
          try {
            await state.animals.refresh();
          } catch (_) {}
          return;
        }
      } catch (_) {}

      // If server didn't provide role, attempt to sync from locally saved info
      // (this is useful when the user registered on this device but server
      // metadata hasn't been set yet). If saved role indicates 'org', try to
      // update server metadata and create a row in `organizations`.
      final saved = await SessionService.loadRole();
      if (saved != null && saved == 'org') {
        // Attempt to update user metadata and create organization row.
        try {
          final orgInfo = await SessionService.loadOrgInfo();
          final name = orgInfo['name'];
          final nif = orgInfo['nif'];

          // Update user metadata on Supabase (if supported by client)
          try {
            await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'role': 'org', if (nif != null) 'nif': nif}));
          } catch (e) {
            // ignore errors updating metadata (not all supabase clients support it the same way)
          }

          // Insert into organizations table, link using user.id if schema supports it
          try {
            final insertData = <String, dynamic>{'name': name ?? 'Unnamed'};
            if (nif != null) insertData['nif'] = nif;
            // include user_id where possible
            insertData['user_id'] = user.id;
            await Supabase.instance.client.from('organizations').insert(insertData);
            // cleanup local org info after successful sync
            await SessionService.clearOrgInfo();
          } catch (e) {
            // if insert fails (e.g., schema doesn't have user_id/nif), ignore
          }

        } catch (_) {}

        // Finally restore local role so UI switches to org shell immediately
        state.login(UserRole.org);
        try {
          await state.animals.refresh();
        } catch (_) {}
      } else if (saved != null) {
        state.login(saved == 'org' ? UserRole.org : UserRole.user);
        try {
          await state.animals.refresh();
        } catch (_) {}
        
      } else {
        state.login(UserRole.user);
      }
    }
  });
  runApp(NestPetApp(state: state));
}

class NestPetApp extends StatelessWidget {
  final AppState state;
  const NestPetApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
      // Definindo esquema de cores fixo conforme solicitado:
      // Cor principal: #824822 -> 0xFF824822
      // Cor de fundo: #F2E8D7 -> 0xFFF2E8D7
      final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF824822)).copyWith(
        primary: const Color(0xFF824822),
        surface: const Color(0xFFF2E8D7),
      );

      return ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp.router(
          title: 'NestPet',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: colorScheme,
            scaffoldBackgroundColor: colorScheme.surface,
            useMaterial3: true,
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: colorScheme.surface,
              indicatorColor: colorScheme.primary,
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return IconThemeData(color: colorScheme.surface);
                }
                return IconThemeData(color: colorScheme.primary.withAlpha((0.95*255).round()));
              }),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(color: colorScheme.surface);
                }
                return TextStyle(color: colorScheme.primary.withAlpha((0.95*255).round()));
              }),
            ),
          ),
          routerConfig: router,
        ),
      );
    }
  }
