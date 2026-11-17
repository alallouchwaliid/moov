import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/moov_api.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../notifications_screen.dart';
import '../search/results_screen.dart';

/// Accueil / recherche : « Trouvez votre prochain trajet. »
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  DateTime? _date;
  int _passengers = 1;

  List<SavedRoute> _saved = [];
  bool _editSaved = false;
  int _unread = 0;
  int? _loadedForUser;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthProvider>(context).user;
    if (user?.id != _loadedForUser) {
      _loadedForUser = user?.id;
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      setState(() {
        _saved = [];
        _unread = 0;
      });
      return;
    }
    try {
      final results = await Future.wait([MoovApi.savedRoutes(), MoovApi.unreadCount()]);
      if (!mounted) return;
      setState(() {
        _saved = results[0] as List<SavedRoute>;
        _unread = results[1] as int;
      });
    } catch (_) {
      // Non bloquant : l'accueil reste utilisable.
    }
  }

  void _swap() {
    final tmp = _from.text;
    _from.text = _to.text;
    _to.text = tmp;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Date du trajet',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _search({String? from, String? to}) async {
    final query = SearchQuery(
      from: from ?? _from.text,
      to: to ?? _to.text,
      date: _date,
      passengers: _passengers,
    );
    if (query.from.trim().isEmpty && query.to.trim().isEmpty) {
      showSnack(context, "Indiquez au moins une ville de départ ou d'arrivée.", error: true);
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultsScreen(query: query)));
    _loadUserData();
  }

  Future<void> _deleteSaved(SavedRoute r) async {
    try {
      await MoovApi.deleteSavedRoute(r.id);
      setState(() => _saved.remove(r));
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadUserData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Row(
              children: [
                user != null
                    ? UserAvatar(user)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset('assets/logo.jpeg', width: 46, height: 46)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user != null ? 'Bonjour ${user.firstName}' : 'Bienvenue sur',
                          style: Theme.of(context).textTheme.bodySmall),
                      const Text('MOOV', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                if (user != null)
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () async {
                      await Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                      _loadUserData();
                    },
                    icon: Badge(
                      isLabelVisible: _unread > 0,
                      label: Text('$_unread'),
                      child: const Icon(Icons.notifications_none, size: 27),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Trouvez votre prochain trajet.', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            const Text('Partagez le trajet, partagez le coût.', style: TextStyle(fontSize: 16, color: MoovColors.muted)),
            const SizedBox(height: 22),
            Stack(
              children: [
                Column(children: [
                  TextField(
                    controller: _from,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Départ', hintText: 'Ville de départ', prefixIcon: Icon(Icons.radio_button_unchecked)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _to,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                        labelText: 'Arrivée', hintText: "Ville d'arrivée", prefixIcon: Icon(Icons.location_on_outlined)),
                  ),
                ]),
                Positioned(
                  right: 8,
                  top: 40,
                  child: IconButton.filledTonal(
                    tooltip: 'Inverser départ et arrivée',
                    onPressed: _swap,
                    icon: const Icon(Icons.swap_vert),
                    style: IconButton.styleFrom(backgroundColor: MoovColors.soft),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        suffixIcon: _date == null
                            ? null
                            : IconButton(
                                tooltip: 'Effacer',
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _date = null)),
                      ),
                      child: Text(_date == null ? 'Toutes dates' : formatDayShort(_date!),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Passagers',
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: _passengers > 1 ? () => setState(() => _passengers--) : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text('$_passengers', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: _passengers < 8 ? () => setState(() => _passengers++) : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            MoovButton(label: 'Rechercher', icon: Icons.arrow_forward, onPressed: _search),
            if (_saved.isNotEmpty) ...[
              SectionTitle('Trajets enregistrés',
                  action: _editSaved ? 'Terminé' : 'Gérer', onAction: () => setState(() => _editSaved = !_editSaved)),
              for (final r in _saved)
                MoovCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  onTap: _editSaved ? null : () => _search(from: r.departureCity, to: r.arrivalCity),
                  child: Row(children: [
                    const Pill('', icon: Icons.bookmark_outline),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${r.departureCity} → ${r.arrivalCity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        if (r.departurePlace.isNotEmpty || r.arrivalPlace.isNotEmpty)
                          Text(
                            [r.departurePlace, r.arrivalPlace].where((e) => e.isNotEmpty).join(' · '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ]),
                    ),
                    _editSaved
                        ? IconButton(
                            tooltip: 'Supprimer',
                            icon: const Icon(Icons.delete_outline, color: MoovColors.red),
                            onPressed: () => _deleteSaved(r))
                        : const Icon(Icons.arrow_forward, color: MoovColors.muted),
                  ]),
                ),
            ],
            const SizedBox(height: 22),
            const InfoCallout(
              title: 'Plus sûrs ensemble.',
              text: 'Consultez les avis des membres et partagez les détails de votre trajet avec un proche.',
            ),
          ],
        ),
      ),
    );
  }
}
