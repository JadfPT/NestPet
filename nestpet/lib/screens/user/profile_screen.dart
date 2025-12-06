// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_state.dart';
import '../../services/session_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    // load saved notifications preference
    SessionService.loadNotificationsEnabled().then((v) {
      if (v != null) setState(() => _notificationsEnabled = v);
    }).catchError((_) {});
  }

  Future<bool?> _confirm(BuildContext ctx, String title, String body) {
    return showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirmar')),
        ],
      ),
    );
  }

  void _contactSupport() {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Contactar Suporte'),
        content: const Text('Envia um email para suporte@exemplo.com ou descreve o problema. (Placeholder)'),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supa = Supabase.instance.client.auth.currentUser;
    final email = supa?.email ?? '—';
    final display = context.watch<AppState>().displayName ?? supa?.userMetadata?['displayName'] ?? supa?.userMetadata?['name'] ?? 'Utilizador';
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Builder(builder: (c) {
                      final meta = supa?.userMetadata;
                      dynamic raw = meta != null ? meta['avatar_url'] : null;
                      String? avatarUrl;
                      if (raw is String && raw.isNotEmpty) avatarUrl = raw;
                      if (raw is List && raw.isNotEmpty) {
                        final first = raw.first;
                        if (first is String && first.isNotEmpty) avatarUrl = first;
                      }
                      final imageProvider = (avatarUrl != null) ? NetworkImage(avatarUrl) : null;
                      return CircleAvatar(
                        radius: 28,
                        backgroundColor: primary.withAlpha((0.18*255).round()),
                        foregroundImage: imageProvider as ImageProvider<Object>?,
                        child: imageProvider == null ? Text(display.isNotEmpty ? display[0].toUpperCase() : 'U', style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 20)) : null,
                      );
                    }),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(display, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(email, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => context.push('/u/edit'), icon: const Icon(Icons.edit_outlined), tooltip: 'Editar perfil'),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Ajuda'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Ajuda'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('FAQ'),
                              SizedBox(height: 8),
                              Text('• Como posso reportar um animal?'),
                              Text(' - Vai a Página de organização e preenche o formulário.'),
                              SizedBox(height: 6),
                              Text('• Como altero os meus dados?'),
                              Text(' - Toca no botão de editar no cabeçalho do perfil.'),
                            ],
                          ),
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar'))],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Preferências'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/u/edit'),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _notificationsEnabled,
                    onChanged: (v) async {
                      setState(() => _notificationsEnabled = v);
                      try {
                        await SessionService.saveNotificationsEnabled(v);
                      } catch (_) {}
                    },
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Notificações'),
                    subtitle: const Text('Receber notificações relacionadas com animais e mensagens'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Privacidade'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Privacidade'),
                        content: const SingleChildScrollView(child: Text('A política de privacidade será aqui exibida. (Placeholder)')),
                        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar'))],
                      ),
                    ),
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.support_agent_outlined),
                    title: const Text('Contactar suporte'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _contactSupport,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_outlined),
                    title: const Text('Terminar sessão'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final ok = await _confirm(context, 'Terminar sessão', 'Queres mesmo terminar a sessão?');
                      if (ok == true) {
                        context.read<AppState>().logout();
                        if (context.mounted) context.go('/');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('App', style: Theme.of(context).textTheme.titleSmall)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Versão'),
                subtitle: Text('1.0.0'),
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
