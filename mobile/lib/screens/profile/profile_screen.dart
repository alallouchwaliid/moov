import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../auth/login_screen.dart';
import '../main_shell.dart';
import '../notifications_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'reviews_screen.dart';
import 'vehicles_screen.dart';

/// « Mon profil » : identité, statistiques, confiance, réglages.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false;

  Future<void> _changePhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      await context.read<AuthProvider>().uploadAvatar(picked);
      if (mounted) showSnack(context, 'Photo mise à jour.');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(context, title: 'Se déconnecter ?', message: 'Vous pourrez vous reconnecter à tout moment.', confirm: 'Se déconnecter');
    if (!ok || !mounted) return;
    final navigator = Navigator.of(context);
    await context.read<AuthProvider>().logout();
    navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  /// « +212612345678 » → « +212 6 •• •• •• 78 »
  String _maskPhone(String p) =>
      p.startsWith('+212') && p.length == 13 ? '+212 ${p[4]} •• •• •• ${p.substring(11)}' : p;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u = auth.user!;
    final muted = Theme.of(context).textTheme.bodySmall;

    Widget trustRow(IconData icon, String label, String text, bool ok) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(children: [
            Icon(icon, color: MoovColors.navy),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(text, style: muted),
              ]),
            ),
            Icon(ok ? Icons.check_circle : Icons.schedule, color: ok ? MoovColors.green : MoovColors.orange),
          ]),
        );

    Widget menuRow(IconData icon, String label, VoidCallback onTap, {Color? color}) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: color ?? MoovColors.navy),
          title: Text(label, style: TextStyle(color: color)),
          trailing: color == null ? const Icon(Icons.chevron_right) : null,
          onTap: onTap,
        );

    void push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: auth.refreshMe,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text('Mon profil', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            Center(
              child: Stack(children: [
                UserAvatar(u, size: 96),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton.filled(
                    tooltip: 'Changer la photo',
                    onPressed: _uploading ? null : _changePhoto,
                    icon: _uploading
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.photo_camera_outlined, size: 18),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Text(u.fullName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Center(
              child: u.isVerified
                  ? const Pill.green('Membre vérifié', icon: Icons.verified_user_outlined)
                  : const Pill('Vérification en attente',
                      icon: Icons.schedule, color: MoovColors.orange, background: MoovColors.orangeSoft),
            ),
            if (u.bio.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(u.bio, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: MoovColors.muted)),
            ],
            if (u.dateJoined != null) ...[
              const SizedBox(height: 6),
              Text('Membre depuis ${formatMonthYear(u.dateJoined!)}', textAlign: TextAlign.center, style: muted),
            ],
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: _stat('${u.tripsCount}', 'Trajets effectués')),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => push(ReviewsScreen(user: u)),
                  child: _stat(
                    u.ratingAverage == null ? '—' : '★ ${u.ratingAverage!.toStringAsFixed(1).replaceAll('.', ',')}',
                    plural(u.ratingCount, 'avis reçu', 'avis reçus'),
                  ),
                ),
              ),
            ]),
            const SectionTitle('Confiance et vérification'),
            trustRow(Icons.badge_outlined, 'Identité',
                u.isVerified ? 'Vérifiée par MOOV' : 'En cours de validation par un administrateur', u.isVerified),
            trustRow(Icons.mail_outline, 'E-mail', u.email ?? '', true),
            trustRow(Icons.phone_outlined, 'Téléphone', u.phone.isEmpty ? 'Non renseigné' : _maskPhone(u.phone),
                u.phone.isNotEmpty),
            const Divider(),
            menuRow(Icons.event_note_outlined, 'Historique et réservations', () => MainShell.switchTab(2)),
            menuRow(Icons.edit_outlined, 'Modifier mon profil', () => push(const EditProfileScreen())),
            menuRow(Icons.directions_car_outlined, 'Mes véhicules', () => push(const VehiclesScreen())),
            menuRow(Icons.star_outline, 'Avis reçus', () => push(ReviewsScreen(user: u))),
            menuRow(Icons.notifications_none, 'Notifications', () => push(const NotificationsScreen())),
            menuRow(Icons.lock_outline, 'Changer le mot de passe', () => push(const ChangePasswordScreen())),
            const Divider(),
            menuRow(Icons.logout, 'Se déconnecter', _logout, color: MoovColors.red),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: MoovColors.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: MoovColors.muted)),
        ]),
      );
}
