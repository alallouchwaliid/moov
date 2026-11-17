import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/moov_api.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../trip/trip_detail_screen.dart';

/// Résultats de recherche avec tri et filtres.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.query});
  final SearchQuery query;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late SearchQuery _q = widget.query.copy();
  final List<Trip> _trips = [];
  int _count = 0;
  int _page = 1;
  bool _hasNext = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      if (more) {
        _loadingMore = true;
      } else {
        _loading = true;
        _error = null;
        _page = 1;
      }
    });
    try {
      final page = await MoovApi.searchTrips(_q, page: more ? _page + 1 : 1);
      if (!mounted) return;
      setState(() {
        if (!more) _trips.clear();
        _trips.addAll(page.results);
        _count = page.count;
        _hasNext = page.hasNext;
        if (more) _page++;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _sort(String ordering) {
    if (_q.ordering == ordering) return;
    _q.ordering = ordering;
    _load();
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<SearchQuery>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FiltersSheet(query: _q.copy()),
    );
    if (result != null) {
      _q = result;
      _load();
    }
  }

  Future<void> _saveRoute() async {
    if (_q.from.trim().isEmpty || _q.to.trim().isEmpty) {
      showSnack(context, 'Indiquez un départ et une arrivée pour enregistrer ce trajet.', error: true);
      return;
    }
    try {
      await MoovApi.saveRoute(_q.from.trim(), _q.to.trim());
      if (mounted) showSnack(context, 'Trajet enregistré sur votre accueil.');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  String get _title {
    final from = _q.from.trim().isEmpty ? 'Partout' : _q.from.trim();
    final to = _q.to.trim().isEmpty ? 'Partout' : _q.to.trim();
    return '$from → $to';
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    final subtitle =
        '${_q.date == null ? 'Toutes dates' : formatDayShort(_q.date!)} · ${plural(_q.passengers, 'passager')}';

    return Scaffold(
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_title, overflow: TextOverflow.ellipsis),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: MoovColors.muted)),
        ]),
        actions: [
          if (loggedIn)
            IconButton(tooltip: 'Enregistrer ce trajet', onPressed: _saveRoute, icon: const Icon(Icons.bookmark_add_outlined)),
          IconButton(
            tooltip: 'Filtres',
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: _q.activeFilters > 0,
              label: Text('${_q.activeFilters}'),
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Loading();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_trips.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Aucun trajet pour ces critères',
        message: "Essayez une autre date, retirez des filtres ou augmentez le prix maximum pour trouver plus de trajets.",
        actionLabel: 'Modifier la recherche',
        onAction: () => Navigator.of(context).pop(),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Wrap(spacing: 8, children: [
            ChoiceChip(
              label: const Text('Plus tôt'),
              selected: _q.ordering == 'departure_time',
              onSelected: (_) => _sort('departure_time'),
            ),
            ChoiceChip(
              label: const Text('Moins cher'),
              selected: _q.ordering == 'price_per_seat',
              onSelected: (_) => _sort('price_per_seat'),
            ),
          ]),
          const SizedBox(height: 12),
          Text(plural(_count, 'trajet disponible', 'trajets disponibles'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (var i = 0; i < _trips.length; i++)
            TripCard(
              trip: _trips[i],
              highlight: i == 0,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TripDetailScreen(tripId: _trips[i].id, passengers: _q.passengers),
                ));
                _load();
              },
            ),
          if (_hasNext)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: MoovButton(
                  label: 'Voir plus de trajets', secondary: true, loading: _loadingMore, onPressed: () => _load(more: true)),
            ),
          const MoovCard(
            child: Row(children: [
              Icon(Icons.shield_outlined, color: MoovColors.muted),
              SizedBox(width: 10),
              Expanded(
                  child: Text('Vérifiez le lieu de rendez-vous avant de réserver.',
                      style: TextStyle(color: MoovColors.muted, fontSize: 14))),
            ]),
          ),
        ],
      ),
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.query});
  final SearchQuery query;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late final SearchQuery q = widget.query;

  static const _slots = {
    null: 'Toutes heures',
    '06:00': 'Après 6 h',
    '12:00': 'Après 12 h',
    '18:00': 'Après 18 h',
  };

  @override
  Widget build(BuildContext context) {
    final price = (q.maxPrice ?? 300).toDouble();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtrer les trajets', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            const Text('Départ', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _slots.entries
                  .map((e) => ChoiceChip(
                        label: Text(e.value),
                        selected: q.departureAfter == e.key,
                        onSelected: (_) => setState(() => q.departureAfter = e.key),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Row(children: [
              const Expanded(child: Text('Prix maximum par place', style: TextStyle(fontWeight: FontWeight.w600))),
              Text(q.maxPrice == null ? 'Sans limite' : formatPrice(price),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: MoovColors.blue)),
            ]),
            Slider(
              value: price,
              min: 20,
              max: 300,
              divisions: 28,
              label: formatPrice(price),
              onChanged: (v) => setState(() => q.maxPrice = v >= 300 ? null : v.round()),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Identité vérifiée uniquement'),
              subtitle: const Text('Conducteurs validés par MOOV'),
              value: q.verifiedOnly,
              onChanged: (v) => setState(() => q.verifiedOnly = v),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    q.maxPrice = null;
                    q.verifiedOnly = false;
                    q.departureAfter = null;
                  }),
                  child: const Text('Réinitialiser'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: MoovButton(label: 'Appliquer', onPressed: () => Navigator.pop(context, q))),
            ]),
          ],
        ),
      ),
    );
  }
}
