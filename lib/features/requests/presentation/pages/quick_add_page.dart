import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../domain/entities/service_request.dart';
import '../bloc/requests_bloc.dart';
import '../bloc/requests_event.dart';
import '../bloc/requests_state.dart';

class QuickAddPage extends StatelessWidget {
  const QuickAddPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RequestsBloc>(),
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
  final TextEditingController _store = TextEditingController();

  String _priority = 'normal';
  DateTime? _dueAt;
  int? _assigneeId;

  List<HouseholdMember> _members = const [];

  @override
  void initState() {
    super.initState();
    context.read<RequestsBloc>().add(const BoardRequested());
  }

  @override
  void dispose() {
    _title.dispose();
    _quantity.dispose();
    _store.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick add')),
      body: SafeArea(
        child: BlocConsumer<RequestsBloc, RequestsState>(
          listener: (context, state) {
            if (state is RequestsActionSuccess) {
              context.pop(true);
            } else if (state is RequestsFailure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is RequestsBoardLoaded) {
              setState(() => _members = state.members);
            }
          },
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'What is needed?',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _quantity,
                  decoration: const InputDecoration(
                    labelText: 'Quantity (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _store,
                  decoration: const InputDecoration(
                    labelText: 'Store (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (value) =>
                      setState(() => _priority = value ?? 'normal'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickDue,
                  icon: const Icon(Icons.event),
                  label: Text(
                    _dueAt == null ? 'No due date' : 'Due ${_dueAt!.toLocal()}',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: _assigneeId,
                  decoration: const InputDecoration(labelText: 'Assign to'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Unassigned'),
                    ),
                    for (final member in _members)
                      DropdownMenuItem<int?>(
                        value: member.userId,
                        child: Text(member.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _assigneeId = value),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: state is RequestsLoading
                      ? null
                      : () {
                          if (_title.text.trim().isEmpty) {
                            return;
                          }

                          context.read<RequestsBloc>().add(
                            RequestSubmitted(
                              title: _title.text.trim(),
                              quantity: _quantity.text.trim().isEmpty
                                  ? null
                                  : _quantity.text.trim(),
                              storeName: _store.text.trim().isEmpty
                                  ? null
                                  : _store.text.trim(),
                              priority: _priority,
                              dueAt: _dueAt,
                              assigneeId: _assigneeId,
                            ),
                          );
                        },
                  child: state is RequestsLoading
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
}
