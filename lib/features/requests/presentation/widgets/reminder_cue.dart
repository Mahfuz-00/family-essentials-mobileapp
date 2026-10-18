import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';
import '../../../places/domain/entities/place.dart';
import '../../../places/domain/repositories/places_repository.dart';

/// The reminder-cue vocabulary, mapped straight onto the API's
/// `location_trigger_direction`. `time` means "no location cue at all".
const String cueByTime = 'time';
const String cueOnArrival = 'enter';
const String cueOnLeaving = 'exit';

/// A sheet that lists options and ticks the current one.
///
/// Extracted so every "choose one of these" in the request flow — member, shop,
/// reminder place — looks and behaves the same way.
Future<T?> showChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T option) label,
  T? current,
}) {
  if (options.isEmpty) {
    return Future.value(null);
  }

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusXl),
      ),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final option in options)
                  ListTile(
                    title: Text(label(option)),
                    trailing: option == current
                        ? const Icon(Icons.check, color: AppTheme.secondary)
                        : null,
                    onTap: () => Navigator.of(context).pop(option),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space2),
        ],
      ),
    ),
  );
}

/// The reminder-cue control: due time, on arrival, on leaving — and, for the
/// two location modes, the saved place that sets it off.
///
/// The same widget is used when a task (or a recurring rule) is created and
/// when its cue is changed afterwards, so the two can never drift apart.
class ReminderCueControl extends StatelessWidget {
  const ReminderCueControl({
    super.key,
    required this.mode,
    required this.places,
    required this.triggerPlaceId,
    required this.onModeChanged,
    required this.onPlaceChanged,
    this.title = 'Remind me',
  });

  /// One of [cueByTime], [cueOnArrival], [cueOnLeaving].
  final String mode;
  final List<Place> places;
  final int? triggerPlaceId;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<int> onPlaceChanged;
  final String title;

  Place? get _place {
    for (final place in places) {
      if (place.id == triggerPlaceId) {
        return place;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final place = _place;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, count: mode == cueByTime ? 0 : 1),
        const SizedBox(height: AppTheme.space2),
        Wrap(
          spacing: AppTheme.space2,
          runSpacing: AppTheme.space2,
          children: [
            _modeChip(context, cueByTime, 'When it is due'),
            _modeChip(context, cueOnArrival, 'When I arrive'),
            _modeChip(context, cueOnLeaving, 'When I leave'),
          ],
        ),
        if (mode != cueByTime) ...[
          const SizedBox(height: AppTheme.space3),
          ChoiceButton(
            icon: Icons.place_outlined,
            label: place == null
                ? 'Choose a place'
                : '${mode == cueOnLeaving ? 'Leaving' : 'Arriving at'} ${place.name}',
            onTap: places.isEmpty
                ? null
                : () async {
                    final chosen = await showChoiceSheet<Place>(
                      context: context,
                      title: 'Remind me at',
                      options: places,
                      label: (option) => option.kindLabel == null
                          ? option.name
                          : '${option.name} · ${option.kindLabel}',
                      current: place,
                    );

                    if (chosen != null) {
                      onPlaceChanged(chosen.id);
                    }
                  },
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Pick the place that should set the reminder off — your office, or home.',
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
          ),
        ],
      ],
    );
  }

  Widget _modeChip(BuildContext context, String value, String label) {
    final selected = mode == value;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onModeChanged(value),
      showCheckmark: false,
      selectedColor: AppTheme.forestSoft,
      backgroundColor: AppTheme.surface,
      side: BorderSide(
        color: selected ? AppTheme.secondary : const Color(0x1F2B2D42),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? AppTheme.secondary : AppTheme.ink,
        ),
      ),
    );
  }
}

/// A 44pt-tall outlined choice, so a finger can hit it.
class ChoiceButton extends StatelessWidget {
  const ChoiceButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: AppTheme.onSurfaceVariant),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.ink,
          ),
        ),
      ),
    );
  }
}

/// Changing a cue after the fact: the same control, in a sheet.
///
/// Loads the saved places itself, so a caller only needs the task's current cue.
Future<({String mode, int? placeId})?> showReminderCueSheet({
  required BuildContext context,
  required String initialMode,
  int? initialPlaceId,
  String title = 'Change the reminder',
}) {
  return showModalBottomSheet<({String mode, int? placeId})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusXl),
      ),
    ),
    builder: (_) => _ReminderCueSheet(
      initialMode: initialMode,
      initialPlaceId: initialPlaceId,
      title: title,
    ),
  );
}

class _ReminderCueSheet extends StatefulWidget {
  const _ReminderCueSheet({
    required this.initialMode,
    required this.initialPlaceId,
    required this.title,
  });

  final String initialMode;
  final int? initialPlaceId;
  final String title;

  @override
  State<_ReminderCueSheet> createState() => _ReminderCueSheetState();
}

class _ReminderCueSheetState extends State<_ReminderCueSheet> {
  List<Place> _places = const [];
  String? _placesError;
  late String _mode = widget.initialMode;
  late int? _placeId = widget.initialPlaceId;

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
    } catch (_) {
      if (mounted) {
        setState(() => _placesError = 'Your saved places could not be loaded.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.space4,
        right: AppTheme.space4,
        top: AppTheme.space4,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.space4,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space4),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'A cue reminds you when you arrive at, or leave, a saved place.',
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            const SizedBox(height: AppTheme.space4),
            ReminderCueControl(
              title: 'Reminder cue',
              mode: _mode,
              places: _places,
              triggerPlaceId: _placeId,
              onModeChanged: (mode) => setState(() => _mode = mode),
              onPlaceChanged: (placeId) => setState(() => _placeId = placeId),
            ),
            if (_placesError != null) ...[
              const SizedBox(height: AppTheme.space3),
              Text(
                _placesError!,
                style: const TextStyle(fontSize: 12, color: AppTheme.error),
              ),
            ],
            const SizedBox(height: AppTheme.space5),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: FilledButton(
                    onPressed: _mode != cueByTime && _placeId == null
                        ? null
                        : () => Navigator.of(context).pop((
                            mode: _mode,
                            placeId: _mode == cueByTime ? null : _placeId,
                          )),
                    child: const Text('Save reminder'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
