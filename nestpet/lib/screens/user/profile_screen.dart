// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_state.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
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
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'suporte@exemplo.com',
      queryParameters: {
        'subject': 'Suporte NestPet',
      },
    );
    launchUrl(emailUri);
  }

  @override
  Widget build(BuildContext context) {
    final supa = Supabase.instance.client.auth.currentUser;
    final email = supa?.email ?? '—';
    final display = context.watch<AppState>().displayName ?? supa?.userMetadata?['displayName'] ?? supa?.userMetadata?['name'] ?? 'Utilizador';
    final primary = Theme.of(context).colorScheme.primary;

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
                              Text('Visão geral', style: TextStyle(fontWeight: FontWeight.w700)),
                              SizedBox(height: 8),
                              Text('A NestPet liga utilizadores a instituições que têm animais para adoção. Podes navegar por animais, favoritar, e enviar mensagens para perguntar ou marcar uma visita.'),
                              SizedBox(height: 12),
                              Text('Principais ações', style: TextStyle(fontWeight: FontWeight.w700)),
                              SizedBox(height: 8),
                              Text('• Ver animais: na página inicial vê cartões com a foto e o nome do animal.'),
                              Text('• Detalhes: toca no cartão para ver galeria, descrição, e informação de contacto.'),
                              Text('• Favoritar: toca na estrela no canto superior do cartão para guardar o animal nos favoritos.'),
                              Text('• Mensagens: usa o ícone de mensagens para comunicar com a instituição sobre um animal.'),
                              SizedBox(height: 12),
                              Text('Conta e perfil', style: TextStyle(fontWeight: FontWeight.w700)),
                              SizedBox(height: 8),
                              Text('• Editar perfil: toca no botão de editar no topo do perfil para alterar o nome ou avatar.'),
                              SizedBox(height: 12),
                              Text('Dicas', style: TextStyle(fontWeight: FontWeight.w700)),
                              SizedBox(height: 8),
                              Text('• Se uma imagem não carregar, tenta novamente mais tarde.'),
                              Text('• Para apagar a conta, utiliza a opção de apagar dentro das definições (será pedido confirmar).'),
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
                              Text('A NestPet compromete-se a proteger a sua privacidade. Esta política explica quais os dados que recolhemos, como os usamos e os seus direitos.'),
                              SizedBox(height: 12),
                              Text('Dados recolhidos', style: TextStyle(fontWeight: FontWeight.w700)),
                              SizedBox(height: 8),
                              Text('• Dados de conta: email, nome de utilizador, avatar (opcional).'),
                              Text('• Dados de interação: mensagens trocadas com instituições, favoritos e anúncios consultados.'),
                              SizedBox(height: 12),
                              Text('Como usamos os dados', style: TextStyle(fontWeight: FontWeight.w700)),
                              SizedBox(height: 8),
                              Text('• Autenticação e gestão da sua conta.'),
                              Text('• Permitir comunicação entre utilizadores e instituições.'),
                              Text('• Melhorias do serviço e análises internas.'),
                              SizedBox(height: 12),
                              Text('Partilha e retenção', style: TextStyle(fontWeight: FontWeight.w700)),
                              SizedBox(height: 8),
                              Text('Não partilhamos os seus dados com terceiros para fins comerciais sem o seu consentimento. Os dados são mantidos enquanto a conta existir e conforme requisitos legais.'),
                              SizedBox(height: 12),
                              Text('Os seus direitos', style: TextStyle(fontWeight: FontWeight.w700)),
                              SizedBox(height: 8),
                              Text('• Aceder, corrigir ou apagar os seus dados mediante pedido.'),
                              Text('• Restringir ou opor-se ao processamento em determinadas circunstâncias.'),
                              SizedBox(height: 12),
                              Text('Contacto', style: TextStyle(fontWeight: FontWeight.w700)),
                              SizedBox(height: 8),
                              Text('Para questões sobre privacidade contacte: privacidade@exemplo.com'),
                            ],
                          ),
                        ),
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
                        if (context.mounted) context.go('/welcome');
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
