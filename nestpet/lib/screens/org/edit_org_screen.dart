import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditOrgScreen extends StatefulWidget {
  const EditOrgScreen({super.key});

  @override
  State<EditOrgScreen> createState() => _EditOrgScreenState();
}

class _EditOrgScreenState extends State<EditOrgScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('organizations')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (res != null) {
        setState(() {
          _addressCtrl.text = (res['address'] ?? res['morada'] ?? '') as String;
          _hoursCtrl.text = (res['hours'] ?? res['horario'] ?? res['service_hours'] ?? '') as String;
          _phoneCtrl.text = (res['phone'] ?? res['contacts'] ?? res['contact'] ?? '') as String;
          _emailCtrl.text = (res['contact_email'] ?? res['email'] ?? '') as String;
          _websiteCtrl.text = (res['website'] ?? '') as String;
        });
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
      'address': _addressCtrl.text.trim(),
      'hours': _hoursCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'contact_email': _emailCtrl.text.trim(),
      'website': _websiteCtrl.text.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    try {
      final existing = await Supabase.instance.client
          .from('organizations')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (existing == null) {
        await Supabase.instance.client.from('organizations').insert(data);
      } else {
        await Supabase.instance.client.from('organizations').update(data).eq('user_id', user.id);
      }
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
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _hoursCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Instituição')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Morada'),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hoursCtrl,
                decoration: const InputDecoration(labelText: 'Horários de serviço'),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Contacto (telefone)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email de contacto'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _websiteCtrl,
                decoration: const InputDecoration(labelText: 'Website', hintText: "https://www.exemplo.com"),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 220,
                child: FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
