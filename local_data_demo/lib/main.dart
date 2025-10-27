import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notes/notes_page.dart';
import 'notes/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _darkMode = prefs.getBool('darkMode') ?? false);
  }

  Future<void> _setDarkMode(bool v) async {
    setState(() => _darkMode = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', v);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mini App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      // Builder para obter um context com Navigator
      home: Builder(
        builder: (ctx) => SplashPage(
          onContinue: () => Navigator.of(ctx).pushReplacement(
            MaterialPageRoute(
              builder: (_) => _HomeShell(
                darkMode: _darkMode,
                onToggleDarkMode: _setDarkMode,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shell com 2 tabs: Definições (SharedPreferences) e Notas (SQLite)
class _HomeShell extends StatelessWidget {
  const _HomeShell({
    required this.darkMode,
    required this.onToggleDarkMode,
  });

  final bool darkMode;
  final ValueChanged<bool> onToggleDarkMode;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mini App'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.settings), text: 'Definições'),
              Tab(icon: Icon(Icons.note_alt_outlined), text: 'Notas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PrefsPage(
              darkMode: darkMode,
              onToggleDarkMode: onToggleDarkMode,
            ),
            const NotesPage(),
          ],
        ),
      ),
    );
  }
}

/// Página simples de preferências (username + modo escuro)
class _PrefsPage extends StatefulWidget {
  const _PrefsPage({
    required this.darkMode,
    required this.onToggleDarkMode,
  });

  final bool darkMode;
  final ValueChanged<bool> onToggleDarkMode;

  @override
  State<_PrefsPage> createState() => _PrefsPageState();
}

class _PrefsPageState extends State<_PrefsPage> {
  final _controller = TextEditingController();
  String _username = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? '';
    _controller.text = _username;
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    _username = _controller.text.trim();
    await prefs.setString('username', _username);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferências guardadas')),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile.adaptive(
          title: const Text('Modo escuro'),
          value: widget.darkMode,
          onChanged: widget.onToggleDarkMode,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Nome do utilizador',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
        ),
        const SizedBox(height: 8),
        Text('Atual: ${_username.isEmpty ? "—" : _username}'),
      ],
    );
  }
}
