import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/moov_api.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../trip/trip_detail_screen.dart';

/// Tous les avis reçus par un membre.
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key, required this.user});
  final User user;

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final List<Review> _reviews = [];
  int _page = 1;
  bool _hasNext = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _loading = !more;
      _error = null;
    });
    try {
      final p = await MoovApi.reviewsFor(widget.user.id, page: more ? _page + 1 : 1);
      if (!mounted) return;
      setState(() {
        if (!more) {
          _reviews.clear();
          _page = 1;
        } else {
          _page++;
        }
        _reviews.addAll(p.results);
        _hasNext = p.hasNext;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _report(Review r) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Signaler cet avis'),
        content: TextField(
          controller: controller,
          maxLength: 300,
          decoration: const InputDecoration(hintText: 'Pourquoi cet avis pose-t-il problème ?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Signaler')),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty) return;
    try {
      await MoovApi.reportReview(r.id, reason);
      if (mounted) showSnack(context, "Merci, l'avis a été transmis à la modération.");
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final me = context.watch<AuthProvider>().user;
    final isMe = me?.id == u.id;
    return Scaffold(
      appBar: AppBar(title: Text(isMe ? 'Mes avis reçus' : 'Avis sur ${u.firstName}')),
      body: _loading
          ? const Loading()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                  children: [
                    Row(children: [
                      UserAvatar(u, size: 64),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(u.fullName, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(ratingText(u), style: const TextStyle(color: MoovColors.muted)),
                          if (u.isVerified) ...[
                            const SizedBox(height: 8),
                            const Pill.green('Membre vérifié', icon: Icons.verified_user_outlined),
                          ],
                        ]),
                      ),
                    ]),
                    if (u.bio.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(u.bio, style: const TextStyle(color: MoovColors.muted)),
                    ],
                    const Divider(),
                    if (_reviews.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Text('Aucun avis pour le moment.',
                            textAlign: TextAlign.center, style: TextStyle(color: MoovColors.muted)),
                      ),
                    for (final r in _reviews)
                      ReviewTile(review: r, onReport: isMe ? () => _report(r) : null),
                    if (_hasNext)
                      MoovButton(label: "Voir plus d'avis", secondary: true, onPressed: () => _load(more: true)),
                  ],
                ),
    );
  }
}
