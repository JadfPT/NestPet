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
          return;
        }
      } catch (_) {}

      final saved = await SessionService.loadRole();
      if (saved != null) state.login(saved == 'org' ? UserRole.org : UserRole.user);
      else state.login(UserRole.user);
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
      background: const Color(0xFFF2E8D7),
      surface: const Color(0xFFF2E8D7),
    );

    return ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp.router(
        title: 'NestPet',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: colorScheme,
          scaffoldBackgroundColor: colorScheme.background,
          useMaterial3: true,
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: colorScheme.background,
            indicatorColor: colorScheme.primary,
            iconTheme: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return IconThemeData(color: colorScheme.background);
              }
              return IconThemeData(color: colorScheme.primary.withOpacity(0.95));
            }),
            labelTextStyle: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return TextStyle(color: colorScheme.background);
              }
              return TextStyle(color: colorScheme.primary.withOpacity(0.95));
            }),
          ),
        ),
        routerConfig: router,
      ),
    );
  }
}
