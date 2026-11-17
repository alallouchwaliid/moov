import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Validation du téléphone marocain : 9 chiffres après +212, commençant par 6 ou 7.
String? validateMoroccanPhone(String? v, {bool required = false}) {
  final digits = (v ?? '').replaceAll(' ', '');
  if (digits.isEmpty) return required ? 'Numéro obligatoire.' : null;
  if (digits.startsWith('0')) return 'Retirez le 0 au début : saisissez les 9 chiffres après +212.';
  if (!RegExp(r'^[67]\d{8}$').hasMatch(digits)) {
    return 'Numéro incomplet. Saisissez 9 chiffres après +212, commençant par 6 ou 7.';
  }
  return null;
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _role = 'student';
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = _phone.text.replaceAll(' ', '');
      await context.read<AuthProvider>().register({
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        'email': _email.text.trim().toLowerCase(),
        'phone': phone.isEmpty ? '' : '+212$phone',
        'role': _role,
        'password': _password.text,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rejoignez la communauté MOOV de votre campus.',
                    style: TextStyle(fontSize: 16, color: MoovColors.muted)),
                const SizedBox(height: 22),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _first,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Prénom'),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _last,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
                    ),
                  ),
                ]),
                gap,
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Adresse email', prefixIcon: Icon(Icons.mail_outline)),
                  validator: (v) =>
                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Adresse email invalide.',
                ),
                gap,
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                    prefixText: '+212 ',
                    helperText: '9 chiffres après +212, sans le premier 0.',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: validateMoroccanPhone,
                ),
                gap,
                const Text('Vous êtes', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'student', label: Text('Étudiant(e)'), icon: Icon(Icons.school_outlined)),
                    ButtonSegment(value: 'staff', label: Text('Personnel'), icon: Icon(Icons.badge_outlined)),
                  ],
                  selected: {_role},
                  onSelectionChanged: (s) => setState(() => _role = s.first),
                ),
                gap,
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    helperText: '8 caractères minimum, pas uniquement des chiffres.',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v ?? '').length < 8 ? '8 caractères minimum.' : null,
                ),
                gap,
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  decoration:
                      const InputDecoration(labelText: 'Confirmer le mot de passe', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => v != _password.text ? 'Les mots de passe ne correspondent pas.' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: MoovColors.red)),
                ],
                const SizedBox(height: 24),
                MoovButton(label: 'Créer mon compte', icon: Icons.arrow_forward, loading: _loading, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
