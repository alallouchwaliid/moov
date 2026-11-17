import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../theme.dart';
import 'auth/login_screen.dart';
import 'main_shell.dart';

/// Écran d'accueil : logo + slogan. Touchez pour commencer.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  void _continue() {
    final auth = context.read<AuthProvider>();
    if (!auth.isReady || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => auth.isLoggedIn ? MainShell() : const LoginScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // Utilisateur déjà connecté : on entre directement dans l'app.
    if (auth.isReady && auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _continue());
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _continue,
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset('assets/logo.jpeg', width: 120, height: 120),
                ),
                const SizedBox(height: 22),
                const Text('MOOV',
                    style: TextStyle(
                        fontSize: 40, fontWeight: FontWeight.w800, color: MoovColors.blue, letterSpacing: 3)),
                const SizedBox(height: 10),
                const Text('Partagez le trajet,\npartagez le coût.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: MoovColors.muted, height: 1.5)),
                const Spacer(),
                const Text('Le covoiturage universitaire au Maroc', style: TextStyle(color: MoovColors.muted)),
                const SizedBox(height: 6),
                auth.isReady
                    ? const Text("Touchez l'écran pour commencer",
                        style: TextStyle(color: MoovColors.muted, fontSize: 13))
                    : const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
