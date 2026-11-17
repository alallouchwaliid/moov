import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../widgets/common.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'publish/publish_screen.dart';
import 'trips/my_trips_screen.dart';

/// Navigation principale : Recherche · Publier · Trajets · Profil.
class MainShell extends StatefulWidget {
  MainShell({this.initialTab = 0}) : super(key: _shellKey);
  final int initialTab;

  // Une seule barre de navigation existe à la fois : une clé globale permet aux
  // écrans ouverts par-dessus (routes poussées) de changer d'onglet.
  static final _shellKey = GlobalKey<MainShellState>();

  /// Change d'onglet depuis n'importe quel écran (0 Recherche, 1 Publier, 2 Trajets, 3 Profil).
  static void switchTab(int index) => _shellKey.currentState?.setTab(index);

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _index = widget.initialTab;
  final _tripsKey = GlobalKey<MyTripsScreenState>();

  void setTab(int index) {
    setState(() => _index = index);
    if (index == 2) _tripsKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    final pages = <Widget>[
      const HomeScreen(),
      loggedIn
          ? const PublishScreen()
          : const LoginRequired(
              icon: Icons.add_road, message: 'Connectez-vous pour publier un trajet et partager vos frais.'),
      loggedIn
          ? MyTripsScreen(key: _tripsKey)
          : const LoginRequired(
              icon: Icons.event_note_outlined, message: 'Connectez-vous pour retrouver vos réservations et vos trajets.'),
      loggedIn
          ? const ProfileScreen()
          : const LoginRequired(icon: Icons.person_outline, message: 'Connectez-vous pour accéder à votre profil.'),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: setTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Recherche'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Publier'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Trajets'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

/// Affiché à la place d'un onglet réservé aux membres connectés.
class LoginRequired extends StatelessWidget {
  const LoginRequired({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: EmptyState(
        icon: icon,
        title: 'Connexion requise',
        message: message,
        actionLabel: 'Se connecter',
        onAction: () => requireLogin(context),
      ),
    );
  }
}

/// Ouvre l'écran de connexion si besoin. Renvoie true si l'utilisateur est connecté.
Future<bool> requireLogin(BuildContext context) async {
  if (context.read<AuthProvider>().isLoggedIn) return true;
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginScreen(asModal: true), fullscreenDialog: true),
  );
  return ok == true;
}
