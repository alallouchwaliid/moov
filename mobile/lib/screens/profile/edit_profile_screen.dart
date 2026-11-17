import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../widgets/common.dart';
import '../auth/register_screen.dart' show validateMoroccanPhone;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _first, _last, _phone, _city, _university, _bio;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user!;
    _first = TextEditingController(text: u.firstName);
    _last = TextEditingController(text: u.lastName);
    _phone = TextEditingController(text: u.phone.startsWith('+212') ? u.phone.substring(4) : u.phone);
    _city = TextEditingController(text: u.city);
    _university = TextEditingController(text: u.university);
    _bio = TextEditingController(text: u.bio);
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _city, _university, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final phone = _phone.text.replaceAll(' ', '');
      await context.read<AuthProvider>().updateProfile({
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        'phone': phone.isEmpty ? '' : '+212$phone',
        'city': _city.text.trim(),
        'university': _university.text.trim(),
        'bio': _bio.text.trim(),
      });
      if (!mounted) return;
      showSnack(context, 'Profil mis à jour.');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier mon profil')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _first,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _last,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Obligatoire' : null,
                ),
              ),
            ]),
            gap,
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixText: '+212 ',
                prefixIcon: Icon(Icons.phone_outlined),
                helperText: 'Visible uniquement par vos passagers / conducteurs confirmés.',
              ),
              validator: validateMoroccanPhone,
            ),
            gap,
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Ville', prefixIcon: Icon(Icons.location_city_outlined)),
            ),
            gap,
            TextFormField(
              controller: _university,
              decoration: const InputDecoration(labelText: 'Université / campus', prefixIcon: Icon(Icons.school_outlined)),
            ),
            gap,
            TextFormField(
              controller: _bio,
              maxLength: 280,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Présentation',
                hintText: 'Ex. : Basée à Rabat. J’aime découvrir le Maroc et partager la route.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 10),
            MoovButton(label: 'Enregistrer', loading: _loading, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
