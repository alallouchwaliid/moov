import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../state/auth_provider.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../main_shell.dart';
import 'register_screen.dart';

/// Connexion par email + mot de passe.
///
/// [asModal] : ouvert depuis l'app (ex. « Réserver » sans compte) — on revient
/// simplement à l'écran précédent après connexion au lieu de rouvrir l'app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.asModal = false});
  final bool asModal;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _enterApp() {
    if (widget.asModal) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => MainShell()), (_) => false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(_email.text, _password.text);
      if (mounted) _enterApp();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRegister() async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const RegisterScreen()));
    if (ok == true && mounted) _enterApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.asModal ? AppBar() : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/logo.jpeg', width: 44, height: 44),
                  ),
                  const SizedBox(width: 12),
                  const Text('MOOV', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: MoovColors.blue)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Adresse du serveur',
                    icon: const Icon(Icons.dns_outlined, color: MoovColors.muted),
                    onPressed: () => showServerDialog(context),
                  ),
                ]),
                const SizedBox(height: 34),
                Text('Bienvenue à bord.', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Connectez-vous pour réserver un trajet ou partager le vôtre.',
                    style: TextStyle(fontSize: 16, color: MoovColors.muted, height: 1.5)),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Adresse email', prefixIcon: Icon(Icons.mail_outline)),
                  validator: (v) => v == null || !v.contains('@') ? 'Saisissez une adresse email valide.' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Afficher' : 'Masquer',
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Saisissez votre mot de passe.' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.error_outline, color: MoovColors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: MoovColors.red))),
                  ]),
                ],
                const SizedBox(height: 24),
                MoovButton(label: 'Se connecter', icon: Icons.arrow_forward, loading: _loading, onPressed: _submit),
                const SizedBox(height: 12),
                MoovButton(label: 'Créer un compte', secondary: true, onPressed: _openRegister),
                if (!widget.asModal) ...[
                  const SizedBox(height: 28),
                  const InfoCallout(
                    title: 'À votre rythme',
                    icon: Icons.explore_outlined,
                    text: 'Vous pouvez consulter les trajets sans compte. La connexion est nécessaire pour réserver.',
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context)
                          .pushReplacement(MaterialPageRoute(builder: (_) => MainShell())),
                      child: const Text('Explorer sans compte'),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  "En continuant, vous acceptez les conditions d'utilisation et la politique de confidentialité de MOOV.",
                  style: TextStyle(fontSize: 12, color: MoovColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Permet de changer l'adresse du backend depuis le téléphone (autre Wi-Fi,
/// partage de connexion, câble USB avec `adb reverse`…) sans recompiler l'app.
Future<void> showServerDialog(BuildContext context) async {
  final controller = TextEditingController(text: api.baseUrl);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Adresse du serveur'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(hintText: 'http://192.168.1.20:8000/api'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Câble USB (adb reverse) : http://127.0.0.1:8000/api\n'
            'Même Wi-Fi ou partage de connexion : http://<IP du PC>:8000/api',
            style: TextStyle(fontSize: 12, color: MoovColors.muted),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, ''),
          child: const Text('Par défaut'),
        ),
        TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Enregistrer')),
      ],
    ),
  );
  controller.dispose();
  if (result == null) return;
  await api.setBaseUrl(result);
  if (context.mounted) showSnack(context, 'Serveur : ${api.baseUrl}');
}
