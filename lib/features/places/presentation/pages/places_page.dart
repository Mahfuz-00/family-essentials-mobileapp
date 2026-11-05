import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';
import '../../domain/entities/place.dart';
import '../../domain/repositories/places_repository.dart';
import '../bloc/places_bloc.dart';
import '../bloc/places_event.dart';
import '../bloc/places_state.dart';

class PlacesPage extends StatelessWidget {
  const PlacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PlacesBloc>()..add(const PlacesRequested()),
      child: const _PlacesView(),
    );
  }
}

class _PlacesView extends StatefulWidget {
  const _PlacesView();

  @override
  State<_PlacesView> createState() => _PlacesViewState();
}

class _PlacesViewState extends State<_PlacesView> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _latitude = TextEditingController(
    text: '23.8103',
  );
  final TextEditingController _longitude = TextEditingController(
    text: '90.4125',
  );
  double _radius = 300;
  String _category = 'grocery';

  @override
  void dispose() {
    _name.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved places')),
      body: SafeArea(
        child: BlocConsumer<PlacesBloc, PlacesState>(
          listener: (context, state) {
            if (state is PlacesActionSuccess) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
              context.read<PlacesBloc>().add(const PlacesRequested());
            } else if (state is PlacesFailure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // OpenStreetMap Info Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.sageSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.secondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.map_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OpenStreetMap Geofencing',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppTheme.ink,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Geofences trigger automated errands when you arrive inside the boundary. Data © OpenStreetMap contributors.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.muted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add a place',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.ink,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latitude,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _longitude,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'grocery', child: Text('Grocery')),
                    DropdownMenuItem(
                      value: 'pharmacy',
                      child: Text('Pharmacy'),
                    ),
                    DropdownMenuItem(value: 'home', child: Text('Home')),
                    DropdownMenuItem(value: 'school', child: Text('School')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setState(() => _category = value ?? 'other'),
                ),
                const SizedBox(height: 8),
                Text('Radius: ${_radius.round()} m'),
                Slider(
                  value: _radius,
                  min: 50,
                  max: 2000,
                  divisions: 39,
                  label: '${_radius.round()} m',
                  onChanged: (value) => setState(() => _radius = value),
                ),
                FilledButton(
                  onPressed: state is PlacesLoading
                      ? null
                      : () {
                          if (_name.text.trim().isEmpty) {
                            return;
                          }

                          context.read<PlacesBloc>().add(
                            PlaceCreated(
                              name: _name.text.trim(),
                              latitude: double.tryParse(_latitude.text) ?? 0,
                              longitude: double.tryParse(_longitude.text) ?? 0,
                              radiusMeters: _radius.round(),
                              category: _category,
                            ),
                          );
                          _name.clear();
                        },
                  child: const Text('Save place'),
                ),
                const Divider(height: 40),
                SectionHeader(
                  title: 'Saved',
                  count: state is PlacesLoaded ? state.places.length : 0,
                ),
                const SizedBox(height: AppTheme.space3),
                if (state is PlacesLoaded)
                  for (final place in state.places) _PlaceTile(place: place),
                if (state is PlacesLoading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place});

  final Place place;

  Future<void> _openOpenStreetMap(BuildContext context) async {
    final lat = place.latitude;
    final lon = place.longitude;
    final uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=16/$lat/$lon',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open OpenStreetMap link')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: WarmCard(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space4,
          AppTheme.space3,
          AppTheme.space2,
          AppTheme.space3,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${place.kindLabel ?? place.category ?? 'other'} · ${place.radiusMeters} m · '
                        '${place.activeRequestsCount ?? 0} open',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'View on OpenStreetMap',
                  icon: const Icon(Icons.map_outlined, color: AppTheme.secondary),
                  onPressed: () => _openOpenStreetMap(context),
                ),
                IconButton(
                  tooltip: 'Simulate arriving here',
                  icon: const Icon(Icons.my_location, color: AppTheme.secondary),
                  onPressed: () => _simulate(context),
                ),
                IconButton(
                  tooltip: 'Remove ${place.name}',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      context.read<PlacesBloc>().add(PlaceDeleted(place.id)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _openOpenStreetMap(context),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.secondary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: AppTheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'OpenStreetMap: ${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)} (tap to view)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new,
                      size: 12,
                      color: AppTheme.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simulate(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final evaluation = await getIt<PlacesRepository>().reportPosition(
        latitude: place.latitude,
        longitude: place.longitude,
      );

      final arrivals = evaluation.arrivals;
      final first = arrivals.isEmpty ? null : arrivals.first;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            first == null
                ? 'Checked in at ${place.name}. Nothing waiting.'
                : first.isSent
                ? 'Told: ${first.body ?? ''}'
                : 'Not told: ${first.reasonMessage ?? first.reason ?? ''}',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
