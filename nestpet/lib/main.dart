// Propósito geral: Ponto de entrada da aplicação NestPet. Inicializa serviços essenciais
// (Flutter, Supabase, estado da app, deep links), configura tratamento de erros e
// arranca a UI com tema e roteamento.
// Observações:
// - A inicialização do Supabase deve ocorrer antes de usar o cliente.
// - O listener de estado de autenticação ajusta o papel do utilizador (org/utilizador)
//   e sincroniza dados iniciais.
// - Os deep links (esquema nestpet://) são tratados para navegar para ecrãs específicos.

// Importações do Flutter e pacotes usados na app.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'supabase_config.dart';
import 'app_router.dart';
import 'providers/app_state.dart';
import 'services/session_service.dart';

// Função principal (entrypoint). Prepara bindings, inicializa Supabase e arranca a app.
void main() async {
  // Garante que o Flutter está pronto para operações assíncronas e plugins.
  WidgetsFlutterBinding.ensureInitialized();
    // Inicializa o cliente Supabase com URL e chave pública (anon).
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

  // Tratamento global de erros Flutter para registar/exibir problemas.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // ignore: avoid_print
    print(details.exceptionAsString());
  };

  // Cria estado global da aplicação e corre a inicialização (carrega dados necessários).
  final state = AppState();
  try {
    await state.init();
  } catch (e, st) {
    // ignore: avoid_print
    print('AppState.init error: $e');
    // ignore: avoid_print
    print(st);
  }

  // Listener de alterações do estado de autenticação.
  // Quando o utilizador faz login/logout, ajusta o papel (org/utilizador)
  // e atualiza a lista de animais.
  Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final meta = user.userMetadata;
        final serverRole = meta != null && meta['role'] != null ? meta['role'] as String? : null;
        if (serverRole != null) {
          // Se o servidor já conhece o papel, aplica-o diretamente.
          state.login(serverRole == 'org' ? UserRole.org : UserRole.user);
          try {
            await state.animals.refresh();
          } catch (_) {}
          return;
        }
      } catch (_) {}

      // Caso não haja papel definido no servidor, tenta recuperar do armazenamento local.
      final saved = await SessionService.loadRole();
      if (saved != null && saved == 'org') {
        try {
          final orgInfo = await SessionService.loadOrgInfo();
          final name = orgInfo['name'];
          final nif = orgInfo['nif'];

          try {
            // Atualiza metadados do utilizador com papel e opcionalmente NIF.
            await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'role': 'org', if (nif != null) 'nif': nif}));
          } catch (e) {
            //ignorar
          }

          try {
            // Insere/atualiza a organização associada ao utilizador.
            final insertData = <String, dynamic>{'name': name ?? 'Unnamed'};
            if (nif != null) insertData['nif'] = nif;
            insertData['user_id'] = user.id;
            await Supabase.instance.client.from('organizations').insert(insertData);
            await SessionService.clearOrgInfo();
          } catch (e) {
            //ignorar
          }

        } catch (_) {}

        // Define papel como organização e atualiza animais.
        state.login(UserRole.org);
        try {
          await state.animals.refresh();
        } catch (_) {}
      } else if (saved != null) {
        // Recupera papel guardado (org/user) e atualiza animais.
        state.login(saved == 'org' ? UserRole.org : UserRole.user);
        try {
          await state.animals.refresh();
        } catch (_) {}
        
      } else {
        // Por omissão, papel de utilizador normal.
        state.login(UserRole.user);
      }
    }
  });

  // Inicializa tratamento de deep links (ligações externas que abrem rotas internas).
  _initDeepLinks();

  // Arranca a aplicação Flutter com o estado preparado.
  runApp(NestPetApp(state: state));
}

// Configura o gestor de deep links: trata link inicial e escuta links em runtime.
void _initDeepLinks() async {
  final appLinks = AppLinks();
  
  try {
    final uri = await appLinks.getInitialLink();
    if (uri != null) {
      _handleDeepLink(uri);
    }
  } catch (_) {}

  appLinks.uriLinkStream.listen((uri) {
    _handleDeepLink(uri);
  });
}

// Interpreta um URI de deep link e navega para a rota correspondente.
void _handleDeepLink(Uri uri) {
  if (uri.scheme == 'nestpet' && uri.host == 'welcome') {
    router.go('/welcome');
  }
}

// Widget raiz da app. Fornece estado com Provider e configura tema e router.
class NestPetApp extends StatelessWidget {
  final AppState state;
  const NestPetApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {

      // Define esquema de cores baseado numa cor de semente, ajustando primária e surface.
      final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF824822)).copyWith(
        primary: const Color(0xFF824822),
        surface: const Color(0xFFF2E8D7),
      );

      // Injeta o estado global e configura MaterialApp com tema e roteamento.
      return ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp.router(
          title: 'NestPet',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: colorScheme,
            scaffoldBackgroundColor: colorScheme.surface,
            useMaterial3: true,
            // Personaliza NavigationBar (ícones/labels) conforme estado selecionado.
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
