import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'app_router.dart';
import 'providers/app_state.dart';

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
  // Inicialização assíncrona do estado da app — não bloquear a UI na abertura
  state.init().catchError((e, st) {
    // ignore: avoid_print
    print('AppState.init error: $e');
    // ignore: avoid_print
    print(st);
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
