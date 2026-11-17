import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/moov_api.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../profile/vehicles_screen.dart';
import 'publish_success_screen.dart';

/// Publier un trajet (mode conducteur).
class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _form = GlobalKey<FormState>();
  final _fromCity = TextEditingController();
  final _fromPlace = TextEditingController();
  final _toCity = TextEditingController();
  final _toPlace = TextEditingController();
  final _description = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;
  TimeOfDay? _arrival;
  int _price = 50;
  int _seats = 3;
  int? _vehicleId;
  String _luggage = 'medium';
  bool _smoking = false;
  bool _pets = false;
  bool _autoAccept = false;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_fromCity, _fromPlace, _toCity, _toPlace, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  void _reset() {
    _form.currentState?.reset();
    for (final c in [_fromCity, _fromPlace, _toCity, _toPlace, _description]) {
      c.clear();
    }
    setState(() {
      _date = null;
      _time = null;
      _arrival = null;
      _price = 50;
      _seats = 3;
      _smoking = false;
      _pets = false;
      _autoAccept = false;
    });
  }

  DateTime _combine(DateTime d, TimeOfDay t) => DateTime(d.year, d.month, d.day, t.hour, t.minute);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime({bool arrival = false}) async {
    final t = await showTimePicker(
      context: context,
      initialTime: (arrival ? _arrival : _time) ?? const TimeOfDay(hour: 8, minute: 0),
      helpText: arrival ? "Heure d'arrivée estimée" : 'Heure de départ',
    );
    if (t == null) return;
    setState(() {
      if (arrival) {
        _arrival = t;
      } else {
        _time = t;
      }
    });
  }

  Future<void> _publish(List<Vehicle> vehicles) async {
    if (!_form.currentState!.validate()) return;
    if (_date == null || _time == null) {
      showSnack(context, 'Choisissez la date et l’heure de départ.', error: true);
      return;
    }
    final departure = _combine(_date!, _time!);
    if (departure.isBefore(DateTime.now())) {
      showSnack(context, "L'heure de départ est déjà passée.", error: true);
      return;
    }
    DateTime? arrival;
    if (_arrival != null) {
      arrival = _combine(_date!, _arrival!);
      if (!arrival.isAfter(departure)) arrival = arrival.add(const Duration(days: 1)); // arrivée le lendemain
    }

    setState(() => _loading = true);
    try {
      final trip = await MoovApi.publishTrip({
        'departure_city': _fromCity.text.trim(),
        'departure_place': _fromPlace.text.trim(),
        'arrival_city': _toCity.text.trim(),
        'arrival_place': _toPlace.text.trim(),
        'departure_time': departure.toUtc().toIso8601String(),
        'arrival_time': arrival?.toUtc().toIso8601String(),
        'seats_total': _seats,
        'price_per_seat': _price,
        'vehicle_id': _vehicleId ?? (vehicles.isNotEmpty ? vehicles.first.id : null),
        'luggage': _luggage,
        'smoking_allowed': _smoking,
        'pets_allowed': _pets,
        'auto_accept': _autoAccept,
        'description': _description.text.trim(),
      });
      if (!mounted) return;
      // Le formulaire est vidé dans tous les cas (« Voir mes trajets » ou « Publier un autre trajet »).
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PublishSuccessScreen(trip: trip)));
      _reset();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final vehicles = user.vehicles;
    final selected = vehicles.where((v) => v.id == _vehicleId).firstOrNull ?? vehicles.firstOrNull;
    final maxSeats = selected?.seats ?? 8;
    if (_seats > maxSeats) _seats = maxSeats;
    const gap = SizedBox(height: 12);

    return SafeArea(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text('Publier un trajet', style: Theme.of(context).textTheme.headlineSmall),
            Text('Mode conducteur', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 22),
            Text('Partagez votre trajet.', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            const Text('Votre itinéraire, coûts partagés, moins de voitures.',
                style: TextStyle(fontSize: 16, color: MoovColors.muted)),
            const SizedBox(height: 22),
            _cityField(_fromCity, 'Ville de départ', Icons.radio_button_unchecked),
            gap,
            _placeField(_fromPlace, 'Lieu de rendez-vous', 'Ex. : Gare Rabat Ville'),
            gap,
            _cityField(_toCity, "Ville d'arrivée", Icons.location_on_outlined),
            gap,
            _placeField(_toPlace, "Lieu d'arrivée", 'Ex. : Campus UM6P'),
            gap,
            Row(children: [
              Expanded(
                child: _pickerField('Date', Icons.calendar_today_outlined,
                    _date == null ? 'Choisir' : formatDayShort(_date!), _pickDate),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _pickerField('Départ', Icons.schedule, _time?.format(context) ?? 'Heure', _pickTime),
              ),
            ]),
            gap,
            _pickerField("Arrivée estimée (facultatif)", Icons.flag_outlined, _arrival?.format(context) ?? 'Heure',
                () => _pickTime(arrival: true)),
            const SizedBox(height: 20),
            MoovCard(
              soft: true,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Prix par place', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Counter(
                  value: _price,
                  min: 5,
                  max: 1000,
                  step: 5,
                  format: (v) => '$v MAD',
                  onChanged: (v) => setState(() => _price = v),
                ),
                Text('Prix affiché par passager, en dirhams.', style: Theme.of(context).textTheme.bodySmall),
                const Divider(height: 28),
                Text('Places disponibles', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Counter(value: _seats, min: 1, max: maxSeats, onChanged: (v) => setState(() => _seats = v)),
                Text('Jusqu’à ${plural(maxSeats, 'passager')}', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            _vehicleSection(vehicles, selected),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _luggage,
              decoration: const InputDecoration(labelText: 'Bagages', prefixIcon: Icon(Icons.luggage_outlined)),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('Aucun bagage')),
                DropdownMenuItem(value: 'small', child: Text('Petit bagage')),
                DropdownMenuItem(value: 'medium', child: Text('1 bagage moyen par personne')),
                DropdownMenuItem(value: 'large', child: Text('Grand bagage')),
              ],
              onChanged: (v) => setState(() => _luggage = v ?? 'medium'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fumeur accepté'),
              value: _smoking,
              onChanged: (v) => setState(() => _smoking = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Animaux acceptés'),
              value: _pets,
              onChanged: (v) => setState(() => _pets = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Réservation instantanée'),
              subtitle: const Text('Les demandes sont acceptées automatiquement.'),
              value: _autoAccept,
              onChanged: (v) => setState(() => _autoAccept = v),
            ),
            gap,
            TextFormField(
              controller: _description,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Informations complémentaires',
                hintText: 'Point de rendez-vous précis, arrêts possibles…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            MoovButton(
              label: 'Publier le trajet',
              icon: Icons.arrow_forward,
              loading: _loading,
              onPressed: () => _publish(vehicles),
            ),
            const SizedBox(height: 12),
            const Text('En publiant, vous acceptez les règles de la communauté.',
                style: TextStyle(fontSize: 12, color: MoovColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _cityField(TextEditingController c, String label, IconData icon) => TextFormField(
        controller: c,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: (v) => (v ?? '').trim().isEmpty ? 'Ville obligatoire.' : null,
      );

  Widget _placeField(TextEditingController c, String label, String hint) => TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: const Icon(Icons.place_outlined)),
      );

  Widget _pickerField(String label, IconData icon, String value, VoidCallback onTap) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      );

  Widget _vehicleSection(List<Vehicle> vehicles, Vehicle? selected) {
    Future<void> openVehicles() async {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VehiclesScreen()));
      if (mounted) await context.read<AuthProvider>().refreshMe();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        const Icon(Icons.directions_car_outlined, color: MoovColors.navy),
        const SizedBox(width: 12),
        Expanded(
          child: vehicles.isEmpty
              ? const Text('Aucun véhicule enregistré', style: TextStyle(color: MoovColors.muted))
              : vehicles.length == 1
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(selected!.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('Votre véhicule enregistré', style: Theme.of(context).textTheme.bodySmall),
                    ])
                  : DropdownButton<int>(
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      value: selected!.id,
                      items: [
                        for (final v in vehicles) DropdownMenuItem(value: v.id, child: Text(v.label)),
                      ],
                      onChanged: (id) => setState(() => _vehicleId = id),
                    ),
        ),
        TextButton(onPressed: openVehicles, child: Text(vehicles.isEmpty ? 'Ajouter' : 'Gérer')),
      ]),
    );
  }
}
