import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/moov_api.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// Véhicules du conducteur.
class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  List<Vehicle>? _vehicles;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final v = await MoovApi.vehicles();
      if (mounted) setState(() => _vehicles = v);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _changed() async {
    await _load();
    if (mounted) await context.read<AuthProvider>().refreshMe();
  }

  Future<void> _add() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _VehicleForm(),
    );
    if (added == true) _changed();
  }

  Future<void> _delete(Vehicle v) async {
    final ok = await confirmDialog(context,
        title: 'Supprimer ce véhicule ?', message: v.label, confirm: 'Supprimer', danger: true);
    if (!ok) return;
    try {
      await MoovApi.deleteVehicle(v.id);
      _changed();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = _vehicles;
    return Scaffold(
      appBar: AppBar(title: const Text('Mes véhicules')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: vehicles == null
          ? (_error != null ? ErrorView(message: _error!, onRetry: _load) : const Loading())
          : vehicles.isEmpty
              ? EmptyState(
                  icon: Icons.directions_car_outlined,
                  title: 'Aucun véhicule',
                  message: 'Ajoutez votre véhicule pour que les passagers le reconnaissent au départ.',
                  actionLabel: 'Ajouter un véhicule',
                  onAction: _add,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
                  children: [
                    for (final v in vehicles)
                      MoovCard(
                        child: Row(children: [
                          const Icon(Icons.directions_car, color: MoovColors.blue, size: 30),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(v.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                [plural(v.seats, 'place passager', 'places passagers'), if (v.plateNumber.isNotEmpty) v.plateNumber]
                                    .join(' · '),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ]),
                          ),
                          IconButton(
                            tooltip: 'Supprimer',
                            icon: const Icon(Icons.delete_outline, color: MoovColors.red),
                            onPressed: () => _delete(v),
                          ),
                        ]),
                      ),
                  ],
                ),
    );
  }
}

class _VehicleForm extends StatefulWidget {
  const _VehicleForm();

  @override
  State<_VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<_VehicleForm> {
  final _form = GlobalKey<FormState>();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _color = TextEditingController();
  final _plate = TextEditingController();
  int _seats = 3;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_brand, _model, _color, _plate]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await MoovApi.addVehicle({
        'brand': _brand.text.trim(),
        'model': _model.text.trim(),
        'color': _color.text.trim(),
        'plate_number': _plate.text.trim(),
        'seats': _seats,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    String? notEmpty(String? v) => (v ?? '').trim().isEmpty ? 'Obligatoire' : null;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ajouter un véhicule', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _brand,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Marque', hintText: 'Renault'),
                  validator: notEmpty,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _model,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Modèle', hintText: 'Clio'),
                  validator: notEmpty,
                ),
              ),
            ]),
            gap,
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _color,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Couleur', hintText: 'Blanche'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _plate,
                  decoration: const InputDecoration(labelText: 'Immatriculation'),
                ),
              ),
            ]),
            gap,
            const Text('Places passagers', style: TextStyle(fontWeight: FontWeight.w600)),
            Counter(value: _seats, min: 1, max: 8, onChanged: (v) => setState(() => _seats = v)),
            gap,
            MoovButton(label: 'Enregistrer le véhicule', loading: _loading, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
