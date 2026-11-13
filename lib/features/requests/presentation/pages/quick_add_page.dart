import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../places/domain/entities/place.dart';
import '../../../places/domain/repositories/places_repository.dart';
import '../../domain/entities/service_request.dart';
import '../bloc/requests_bloc.dart';
import '../bloc/requests_event.dart';
import '../bloc/requests_state.dart';
import '../widgets/reminder_cue.dart';

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

class _ItemRow {
  final TextEditingController name = TextEditingController();
  final TextEditingController quantity = TextEditingController();

  void dispose() {
    name.dispose();
    quantity.dispose();
  }
}

class _QuickAddFormState extends State<_QuickAddForm> {
  final TextEditingController _title = TextEditingController();
  final List<_ItemRow> _items = [_ItemRow()];

  List<HouseholdMember> _members = const [];
  List<Place> _places = const [];

  int? _assigneeId;
  int? _shopId;
  int? _triggerPlaceId;
  DateTime? _dueAt;

  /// One of [cueByTime], [cueOnArrival], [cueOnLeaving].
  String _remind = cueByTime;

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
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(_ItemRow());
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
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
    final chosen = await showChoiceSheet<HouseholdMember>(
      context: context,
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
    final chosen = await showChoiceSheet<Place>(
      context: context,
      title: 'Where is it bought?',
      options: _places,
      label: _placeLabel,
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

  String _placeLabel(Place place) => place.kindLabel == null
      ? place.name
      : '${place.name} · ${place.kindLabel}';

  void _submit() {
    final validItems = _items
        .map((r) => {
              'name': r.name.text.trim(),
              'quantity_asked': r.quantity.text.trim().isEmpty ? null : r.quantity.text.trim(),
            })
        .where((m) => (m['name'] as String).isNotEmpty)
        .toList();

    var title = _title.text.trim();
    if (title.isEmpty) {
      if (validItems.isEmpty) return;
      title = validItems.map((i) => i['name'] as String).join(', ');
    }

    final byTime = _remind == cueByTime;
    final primaryQty = validItems.isNotEmpty ? validItems.first['quantity_asked'] : null;

    context.read<RequestsBloc>().add(
      RequestSubmitted(
        title: title,
        quantity: primaryQty,
        items: validItems.isNotEmpty ? validItems : null,
        dueAt: _dueAt,
        assigneeId: _assigneeId,
        placeId: _shopId,
        triggerPlaceId: byTime ? null : _triggerPlaceId,
        triggerDirection: byTime ? null : _remind,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = _members.where((m) => m.userId == _assigneeId).firstOrNull;
    final shop = _places.where((p) => p.id == _shopId).firstOrNull;

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
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 16, color: AppTheme.ink),
                  decoration: const InputDecoration(
                    labelText: 'Task / Errand Title (optional)',
                    hintText: 'e.g. Grocery run or Hardware store',
                    hintStyle: TextStyle(fontSize: 14, color: AppTheme.muted),
                  ),
                ),
                const SizedBox(height: AppTheme.space4),

                // Multi-item section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Items to pick up',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add, size: 16, color: AppTheme.secondary),
                      label: const Text(
                        'Add item',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space2),
                for (var i = 0; i < _items.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _items[i].name,
                            autofocus: i == 0,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Item name (e.g. Milk)',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space2),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _items[i].quantity,
                            decoration: const InputDecoration(
                              hintText: 'Asked qty (e.g. 2L)',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        if (_items.length > 1) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppTheme.muted),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Remove item',
                            onPressed: () => _removeItem(i),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
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

                // The same control the detail sheet and a recurring rule use.
                ReminderCueControl(
                  mode: _remind,
                  places: _places,
                  triggerPlaceId: _triggerPlaceId,
                  onModeChanged: (mode) => setState(() {
                    _remind = mode;
                    _triggerPlaceId ??= _shopId;
                  }),
                  onPlaceChanged: (placeId) =>
                      setState(() => _triggerPlaceId = placeId),
                ),

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
}
