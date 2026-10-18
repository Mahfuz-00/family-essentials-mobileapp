import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';
import '../../domain/entities/place.dart';
import '../../domain/repositories/places_repository.dart';

/// What an arrival notification opens: everything still open at that place.
///
/// Reads the existing store-list endpoint, so there is no second way to ask the
/// question "what is waiting here?".
class LocationNeedsCard extends StatefulWidget {
  const LocationNeedsCard({super.key, required this.placeId});

  final int placeId;

  @override
  State<LocationNeedsCard> createState() => _LocationNeedsCardState();
}

class _LocationNeedsCardState extends State<LocationNeedsCard> {
  PlaceNeeds? _needs;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final needs = await getIt<PlacesRepository>().placeNeeds(widget.placeId);

      if (mounted) {
        setState(() => _needs = needs);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return WarmCard(
        child: Text(
          _error!,
          style: const TextStyle(fontSize: 12, color: AppTheme.error),
        ),
      );
    }

    final needs = _needs;

    if (needs == null) {
      return const WarmCard(
        child: Text(
          'Loading this place…',
          style: TextStyle(fontSize: 12, color: AppTheme.muted),
        ),
      );
    }

    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  needs.place.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              if (needs.place.kindLabel != null)
                PriorityChip(
                  label: needs.place.kindLabel!,
                  tone: WarmTone.primary,
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Waiting here',
            style: TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          const SizedBox(height: AppTheme.space2),
          if (needs.requests.isEmpty)
            const Text(
              'Nothing open at this place.',
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
            )
          else
            for (final request in needs.requests)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${request.title}'
                  '${request.quantity == null ? '' : ' (${request.quantity})'}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.ink),
                ),
              ),
        ],
      ),
    );
  }
}
