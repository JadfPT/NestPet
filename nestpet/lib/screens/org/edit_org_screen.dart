import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/unsaved_changes_guard.dart';

class EditOrgScreen extends StatefulWidget {
  const EditOrgScreen({super.key});

  @override
  State<EditOrgScreen> createState() => _EditOrgScreenState();
}

class _EditOrgScreenState extends State<EditOrgScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  bool _loading = false;

  final Map<String, String> _initialValues = {};

  UnsavedChangesGuard? _guard;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client.from('organizations').select().eq('user_id', user.id).maybeSingle();
      if (res != null) {
        _orgNameCtrl.text = (res['name'] ?? res['nome'] ?? '') as String;
        _addressCtrl.text = (res['address'] ?? res['morada'] ?? '') as String;
        _hoursCtrl.text = (res['hours'] ?? res['horario'] ?? res['service_hours'] ?? '') as String;
        _phoneCtrl.text = (res['phone'] ?? res['contacts'] ?? res['contact'] ?? '') as String;
        _websiteCtrl.text = (res['website'] ?? '') as String;
        _initialValues['name'] = _orgNameCtrl.text;
        _initialValues['address'] = _addressCtrl.text;
        _initialValues['hours'] = _hoursCtrl.text;
        _initialValues['phone'] = _phoneCtrl.text;
        _initialValues['email'] = _emailCtrl.text;
        _initialValues['website'] = _websiteCtrl.text;
        if (mounted) setState(() {});
        _registerGuard();
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final data = {
      'user_id': user.id,
      'name': _orgNameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'hours': _hoursCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'contact_email': _emailCtrl.text.trim(),
      'website': _websiteCtrl.text.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    try {
      final existing = await Supabase.instance.client.from('organizations').select().eq('user_id', user.id).maybeSingle();
      if (existing == null) {
        await Supabase.instance.client.from('organizations').insert(data);
      } else {
        await Supabase.instance.client.from('organizations').update(data).eq('user_id', user.id);
      }
      _initialValues['name'] = _orgNameCtrl.text.trim();
      _initialValues['address'] = _addressCtrl.text.trim();
      _initialValues['hours'] = _hoursCtrl.text.trim();
      _initialValues['phone'] = _phoneCtrl.text.trim();
      _initialValues['email'] = _emailCtrl.text.trim();
      _initialValues['website'] = _websiteCtrl.text.trim();
      _registerGuard();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informações da instituição actualizadas')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao guardar: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _orgNameCtrl.dispose();
    _addressCtrl.dispose();
    _hoursCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    if (_guard != null) {
      UnsavedChangesRegistry.instance.clear(_guard!); // Clear the guard on dispose
    }
    super.dispose();
  }

  bool _hasChanges() {
    if (_initialValues.isEmpty) return false;
    if ((_initialValues['name'] ?? '') != _orgNameCtrl.text) return true;
    if ((_initialValues['address'] ?? '') != _addressCtrl.text) return true;
    if ((_initialValues['hours'] ?? '') != _hoursCtrl.text) return true;
    if ((_initialValues['phone'] ?? '') != _phoneCtrl.text) return true;
    if ((_initialValues['email'] ?? '') != _emailCtrl.text) return true;
    if ((_initialValues['website'] ?? '') != _websiteCtrl.text) return true;
    return false;
  }

  Future<bool> _confirmDiscard() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Alterações não guardadas'),
        content: const Text('Tem alterações não guardadas. Quer descartar e voltar atrás?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Descartar')),
        ],
      ),
    );
    return res == true;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (!_hasChanges()) return true;
        final guard = _guard;
        if (guard == null) return true; // Check if guard is null
        return guard.confirmDiscard(); // Use guard to confirm discard
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Instituição'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final nav = Navigator.of(context);
              final ok = !_hasChanges() ? true : await _confirmDiscard();
              if (!mounted) return;
              if (ok) nav.pop();
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _orgNameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nome da instituição',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Preencha o nome da instituição' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressCtrl,
                          decoration: InputDecoration(
                            labelText: 'Morada',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          minLines: 1,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _hoursCtrl,
                          decoration: InputDecoration(
                            labelText: 'Horários de serviço',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          minLines: 1,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneCtrl,
                          decoration: InputDecoration(
                            labelText: 'Contacto telefónico',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return 'Preencha o contacto (9 dígitos)';
                            final onlyDigits = s.replaceAll(RegExp(r'\D'), '');
                            if (onlyDigits.length != 9) return 'O contacto deve ter exactamente 9 dígitos';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: InputDecoration(
                            labelText: 'Email de contacto',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return null;
                            final at = s.indexOf('@');
                            if (at <= 0) return 'Email inválido';
                            final dot = s.indexOf('.', at);
                            if (dot <= at + 1) return 'Email inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _websiteCtrl,
                          decoration: InputDecoration(
                            labelText: 'Website',
                            hintText: 'https://www.exemplo.com',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          keyboardType: TextInputType.url,
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return null;
                            final uri = Uri.tryParse(s);
                            if (uri == null) return 'Website inválido';
                            if (!(uri.scheme == 'http' || uri.scheme == 'https')) return 'Insira um URL válido';
                            if (uri.host.isEmpty || !uri.host.contains('.')) return 'Website inválido';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                    onPressed: _loading ? null : _save,
                    child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _registerGuard() {
    _guard = UnsavedChangesGuard(
      hasUnsaved: _hasChanges,
      confirmDiscard: _confirmDiscard,
    );
    UnsavedChangesRegistry.instance.register(_guard!);
  }
}
