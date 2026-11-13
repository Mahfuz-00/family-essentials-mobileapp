import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
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
  final MapController _mapController = MapController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _latitude = TextEditingController(text: '23.8103');
  final TextEditingController _longitude = TextEditingController(text: '90.4125');

  double _radius = 300;
  String _category = 'grocery';

  Place? _selectedPlace;
  double _editRadius = 300;
  LatLng? _droppedPin = const LatLng(23.8103, 90.4125);
  int _placeCap = 10;
  String _planLabel = 'Pilot Family';

  @override
  void initState() {
    super.initState();
    _loadPlanPlaceCap();
  }

  Future<void> _loadPlanPlaceCap() async {
    try {
      final savedTier = await getIt<SecureStorage>().readActiveTier();
      if (savedTier == 'starter') {
        _placeCap = 2;
        _planLabel = 'Starter Family';
      } else if (savedTier == 'household_pro' || savedTier == 'standard') {
        _placeCap = 25;
        _planLabel = 'Household Pro';
      } else if (savedTier == 'enterprise') {
        _placeCap = 100;
        _planLabel = 'Enterprise';
      }
      if (getIt.isRegistered<DioClient>()) {
        final res = await getIt<DioClient>().dio.get<Map<String, dynamic>>(
          '/v1/tenant/quotas',
        );
        final plan = res.data?['plan'];
        if (plan is Map) {
          if (plan['place_cap'] is num) {
            _placeCap = (plan['place_cap'] as num).toInt();
          }
          if (plan['label'] is String) {
            _planLabel = plan['label'] as String;
          }
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  void _selectPlace(Place place) {
    setState(() {
      _selectedPlace = place;
      _editRadius = place.radiusMeters.toDouble();
      _droppedPin = null;
    });
    _mapController.move(LatLng(place.latitude, place.longitude), 15.0);
  }

  void _clearSelectedPlace() {
    setState(() {
      _selectedPlace = null;
      _droppedPin = LatLng(
        double.tryParse(_latitude.text) ?? 23.8103,
        double.tryParse(_longitude.text) ?? 90.4125,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<PlacesBloc, PlacesState>(
          listener: (context, state) {
            if (state is PlacesActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.secondary,
                ),
              );
              context.read<PlacesBloc>().add(const PlacesRequested());
              if (_selectedPlace != null) {
                setState(() => _selectedPlace = null);
              }
            } else if (state is PlacesFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.accent,
                ),
              );
            }
          },
          builder: (context, state) {
            final places = state is PlacesLoaded ? state.places : <Place>[];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                // OpenStreetMap Info Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.forestSoft,
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
                              'OpenStreetMap Live Geofences',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppTheme.ink,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Tap any place or map location to inspect and adjust boundary radius.',
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
                const SizedBox(height: 16),

                // Interactive OpenStreetMap Container (Point 20)
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.secondary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: places.isNotEmpty
                              ? LatLng(places.first.latitude, places.first.longitude)
                              : const LatLng(23.8103, 90.4125),
                          initialZoom: 13.5,
                          onTap: (tapPosition, point) {
                            setState(() {
                              _selectedPlace = null;
                              _droppedPin = point;
                              _latitude.text = point.latitude.toStringAsFixed(6);
                              _longitude.text = point.longitude.toStringAsFixed(6);
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.familyessentials.family_essentials_mobile',
                          ),
                          // Geofence Circles
                          CircleLayer(
                            circles: [
                              for (final p in places)
                                CircleMarker(
                                  point: LatLng(p.latitude, p.longitude),
                                  radius: _selectedPlace?.id == p.id
                                      ? _editRadius
                                      : p.radiusMeters.toDouble(),
                                  useRadiusInMeter: true,
                                  color: _selectedPlace?.id == p.id
                                      ? AppTheme.secondary.withValues(alpha: 0.3)
                                      : AppTheme.secondary.withValues(alpha: 0.12),
                                  borderColor: _selectedPlace?.id == p.id
                                      ? AppTheme.secondary
                                      : AppTheme.secondary.withValues(alpha: 0.6),
                                  borderStrokeWidth: _selectedPlace?.id == p.id ? 2.5 : 1.5,
                                ),
                              // New dropped pin preview circle
                              if (_selectedPlace == null && _droppedPin != null)
                                CircleMarker(
                                  point: _droppedPin!,
                                  radius: _radius,
                                  useRadiusInMeter: true,
                                  color: AppTheme.accent.withValues(alpha: 0.2),
                                  borderColor: AppTheme.accent,
                                  borderStrokeWidth: 2.0,
                                ),
                            ],
                          ),
                          // Markers
                          MarkerLayer(
                            markers: [
                              for (final p in places)
                                Marker(
                                  point: LatLng(p.latitude, p.longitude),
                                  width: 44,
                                  height: 44,
                                  child: GestureDetector(
                                    onTap: () => _selectPlace(p),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: _selectedPlace?.id == p.id
                                            ? AppTheme.secondary
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.secondary,
                                          width: 2,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _iconForCategory(p.category),
                                        size: 22,
                                        color: _selectedPlace?.id == p.id
                                            ? Colors.white
                                            : AppTheme.secondary,
                                      ),
                                    ),
                                  ),
                                ),
                              if (_selectedPlace == null && _droppedPin != null)
                                Marker(
                                  point: _droppedPin!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    size: 38,
                                    color: AppTheme.accent,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      // Top Map Controls & Attribution
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 80,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.touch_app, size: 14, color: AppTheme.secondary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _selectedPlace != null
                                        ? 'Editing: ${_selectedPlace!.name}'
                                        : 'Tap map to drop pin',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'map_zoom_in',
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.ink,
                              elevation: 2,
                              onPressed: () {
                                final currentZoom = _mapController.camera.zoom;
                                _mapController.move(
                                  _mapController.camera.center,
                                  currentZoom + 1,
                                );
                              },
                              child: const Icon(Icons.add, size: 18),
                            ),
                            const SizedBox(height: 6),
                            FloatingActionButton.small(
                              heroTag: 'map_zoom_out',
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.ink,
                              elevation: 2,
                              onPressed: () {
                                final currentZoom = _mapController.camera.zoom;
                                _mapController.move(
                                  _mapController.camera.center,
                                  currentZoom - 1,
                                );
                              },
                              child: const Icon(Icons.remove, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Map Geofence Adjuster OR Add Place Card (Point 20)
                if (_selectedPlace != null) ...[
                  WarmCard(
                    padding: const EdgeInsets.all(16),
                    borderColor: AppTheme.secondary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.forestSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _iconForCategory(_selectedPlace!.category),
                                color: AppTheme.secondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedPlace!.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                  Text(
                                    '${_selectedPlace!.latitude.toStringAsFixed(4)}, ${_selectedPlace!.longitude.toStringAsFixed(4)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _clearSelectedPlace,
                              child: const Text('Deselect'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Adjust Geofence Radius:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.ink,
                              ),
                            ),
                            Text(
                              '${_editRadius.round()} meters',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _editRadius,
                          min: 50,
                          max: 2000,
                          divisions: 39,
                          activeColor: AppTheme.secondary,
                          label: '${_editRadius.round()} m',
                          onChanged: (val) => setState(() => _editRadius = val),
                        ),
                        const SizedBox(height: 6),
                        FilledButton.icon(
                          onPressed: () {
                            context.read<PlacesBloc>().add(
                              PlaceUpdated(
                                id: _selectedPlace!.id,
                                radiusMeters: _editRadius.round(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: Text('Save New Radius (${_editRadius.round()} m)'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  WarmCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add a Saved Place',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.ink,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap the map above to pick exact coordinates automatically.',
                          style: TextStyle(fontSize: 12, color: AppTheme.muted),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Place Name (e.g. Agora Supermarket)',
                            prefixIcon: Icon(Icons.storefront_outlined),
                          ),
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
                                  prefixIcon: Icon(Icons.my_location, size: 18),
                                ),
                                onChanged: (val) {
                                  final lat = double.tryParse(val);
                                  if (lat != null && _droppedPin != null) {
                                    setState(() {
                                      _droppedPin = LatLng(lat, _droppedPin!.longitude);
                                    });
                                  }
                                },
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
                                  prefixIcon: Icon(Icons.explore_outlined, size: 18),
                                ),
                                onChanged: (val) {
                                  final lng = double.tryParse(val);
                                  if (lng != null && _droppedPin != null) {
                                    setState(() {
                                      _droppedPin = LatLng(_droppedPin!.latitude, lng);
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'grocery', child: Text('Grocery / Supermarket')),
                            DropdownMenuItem(value: 'pharmacy', child: Text('Pharmacy')),
                            DropdownMenuItem(value: 'home', child: Text('Home')),
                            DropdownMenuItem(value: 'school', child: Text('School')),
                            DropdownMenuItem(value: 'other', child: Text('Other')),
                          ],
                          onChanged: (value) => setState(() => _category = value ?? 'other'),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Trigger Boundary:',
                              style: TextStyle(fontSize: 13, color: AppTheme.ink),
                            ),
                            Text(
                              '${_radius.round()} meters',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _radius,
                          min: 50,
                          max: 2000,
                          divisions: 39,
                          activeColor: AppTheme.secondary,
                          label: '${_radius.round()} m',
                          onChanged: (value) => setState(() => _radius = value),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: state is PlacesLoading
                              ? null
                              : () {
                                  if (places.length >= _placeCap) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Plan Limit Reached: $_planLabel allows up to $_placeCap saved places. Upgrade your plan for more.',
                                        ),
                                        backgroundColor: AppTheme.tertiary,
                                        action: SnackBarAction(
                                          label: 'Upgrade',
                                          textColor: Colors.white,
                                          onPressed: () =>
                                              context.push('/billing'),
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (_name.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a place name')),
                                    );
                                    return;
                                  }

                                  context.read<PlacesBloc>().add(
                                    PlaceCreated(
                                      name: _name.text.trim(),
                                      latitude: double.tryParse(_latitude.text) ?? 23.8103,
                                      longitude: double.tryParse(_longitude.text) ?? 90.4125,
                                      radiusMeters: _radius.round(),
                                      category: _category,
                                    ),
                                  );
                                  _name.clear();
                                },
                          icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                          label: Text(
                            places.length >= _placeCap
                                ? 'Plan Limit Reached (${places.length}/$_placeCap)'
                                : 'Save Place to Household (${places.length}/$_placeCap)',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Saved Places List Section
                SectionHeader(
                  title: 'Household Places',
                  count: places.length,
                ),
                const SizedBox(height: AppTheme.space3),

                // Shimmer Loading for Places (Point 19)
                if (state is PlacesLoading) ...[
                  const ShimmerWarmCard(height: 90),
                  const SizedBox(height: AppTheme.space3),
                  const ShimmerWarmCard(height: 90),
                  const SizedBox(height: AppTheme.space3),
                  const ShimmerWarmCard(height: 90),
                ] else if (places.isEmpty) ...[
                  WarmCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.location_off_outlined, size: 40, color: AppTheme.muted.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          const Text(
                            'No saved places yet',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap the map above to drop a pin and save your first geofence.',
                            style: TextStyle(fontSize: 12, color: AppTheme.muted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  for (final place in places)
                    _PlaceTile(
                      place: place,
                      isSelected: _selectedPlace?.id == place.id,
                      onTap: () => _selectPlace(place),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _iconForCategory(String? category) {
    switch (category) {
      case 'grocery':
        return Icons.shopping_basket_rounded;
      case 'pharmacy':
        return Icons.local_pharmacy_rounded;
      case 'home':
        return Icons.cottage_rounded;
      case 'school':
        return Icons.school_rounded;
      default:
        return Icons.pin_drop_rounded;
    }
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({
    required this.place,
    required this.isSelected,
    required this.onTap,
  });

  final Place place;
  final bool isSelected;
  final VoidCallback onTap;

  void _openInAppMapModal(BuildContext context) {
    final point = LatLng(place.latitude, place.longitude);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.map_rounded, color: AppTheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ),
                      Text(
                        'In-App OpenStreetMap · ${place.radiusMeters}m geofence · ${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: 15.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.familyessentials.family_essentials_mobile',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: point,
                          radius: place.radiusMeters.toDouble(),
                          useRadiusInMeter: true,
                          color: AppTheme.secondary.withValues(alpha: 0.22),
                          borderColor: AppTheme.secondary,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onTap();
                    },
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Adjust Radius on Page'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _simulate(context);
                    },
                    icon: const Icon(Icons.my_location_rounded, size: 16),
                    label: const Text('Simulate Arrival'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final point = LatLng(place.latitude, place.longitude);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: WarmCard(
          borderColor: isSelected ? AppTheme.secondary : null,
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space4,
            AppTheme.space3,
            AppTheme.space3,
            AppTheme.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                place.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.ink,
                                ),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ACTIVE ON MAP',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${place.kindLabel ?? place.category ?? 'other'} · ${place.radiusMeters} m radius · '
                          '${place.activeRequestsCount ?? 0} open errands',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Inspect on In-App OpenStreetMap',
                    icon: const Icon(Icons.map_outlined, color: AppTheme.secondary),
                    onPressed: () => _openInAppMapModal(context),
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
              const SizedBox(height: 10),
              // Embedded In-App OpenStreetMap Preview (Point 6 — no external browser URL link)
              GestureDetector(
                onTap: () => _openInAppMapModal(context),
                child: Container(
                  height: 112,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.secondary.withValues(alpha: 0.25),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      IgnorePointer(
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: point,
                            initialZoom: 15.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.familyessentials.family_essentials_mobile',
                            ),
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: point,
                                  radius: place.radiusMeters.toDouble(),
                                  useRadiusInMeter: true,
                                  color: AppTheme.secondary.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderColor: AppTheme.secondary,
                                  borderStrokeWidth: 1.5,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: point,
                                  width: 32,
                                  height: 32,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.secondary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fullscreen_rounded,
                                size: 14,
                                color: AppTheme.secondary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'In-App OpenStreetMap',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
