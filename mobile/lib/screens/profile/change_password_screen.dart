import 'package:flutter/material.dart';

import '../../api/moov_api.dart';
import '../../widgets/common.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await MoovApi.changePassword(_old.text, _new.text);
      if (!mounted) return;
      showSnack(context, 'Mot de passe modifié.');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            TextFormField(
              controller: _old,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mot de passe actuel'),
              validator: (v) => (v ?? '').isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _new,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nouveau mot de passe', helperText: '8 caractères minimum.'),
              validator: (v) => (v ?? '').length < 8 ? '8 caractères minimum.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmer le nouveau mot de passe'),
              validator: (v) => v != _new.text ? 'Les mots de passe ne correspondent pas.' : null,
            ),
            const SizedBox(height: 24),
            MoovButton(label: 'Modifier le mot de passe', loading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
