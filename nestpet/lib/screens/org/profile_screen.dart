// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_state.dart';
import 'edit_org_screen.dart';
import '../user/edit_account_screen.dart';

class OrgProfileScreen extends StatelessWidget {
  const OrgProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supa = Supabase.instance.client.auth.currentUser;
    final email = supa?.email ?? '—';
    final display = context.watch<AppState>().displayName ?? supa?.userMetadata?['displayName'] ?? supa?.userMetadata?['name'] ?? 'Instituição';
    final primary = Theme.of(context).colorScheme.primary;

    final orgFuture = () async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;
      final org = await Supabase.instance.client.from('organizations').select().eq('user_id', user.id).maybeSingle();
      return org;
    }();

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil da Instituição')),
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
                        child: imageProvider == null ? Text(display.isNotEmpty ? display[0].toUpperCase() : 'I', style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 20)) : null,
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
                    IconButton(onPressed: () async {
                      final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditAccountScreen()));
                      if (res == true) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
                      }
                    }, icon: const Icon(Icons.edit_outlined), tooltip: 'Editar conta'),
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
                  FutureBuilder<dynamic>(
                    future: orgFuture,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.info_outline),
                            title: const Text('Detalhes'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              // Open edit screen for organization details
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditOrgScreen()));
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.delete_forever),
                            title: const Text('Apagar conta'),
                            subtitle: const Text('Ação irreversível'),
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funcionalidade por implementar'))),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('Terminar sessão'),
                            onTap: () {
                              context.read<AppState>().logout();
                              context.go('/');
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
