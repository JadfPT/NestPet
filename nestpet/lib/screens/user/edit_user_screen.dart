import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../widgets/avatar_picker.dart';

class EditUserScreen extends StatefulWidget {
  const EditUserScreen({super.key});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  bool _saving = false;
  late String _initialName;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['displayName'] ?? user?.userMetadata?['name'] ?? '';
    _nameCtrl = TextEditingController(text: name);
    _initialName = name;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    if (!_formKey.currentState!.validate()) return false;
    // perform save
    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'displayName': name, 'name': name}));
      if (context.mounted) {
        try {
          context.read<AppState>().setDisplayName(name);
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado')));
      }
      _initialName = name;
      return true;
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar: $e')));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _onWillPop() async {
    final current = _nameCtrl.text.trim();
    final dirty = current != _initialName;
    if (!dirty) return true;

    final choice = await showDialog<int>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Alterações não guardadas'),
        content: const Text('Tens alterações por guardar. Queres guardar ou descartar estas alterações?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, 0), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, 2), child: const Text('Descartar')),
          FilledButton(onPressed: () => Navigator.pop(c, 1), child: const Text('Guardar')),
        ],
      ),
    );

    if (choice == 0 || choice == null) return false;
    if (choice == 2) return true;
    if (choice == 1) {
      final ok = await _save();
      return ok;
    }
    return true;
  }

  Future<void> _requestDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Apagar conta'),
        content: const Text('Tens a certeza que queres apagar a tua conta? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido de apagamento enviado')));
      context.read<AppState>().logout();
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _uploadAvatar(File? file) async {
    if (file == null) {
      try {
        await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'avatar_url': ''}));
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          try {
            await Supabase.instance.client.from('profiles').update({'avatar_url': []}).eq('id', userId);
          } catch (_) {}
        }
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar removido')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro a remover avatar: $e')));
      }
      return;
    }

    final current = Supabase.instance.client.auth.currentUser;
    if (current == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('É necessário iniciar sessão para alterar avatar')));
      return;
    }

    setState(() => _saving = true);
    try {
      final bytes = await file.readAsBytes();
      final userId = current.id;
      final fileName = file.path.split(Platform.pathSeparator).last;
      final dest = 'users/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await Supabase.instance.client.storage.from('avatars').uploadBinary(dest, bytes, fileOptions: FileOptions(cacheControl: '3600'));
      final publicUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(dest);
      await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'avatar_url': publicUrl}));
      // persist avatar url in profiles table: try update first (avoids INSERT blocked by RLS)
      try {
        final userId = current.id;
        final updateRes = await Supabase.instance.client.from('profiles').update({
          'avatar_url': [publicUrl],
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', userId);
        if (updateRes == null || (updateRes is List && updateRes.isEmpty)) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar enviado mas não foi possível atualizar a tabela profiles: registo não encontrado. Executa o script de populaçao no Supabase.')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar profiles: $e')));
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar atualizado')));
    } catch (e) {
      final msg = e.toString();
      if (msg.toLowerCase().contains('bucket not found') || msg.contains('statusCode: 404')) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao enviar avatar: bucket 'avatars' não encontrado. Cria um bucket 'avatars' no Supabase Storage ou atualiza o nome do bucket no código.")));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao enviar avatar: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final display = user?.userMetadata?['displayName'] ?? user?.userMetadata?['name'] ?? '';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text('Editar conta')),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Center(child: AvatarPicker(imageUrl: avatarUrl, initials: display.isNotEmpty ? display[0] : 'U', radius: 52, onImage: (file) => _uploadAvatar(file))),
                      const SizedBox(height: 12),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(labelText: 'Nome de utilizador'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Preenche o nome' : null,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _saving
                                    ? null
                                    : () async {
                                        final ok = await _save();
                                        if (ok && context.mounted) Navigator.pop(context);
                                      },
                                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), padding: const EdgeInsets.symmetric(vertical: 14)),
                                child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar mudanças'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Alterar password'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  onPressed: _requestDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: const Text('Apagar conta', style: TextStyle(color: Colors.redAccent)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
