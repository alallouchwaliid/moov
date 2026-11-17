import 'package:flutter/material.dart';

import '../../api/moov_api.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Notation 1 à 5 étoiles + commentaire court après un trajet terminé.
class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({super.key, required this.tripId, required this.tripLabel, required this.target});
  final int tripId;
  final String tripLabel;
  final User target;

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  int _rating = 0;
  final _comment = TextEditingController();
  bool _loading = false;

  static const _labels = ['', 'Décevant', 'Moyen', 'Bien', 'Très bien', 'Excellent'];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await MoovApi.postReview(
        tripId: widget.tripId,
        targetId: widget.target.id,
        rating: _rating,
        comment: _comment.text.trim(),
      );
      if (!mounted) return;
      showSnack(context, 'Merci ! Votre avis a été publié.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laisser un avis')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Center(child: UserAvatar(widget.target, size: 80)),
          const SizedBox(height: 14),
          Text('Comment s\'est passé votre trajet avec ${widget.target.firstName} ?',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(widget.tripLabel, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final value = i + 1;
              return IconButton(
                tooltip: '$value étoile${value > 1 ? 's' : ''}',
                iconSize: 44,
                onPressed: () => setState(() => _rating = value),
                icon: Icon(value <= _rating ? Icons.star_rounded : Icons.star_outline_rounded, color: MoovColors.blue),
              );
            }),
          ),
          Text(_labels[_rating],
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, color: MoovColors.blue, fontSize: 16)),
          const SizedBox(height: 22),
          TextField(
            controller: _comment,
            maxLength: 300,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Commentaire (facultatif)',
              hintText: 'Ponctualité, conduite, ambiance…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          MoovButton(label: "Publier l'avis", loading: _loading, onPressed: _rating == 0 ? null : _submit),
          const SizedBox(height: 10),
          const Text('Votre avis sera visible sur le profil du membre. Restez courtois et factuel.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: MoovColors.muted)),
        ],
      ),
    );
  }
}
