import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notes/notes_page.dart';

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
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _username = prefs.getString('username') ?? '';
    });
  }

  Future<void> _updateDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    setState(() => _darkMode = value);
  }

  Future<void> _updateUsername(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', value);
    setState(() => _username = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Data Demo',
      theme: ThemeData(
        colorScheme:
            _darkMode ? const ColorScheme.dark() : const ColorScheme.light(),
        useMaterial3: true,
      ),
      home: HomePage(
        darkMode: _darkMode,
        onToggleDarkMode: _updateDarkMode, // pode devolver Future, o onChanged ignora o retorno
        username: _username,
        onUpdateUsername: _updateUsername, // agora é Future<void> Function(String)
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final bool darkMode;
  final Future<void> Function(bool) onToggleDarkMode;
  final String username;
  final Future<void> Function(String) onUpdateUsername;

  const HomePage({
    super.key,
    required this.darkMode,
    required this.onToggleDarkMode,
    required this.username,
    required this.onUpdateUsername,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      PreferencesPage(
        darkMode: widget.darkMode,
        onToggleDarkMode: widget.onToggleDarkMode,
        username: widget.username,
        onUpdateUsername: widget.onUpdateUsername,
      ),
      const NotesPage(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de dados locais')),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.settings), label: 'Preferências'),
        NavigationDestination(icon: Icon(Icons.note), label: 'Notas'),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

class PreferencesPage extends StatefulWidget {
  final bool darkMode;
  final Future<void> Function(bool) onToggleDarkMode;
  final String username;
  final Future<void> Function(String) onUpdateUsername;

  const PreferencesPage({
    super.key,
    required this.darkMode,
    required this.onToggleDarkMode,
    required this.username,
    required this.onUpdateUsername,
  });

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.username);
  }

  // Mantém o TextField sincronizado se o username vindo de cima mudar
  @override
  void didUpdateWidget(covariant PreferencesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username &&
        _controller.text != widget.username) {
      _controller.text = widget.username;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus(); // fecha teclado
    await widget.onUpdateUsername(_controller.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nome guardado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Modo escuro'),
            value: widget.darkMode,
            onChanged: (v) => widget.onToggleDarkMode(v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Nome do utilizador',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Guardar nome'),
          ),
          const SizedBox(height: 8),
          Text('Atual: ${widget.username.isEmpty ? "—" : widget.username}'),
        ],
      ),
    );
  }
}
