import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';
import '../../../places/domain/entities/place.dart';
import '../../../places/domain/repositories/places_repository.dart';
import '../../domain/entities/service_request.dart';
import '../bloc/requests_bloc.dart';
import '../bloc/requests_event.dart';
import '../bloc/requests_state.dart';

/// Ask for one thing, then say when you want to be reminded.
///
/// One field, three chips and a reminder choice — the whole request fits on one
/// screen, so a basic ask takes seconds rather than a form.
class QuickAddPage extends StatelessWidget {
  const QuickAddPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RequestsBloc>()..add(const BoardRequested()),
      child: const _QuickAddForm(),
    );
  }
}

class _QuickAddForm extends StatefulWidget {
  const _QuickAddForm();

  @override
  State<_QuickAddForm> createState() => _QuickAddFormState();
}

class _QuickAddFormState extends State<_QuickAddForm> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _quantity = TextEditingController();

  List<HouseholdMember> _members = const [];
  List<Place> _places = const [];

  int? _assigneeId;
  int? _shopId;
  int? _triggerPlaceId;
  DateTime? _dueAt;

  /// time | enter | exit
  String _remind = 'time';

  @override
  void initState() {
    super.initState();
    context.read<RequestsBloc>().add(const BoardRequested());
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final places = await getIt<PlacesRepository>().places();
      if (mounted) {
        setState(() => _places = places);
      }
    } catch (_) {
      // A missing place list must not stop the request being created.
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _dueAt = DateTime(date.year, date.month, date.day, 18));
    }
  }

  Future<void> _pickMember() async {
    final chosen = await _chooseFrom<HouseholdMember>(
      title: 'Who is it for?',
      options: _members,
      label: (member) => member.name,
      current: _members
          .where((member) => member.userId == _assigneeId)
          .firstOrNull,
    );

    if (chosen != null) {
      setState(() => _assigneeId = chosen.userId);
    }
  }

  Future<void> _pickShop() async {
    final chosen = await _chooseFrom<Place>(
      title: 'Where is it bought?',
      options: _places,
      label: (place) => place.kindLabel == null
          ? place.name
          : '${place.name} · ${place.kindLabel}',
      current: _places.where((place) => place.id == _shopId).firstOrNull,
    );

    if (chosen != null) {
      setState(() {
        _shopId = chosen.id;
        // A shop is the natural cue too, if none has been chosen.
        _triggerPlaceId ??= chosen.id;
      });
    }
  }

  Future<void> _pickTriggerPlace() async {
    final chosen = await _chooseFrom<Place>(
      title: 'Remind me at',
      options: _places,
      label: (place) => place.kindLabel == null
          ? place.name
          : '${place.name} · ${place.kindLabel}',
      current: _places
          .where((place) => place.id == _triggerPlaceId)
          .firstOrNull,
    );

    if (chosen != null) {
      setState(() => _triggerPlaceId = chosen.id);
    }
  }

  Future<T?> _chooseFrom<T>({
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
                      trailing: identical(option, current)
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

  void _submit() {
    if (_title.text.trim().isEmpty) {
      return;
    }

    final locationTrigger = _remind == 'time';

    context.read<RequestsBloc>().add(
      RequestSubmitted(
        title: _title.text.trim(),
        quantity: _quantity.text.trim().isEmpty ? null : _quantity.text.trim(),
        dueAt: _dueAt,
        assigneeId: _assigneeId,
        placeId: _shopId,
        triggerPlaceId: locationTrigger ? null : _triggerPlaceId,
        triggerDirection: locationTrigger ? null : _remind,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = _members.where((m) => m.userId == _assigneeId).firstOrNull;
    final shop = _places.where((p) => p.id == _shopId).firstOrNull;
    final triggerPlace = _places
        .where((p) => p.id == _triggerPlaceId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('New request')),
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: BlocConsumer<RequestsBloc, RequestsState>(
          listener: (context, state) {
            if (state is RequestsActionSuccess) {
              context.pop(true);
            } else if (state is RequestsFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.coralSoft,
                ),
              );
            } else if (state is RequestsBoardLoaded) {
              setState(() => _members = state.members);
            }
          },
          builder: (context, state) {
            final busy = state is RequestsLoading;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                TextField(
                  controller: _title,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 18, color: AppTheme.ink),
                  decoration: const InputDecoration(
                    hintText: 'What do you need?',
                    hintStyle: TextStyle(fontSize: 18, color: AppTheme.muted),
                  ),
                ),
                const SizedBox(height: AppTheme.space3),
                TextField(
                  controller: _quantity,
                  decoration: const InputDecoration(
                    labelText: 'How much? (optional)',
                  ),
                ),
                const SizedBox(height: AppTheme.space4),

                // For · Where · By — each one tap, opening a sheet.
                Wrap(
                  spacing: AppTheme.space2,
                  runSpacing: AppTheme.space2,
                  children: [
                    _choiceChip(
                      icon: Icons.person_outline,
                      label: member?.name ?? 'For anyone',
                      onTap: _pickMember,
                    ),
                    _choiceChip(
                      icon: Icons.storefront_outlined,
                      label: shop?.name ?? 'Any shop',
                      onTap: _pickShop,
                    ),
                    _choiceChip(
                      icon: Icons.event_outlined,
                      label: _dueAt == null
                          ? 'No deadline'
                          : 'By ${_dueAt!.day}/${_dueAt!.month}',
                      onTap: _pickDue,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space5),

                SectionHeader(
                  title: 'Remind me',
                  count: _remind == 'time' ? 0 : 1,
                ),
                const SizedBox(height: AppTheme.space2),
                Wrap(
                  spacing: AppTheme.space2,
                  runSpacing: AppTheme.space2,
                  children: [
                    _remindChip('time', 'When it is due'),
                    _remindChip('enter', 'When I arrive'),
                    _remindChip('exit', 'When I leave'),
                  ],
                ),

                if (_remind != 'time') ...[
                  const SizedBox(height: AppTheme.space3),
                  _choiceChip(
                    icon: Icons.place_outlined,
                    label: triggerPlace == null
                        ? 'Choose a place'
                        : '${_remind == 'exit' ? 'Leaving' : 'Arriving at'} ${triggerPlace.name}',
                    onTap: _pickTriggerPlace,
                    wide: true,
                  ),
                  if (triggerPlace == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Pick the place that should set the reminder off — your office, or home.',
                        style: TextStyle(fontSize: 12, color: AppTheme.muted),
                      ),
                    ),
                ],

                const SizedBox(height: AppTheme.space5),
                FilledButton(
                  onPressed: busy ? null : _submit,
                  child: busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add request'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _choiceChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool wide = false,
  }) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 16, color: AppTheme.onSurfaceVariant),
      backgroundColor: AppTheme.surface,
      side: const BorderSide(color: Color(0x1F2B2D42)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.ink,
        ),
      ),
    );
  }

  Widget _remindChip(String value, String label) {
    final selected = _remind == value;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() {
        _remind = value;
        _triggerPlaceId ??= _shopId;
      }),
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
