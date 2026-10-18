import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';
import '../../../places/domain/entities/place.dart';
import '../../../places/domain/repositories/places_repository.dart';
import '../../../requests/domain/entities/service_request.dart';
import '../../../requests/domain/repositories/requests_repository.dart';
import '../../../requests/presentation/widgets/reminder_cue.dart';
import '../../domain/entities/recurring_rule.dart';
import '../bloc/recurring_bloc.dart';
import '../bloc/recurring_event.dart';
import '../bloc/recurring_state.dart';

/// Recurring rules — the chores that come back on their own.
///
/// Reached from Today rather than given a tab of its own: the rules are set up
/// once and then left alone, so they do not earn a permanent destination.
class RecurringPage extends StatelessWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RecurringBloc>()..add(const RecurringRulesRequested()),
      child: const _RecurringView(),
    );
  }
}

class _RecurringView extends StatelessWidget {
  const _RecurringView();

  Future<void> _add(BuildContext context) async {
    final bloc = context.read<RecurringBloc>();

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (_) => const AddRecurringRuleSheet(),
    );

    if (created == true) {
      bloc.add(const RecurringRulesRequested());
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RecurringRule rule,
  ) async {
    final bloc = context.read<RecurringBloc>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this rule?'),
        content: Text(
          '“${rule.title}” stops repeating. Requests it already created keep '
          'their own history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bloc.add(RecurringRuleDeleted(rule.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        title: const Text('Recurring rules'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<RecurringBloc>().add(const RecurringRulesRequested()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context),
        backgroundColor: AppTheme.secondary,
        foregroundColor: AppTheme.onSecondary,
        tooltip: 'Add a recurring rule',
        child: const Icon(Icons.add, size: 28),
      ),
      body: BlocConsumer<RecurringBloc, RecurringState>(
        listener: (context, state) {
          if (state is RecurringActionSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            context.read<RecurringBloc>().add(const RecurringRulesRequested());
          } else if (state is RecurringFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.coralSoft,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RecurringLoading || state is RecurringInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.secondary),
            );
          }

          if (state is RecurringFailure) {
            return Padding(
              padding: const EdgeInsets.all(AppTheme.space4),
              child: WarmEmptyState(
                title: 'Your rules did not load',
                description: '${state.message}\nTry again in a moment.',
                icon: Icons.cloud_off_outlined,
                action: FilledButton(
                  onPressed: () => context.read<RecurringBloc>().add(
                    const RecurringRulesRequested(),
                  ),
                  child: const Text('Try again'),
                ),
              ),
            );
          }

          if (state is! RecurringLoaded) {
            return const SizedBox.shrink();
          }

          if (state.rules.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppTheme.space4),
              child: WarmEmptyState(
                title: 'Nothing repeats yet',
                description:
                    'Milk every Thursday, the bins every month on the 31st. Add '
                    'the rhythm once and the request writes itself.',
                icon: Icons.repeat,
                action: FilledButton(
                  onPressed: () => _add(context),
                  child: const Text('Add a rule'),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.secondary,
            onRefresh: () async => context.read<RecurringBloc>().add(
              const RecurringRulesRequested(),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                SectionHeader(title: 'Rules', count: state.rules.length),
                const SizedBox(height: AppTheme.space3),
                for (final rule in state.rules)
                  _RuleCard(
                    rule: rule,
                    onToggle: () => context.read<RecurringBloc>().add(
                      RecurringRuleToggled(id: rule.id, active: !rule.active),
                    ),
                    onDelete: () => _confirmDelete(context, rule),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.onToggle,
    required this.onDelete,
  });

  final RecurringRule rule;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: WarmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rule.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
                PriorityChip(
                  label: rule.active ? 'Active' : 'Paused',
                  tone: rule.active ? WarmTone.success : WarmTone.neutral,
                  dot: true,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                rule.cadenceLabel,
                if (rule.assigneeName != null) '→ ${rule.assigneeName}',
                if (rule.placeName != null) rule.placeName!,
              ].join(' · '),
              style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
            ),
            if (rule.reminderCue != null) ...[
              const SizedBox(height: 2),
              Text(
                rule.reminderCue!,
                style: const TextStyle(fontSize: 12, color: AppTheme.muted),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              rule.active
                  ? 'Next run ${_date(rule.nextRunOn)}'
                  : 'Paused · next run was ${_date(rule.nextRunOn)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(height: AppTheme.space3),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onToggle,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: Text(rule.active ? 'Pause' : 'Resume'),
                  ),
                ),
                const SizedBox(width: AppTheme.space2),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    tooltip: 'Remove ${rule.title}',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _date(DateTime? date) => date == null
      ? 'not scheduled'
      : '${date.day} ${_months[date.month - 1]} ${date.year}';
}

/// The create form: cadence, then the field that cadence needs, then who, where
/// and the reminder cue — the same cue control quick add uses.
class AddRecurringRuleSheet extends StatefulWidget {
  const AddRecurringRuleSheet({super.key});

  @override
  State<AddRecurringRuleSheet> createState() => _AddRecurringRuleSheetState();
}

class _AddRecurringRuleSheetState extends State<AddRecurringRuleSheet> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _quantity = TextEditingController();

  List<Place> _places = const [];
  List<HouseholdMember> _members = const [];

  String _cadence = 'weekly';
  int _weekday = apiWeekdayFromDart(DateTime.now().weekday);
  int _dayOfMonth = 1;

  int? _assigneeId;
  int? _placeId;
  int? _triggerPlaceId;
  String _cue = cueByTime;

  @override
  void initState() {
    super.initState();
    _loadChoices();
  }

  Future<void> _loadChoices() async {
    // A missing roster or place list must not stop a rule being created.
    try {
      final members = await getIt<RequestsRepository>().members();

      if (mounted) {
        setState(() => _members = members);
      }
    } catch (_) {
      // Left empty; the picker simply offers nothing.
    }

    try {
      final places = await getIt<PlacesRepository>().places();

      if (mounted) {
        setState(() => _places = places);
      }
    } catch (_) {
      // Same.
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _submit() {
    if (_title.text.trim().isEmpty) {
      return;
    }

    context.read<RecurringBloc>().add(
      RecurringRuleCreated(
        title: _title.text.trim(),
        cadence: _cadence,
        weekday: _cadence == 'weekly' ? _weekday : null,
        dayOfMonth: _cadence == 'monthly' ? _dayOfMonth : null,
        quantity: _quantity.text.trim().isEmpty ? null : _quantity.text.trim(),
        assigneeId: _assigneeId,
        placeId: _placeId,
        triggerPlaceId: _cue == cueByTime ? null : _triggerPlaceId,
        triggerDirection: _cue == cueByTime ? null : _cue,
      ),
    );

    Navigator.of(context).pop(true);
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
            const Text(
              'Add a recurring rule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'A fresh request every cycle. Nothing is reset — each cycle is its '
              'own task.',
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            const SizedBox(height: AppTheme.space4),

            TextField(
              controller: _title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'What repeats?'),
            ),
            const SizedBox(height: AppTheme.space3),
            TextField(
              controller: _quantity,
              decoration: const InputDecoration(
                labelText: 'How much? (optional)',
              ),
            ),

            const SizedBox(height: AppTheme.space4),
            const Text(
              'How often',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: AppTheme.space2),
            Wrap(
              spacing: AppTheme.space2,
              runSpacing: AppTheme.space2,
              children: [
                _cadenceChip('daily', 'Every day'),
                _cadenceChip('weekly', 'Every week'),
                _cadenceChip('monthly', 'Every month'),
              ],
            ),

            if (_cadence == 'weekly') ...[
              const SizedBox(height: AppTheme.space3),
              DropdownButtonFormField<int>(
                initialValue: _weekday,
                decoration: const InputDecoration(labelText: 'On which day'),
                items: [
                  for (var day = 0; day < weekdayNames.length; day++)
                    DropdownMenuItem(
                      value: day,
                      child: Text('Every ${weekdayNames[day]}'),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _weekday = value ?? _weekday),
              ),
            ],

            if (_cadence == 'monthly') ...[
              const SizedBox(height: AppTheme.space3),
              DropdownButtonFormField<int>(
                initialValue: _dayOfMonth,
                decoration: const InputDecoration(
                  labelText: 'On which day of the month',
                ),
                items: [
                  for (var day = 1; day <= 31; day++)
                    DropdownMenuItem(
                      value: day,
                      child: Text('The ${ordinal(day)}'),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _dayOfMonth = value ?? _dayOfMonth),
              ),
            ],

            const SizedBox(height: AppTheme.space4),
            Wrap(
              spacing: AppTheme.space2,
              runSpacing: AppTheme.space2,
              children: [
                _pickerChip(
                  icon: Icons.person_outline,
                  label:
                      _members
                          .where((member) => member.userId == _assigneeId)
                          .firstOrNull
                          ?.name ??
                      'For anyone',
                  onTap: () async {
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
                  },
                ),
                _pickerChip(
                  icon: Icons.storefront_outlined,
                  label:
                      _places
                          .where((place) => place.id == _placeId)
                          .firstOrNull
                          ?.name ??
                      'Any shop',
                  onTap: () async {
                    final chosen = await showChoiceSheet<Place>(
                      context: context,
                      title: 'Where is it bought?',
                      options: _places,
                      label: (place) => place.name,
                      current: _places
                          .where((place) => place.id == _placeId)
                          .firstOrNull,
                    );

                    if (chosen != null) {
                      setState(() => _placeId = chosen.id);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: AppTheme.space4),
            ReminderCueControl(
              mode: _cue,
              places: _places,
              triggerPlaceId: _triggerPlaceId,
              onModeChanged: (mode) => setState(() {
                _cue = mode;
                _triggerPlaceId ??= _placeId;
              }),
              onPlaceChanged: (placeId) =>
                  setState(() => _triggerPlaceId = placeId),
            ),

            const SizedBox(height: AppTheme.space5),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Save rule'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cadenceChip(String value, String label) {
    final selected = _cadence == value;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _cadence = value),
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

  Widget _pickerChip({
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
