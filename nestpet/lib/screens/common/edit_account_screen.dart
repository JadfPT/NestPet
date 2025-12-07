// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../widgets/avatar_picker.dart';
import '../../widgets/change_password_flow.dart';
import '../../utils/unsaved_changes_guard.dart';

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  bool _saving = false;
  late String _initialName;
  bool _isOrg = false;
  UnsavedChangesGuard? _guard;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['displayName'] ?? user?.userMetadata?['name'] ?? '';
    _nameCtrl = TextEditingController(text: name);
    _initialName = name;
    _maybeLoadOrgName();
    _registerGuard();
  }

  Future<void> _maybeLoadOrgName() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final org = await Supabase.instance.client.from('organizations').select().eq('user_id', user.id).maybeSingle();
      if (org != null) {
        _isOrg = true;
        final orgName = (org['name'] ?? org['nome'] ?? '').toString();
        // Only use org name as a fallback when there is no display name saved
        if (_nameCtrl.text.trim().isEmpty && orgName.isNotEmpty) {
          _nameCtrl.text = orgName;
          _initialName = orgName;
        }
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_guard != null) {
      UnsavedChangesRegistry.instance.clear(_guard!);
    }
    _nameCtrl.dispose();
    super.dispose();
  }

  void _registerGuard() {
    _guard = UnsavedChangesGuard(
      hasUnsaved: () => _nameCtrl.text.trim() != _initialName,
      confirmDiscard: () async {
        final choice = await showDialog<int>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Alterações não guardadas'),
            content: const Text('Tem alterações por guardar. Quer guardar ou descartar essas alterações?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, 0), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(c, 2), child: const Text('Descartar')),
              FilledButton(onPressed: () => Navigator.pop(c, 1), child: const Text('Guardar')),
            ],
          ),
        );
        if (choice == 0 || choice == null) return false;
        if (choice == 2) return true;
        if (choice == 1) return await _save();
        return false;
      },
    );
    UnsavedChangesRegistry.instance.register(_guard!);
  }

  Future<bool> _save() async {
    if (!_formKey.currentState!.validate()) return false;
    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'displayName': name, 'name': name}));
      // try to persist into profiles (may be blocked by RLS)
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await Supabase.instance.client.from('profiles').update({'username': name, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', userId);
        }
      } catch (_) {}
      if (context.mounted) {
        try {
          context.read<AppState>().setDisplayName(name);
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado')));
      }
      _initialName = name;
      _registerGuard();
      return true;
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar: $e')));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
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
      try {
        await Supabase.instance.client.from('profiles').update({'avatar_url': [publicUrl], 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', userId);
      } catch (_) {}
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar atualizado')));
    } catch (e) {
      final msg = e.toString();
      if (msg.toLowerCase().contains('bucket not found') || msg.contains('statusCode: 404')) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao enviar avatar: bucket 'avatars' não encontrado. Contacte o suporte.")));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao enviar avatar: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _requestDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Apagar conta'),
        content: const Text('Tem a certeza que quer apagar a sua conta? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (ok != true) return;

    final client = Supabase.instance.client;
    // Ask for password to confirm identity before deleting account
    final password = await showDialog<String?>(
      context: context,
      builder: (c) {
        final TextEditingController pwdCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Confirme a password'),
          content: TextField(
            controller: pwdCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, null), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(c, pwdCtrl.text), child: const Text('Confirmar')),
          ],
        );
      },
    );
    if (password == null || password.isEmpty) return;

    // Re-authenticate by signing in with email + password. If this fails,
    // abort the delete operation.
    final email = client.auth.currentUser?.email;
    if (email == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro: utilizador não autenticado')));
      return;
    }
    try {
      // Attempt sign-in with password to verify credentials. This will replace
      // the current session with a fresh session if successful, which is fine
      // since we're about to remove the account.
      await client.auth.signInWithPassword(email: email, password: password);
      // Confirm session updated
      final currentEmail = client.auth.currentUser?.email;
      if (currentEmail == null || currentEmail != email) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password inválida')));
        return;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password inválida')));
      return;
    }
    // Try calling the server-side RPC which deletes the authenticated user's data
    // and the corresponding auth.users entry. This function must be created in
    // Supabase SQL Editor as an admin (see db/migrations/0003_remove_account_rpc.sql).
    try {
      // Try to invoke server RPC (created with admin privileges) to remove
      // the authenticated user's account and related rows.
      final rpcRes = await client.rpc('remove_account_and_data').select();
      // rpcRes might be a PostgrestResponse or dynamic. Check for an error
      // in a defensive way and run fallback if present.
      dynamic rpcError;
      try {
        rpcError = (rpcRes as dynamic).error;
      } catch (_) {
        rpcError = null;
      }
      if (rpcError != null) {
        // run fallback deletes silently
        try {
          final uid = client.auth.currentUser?.id;
          if (uid != null) {
            await client.from('animals').delete().eq('org_id', uid);
            await client.from('favorites').delete().eq('user_id', uid);
            await client.from('typing_status').delete().eq('user_id', uid);
            await client.from('messages').delete().eq('user_id', uid);
            await client.from('organizations').delete().eq('user_id', uid);
            await client.from('profiles').delete().eq('id', uid);
          }
        } catch (e) {
          // swallow but log
          // ignore: avoid_print
          print('Fallback delete error: $e');
        }
      }
    } catch (e) {
      // If RPC invocation itself throws, attempt best-effort deletes locally
      try {
        final uid = client.auth.currentUser?.id;
        if (uid != null) {
          await client.from('animals').delete().eq('org_id', uid);
          await client.from('favorites').delete().eq('user_id', uid);
          await client.from('typing_status').delete().eq('user_id', uid);
          await client.from('messages').delete().eq('user_id', uid);
          await client.from('organizations').delete().eq('user_id', uid);
          await client.from('profiles').delete().eq('id', uid);
        }
      } catch (e2) {
        // ignore: avoid_print
        print('Fallback delete error after exception: $e2');
      }
    }

    // Finally sign out locally
    try {
      await client.auth.signOut();
    } catch (_) {}

    if (context.mounted) {
      try {
        context.read<AppState>().logout();
      } catch (_) {}
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final display = user?.userMetadata?['displayName'] ?? user?.userMetadata?['name'] ?? '';

    // WillPopScope deprecated; suppress info until further migration to PopScope
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        final current = _nameCtrl.text.trim();
        final dirty = current != _initialName;
        if (!dirty) return true;
        final guard = _guard;
        if (guard == null) return true;
        return guard.confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Editar conta')),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Center(child: AvatarPicker(imageUrl: avatarUrl, initials: _isOrg ? 'I' : (display.isNotEmpty ? display[0] : 'U'), radius: 52, onImage: (file) => _uploadAvatar(file))),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(children: [
                      TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nome de utilizador'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Preenche o nome' : null),
                      const SizedBox(height: 16),
                      SizedBox(width: double.infinity, child: FilledButton(onPressed: _saving ? null : () async { final ok = await _save(); if (ok && context.mounted) Navigator.pop(context); }, style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), padding: const EdgeInsets.symmetric(vertical: 14)), child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar mudanças'))),
                    ]),
                  ),
                ]),
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
                onPressed: () => ChangePasswordFlow.show(context),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Alterar password'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), side: const BorderSide(color: Colors.redAccent)), onPressed: _requestDelete, icon: const Icon(Icons.delete_outline, color: Colors.redAccent), label: const Text('Apagar conta', style: TextStyle(color: Colors.redAccent)))),
          ]),
        ),
      ),
    );
  }
}
