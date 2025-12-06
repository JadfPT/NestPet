// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state.dart';
import 'edit_org_screen.dart';
import '../common/edit_account_screen.dart';

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

    void contactSupport() {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'suporte@exemplo.com',
        queryParameters: {'subject': 'Suporte NestPet'},
      );
      launchUrl(emailUri);
    }

    return Scaffold(
      appBar: AppBar(title: Text('Perfil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),),
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
                            leading: const Icon(Icons.help_outline),
                            title: const Text('Ajuda'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => showDialog<void>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Ajuda para Instituições'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text('Como gerir a sua instituição', style: TextStyle(fontWeight: FontWeight.w700)),
                                      SizedBox(height: 8),
                                      Text('• Adicionar/editar animais: usa o botão "Adicionar animal" para publicar um novo anúncio. Em cada cartão pode editar ou apagar o anúncio.'),
                                      Text('• Media: adicione fotos e vídeos para melhorar o anúncio. Suportamos imagens e vídeos curtos.'),
                                      Text('• Mensagens: as mensagens chegadas são mostradas na secção de mensagens; responde para combinar visitas ou fornecer mais informações.'),
                                      SizedBox(height: 8),
                                      Text('• Favoritos: os utilizadores podem favoritar animais; verás essas interacções para priorizar contactos.'),
                                      SizedBox(height: 8),
                                      Text('• Perfil da instituição: atualiza morada, horários e contactos em "Detalhes" para que os utilizadores vejam as informações corretas.'),
                                      SizedBox(height: 8),
                                      Text('• Apagar conta: se precisares apagar a conta, contacta o suporte ou segue a opção de eliminação disponível nas definições de conta (esta ação remove os registos associados).'),
                                    ],
                                  ),
                                ),
                                actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar'))],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.lock_outline),
                            title: const Text('Privacidade'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => showDialog<void>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Política de Privacidade'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text('Introdução', style: TextStyle(fontWeight: FontWeight.w700)),
                                      SizedBox(height: 8),
                                      Text('A NestPet recolhe dados necessários para o funcionamento: email, nome da instituição, contactos, anúncios e media publicados.'),
                                      SizedBox(height: 8),
                                      Text('Utilização dos dados:'),
                                      Text('• Gestão de anúncios e comunicação com utilizadores.'),
                                      Text('• Melhoria de serviço e análise interna.'),
                                      SizedBox(height: 8),
                                      Text('Partilha:'),
                                      Text('Os dados da instituição relacionados com anúncios são visíveis a utilizadores interessados. Não partilhamos dados sensíveis sem consentimento.'),
                                      SizedBox(height: 8),
                                      Text('Contacto:'),
                                      Text('Para questões sobre privacidade contacte: privacidade@exemplo.com'),
                                    ],
                                  ),
                                ),
                                actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar'))],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.support_agent_outlined),
                            title: const Text('Contactar suporte'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: contactSupport,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('Terminar sessão'),
                            onTap: () {
                              context.read<AppState>().logout();
                              context.go('/welcome');
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
                subtitle: const Text('1.0.0'),
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
