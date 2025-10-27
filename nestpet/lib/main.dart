import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'providers/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // ignore: avoid_print
    print(details.exceptionAsString());
  };

  final state = AppState();
  await state.init(); // garante Hive + boxes ok

  runApp(NestPetApp(state: state));
}

class NestPetApp extends StatelessWidget {
  final AppState state;
  const NestPetApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp.router(
        title: 'NestPet',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5E3C)),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}
