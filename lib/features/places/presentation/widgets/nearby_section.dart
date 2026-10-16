import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/geo/location_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/place.dart';
import '../../domain/repositories/places_repository.dart';

/// Store-specific shopping lists (PRD Layer 3 of Phase 5): when the device is
/// within a saved place's radius, the requests bound to that place surface.
///
/// The real plugin supplies positions; here the "simulate arrival" action uses
/// [MockLocationProvider] so the flow is demoable without hardware.
class NearbySection extends StatefulWidget {
  const NearbySection({super.key});

  @override
  State<NearbySection> createState() => _NearbySectionState();
}

class _NearbySectionState extends State<NearbySection> {
  List<Place> _places = const [];
  GeofenceEvaluation? _evaluation;
  bool _permissionDenied = false;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final places = await getIt<PlacesRepository>().places();

      if (mounted) {
        setState(() => _places = places);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  Future<void> _simulateArrival(Place place) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final provider = getIt<LocationProvider>();
    final granted = await provider.requestPermission();

    if (!granted) {
      if (mounted) {
        setState(() {
          _busy = false;
          _permissionDenied = true;
        });
      }
      return;
    }

    if (provider is MockLocationProvider) {
      provider.simulate(place.point);
    }

    try {
      final position = await provider.currentPosition();
      final evaluation = await getIt<PlacesRepository>().reportPosition(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (mounted) {
        setState(() {
          _evaluation = evaluation;
          _permissionDenied = false;
          _busy = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_places.isEmpty && _error == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nearby stores',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.ink,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Arriving near a saved place surfaces the shopping list for it.',
            style: TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final place in _places)
                OutlinedButton(
                  onPressed: _busy ? null : () => _simulateArrival(place),
                  child: Text('Simulate arriving at ${place.name}'),
                ),
            ],
          ),
          if (_permissionDenied) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.coralSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Location permission denied — reminders still fire on their due '
                'time (time-based fallback). Enable location to get store alerts.',
                style: TextStyle(color: AppTheme.tertiary, fontSize: 12),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.error, fontSize: 12),
            ),
          ],
          if (_evaluation != null) ...[
            const SizedBox(height: 12),
            for (final list in _evaluation!.shoppingLists)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shopping list · ${list.place.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (list.requests.isEmpty)
                      const Text(
                        'Nothing pending here.',
                        style: TextStyle(color: AppTheme.muted, fontSize: 12),
                      )
                    else
                      for (final request in list.requests)
                        Text(
                          '• ${request.title}${request.quantity == null ? '' : ' (${request.quantity})'}',
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 13,
                          ),
                        ),
                  ],
                ),
              ),
            for (final transition in _evaluation!.transitions)
              Text(
                '${transition.entered ? 'Entered' : 'Left'} place #${transition.placeId} '
                '(${transition.distanceMeters.round()} m)',
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
          ],
        ],
      ),
    );
  }
}
