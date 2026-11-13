import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/service_request.dart';

class FulfillItemData {
  FulfillItemData({
    required String name,
    this.quantityAsked,
    String? quantityGot,
    this.isPicked = true,
    this.isExtra = false,
  })  : nameController = TextEditingController(text: name),
        gotController = TextEditingController(text: quantityGot ?? quantityAsked ?? '');

  final TextEditingController nameController;
  final String? quantityAsked;
  final TextEditingController gotController;
  bool isPicked;
  final bool isExtra;

  String get name => nameController.text.trim();

  void dispose() {
    nameController.dispose();
    gotController.dispose();
  }
}

class FulfillRequestSheet extends StatefulWidget {
  const FulfillRequestSheet({
    super.key,
    required this.request,
    required this.onComplete,
  });

  final ServiceRequest request;
  final void Function(Map<String, dynamic> payload) onComplete;

  static Future<void> show(
    BuildContext context, {
    required ServiceRequest request,
    required void Function(Map<String, dynamic> payload) onComplete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FulfillRequestSheet(
        request: request,
        onComplete: onComplete,
      ),
    );
  }

  @override
  State<FulfillRequestSheet> createState() => _FulfillRequestSheetState();
}

class _FulfillRequestSheetState extends State<FulfillRequestSheet> {
  late final List<FulfillItemData> _items;
  final TextEditingController _amount = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.request.items.isNotEmpty) {
      _items = widget.request.items
          .map((item) => FulfillItemData(
                name: item.name,
                quantityAsked: item.quantityAsked,
                quantityGot: item.quantityGot,
                isPicked: true,
              ))
          .toList();
    } else {
      _items = [
        FulfillItemData(
          name: widget.request.title,
          quantityAsked: widget.request.quantity,
          quantityGot: widget.request.quantityGot,
          isPicked: true,
        ),
      ];
    }
  }

  @override
  void dispose() {
    for (final it in _items) {
      it.dispose();
    }
    _amount.dispose();
    super.dispose();
  }

  void _addExtraItem() {
    setState(() {
      _items.add(
        FulfillItemData(
          name: '',
          quantityAsked: null,
          quantityGot: '1',
          isPicked: true,
          isExtra: true,
        ),
      );
    });
  }

  void _removeExtraItem(int index) {
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
  }

  void _submit() {
    final updatedItems = _items
        .where((it) => it.name.isNotEmpty)
        .map((it) => {
              'name': it.name,
              'quantity_asked': it.quantityAsked,
              'quantity_got': it.gotController.text.trim().isEmpty ? null : it.gotController.text.trim(),
              'is_picked': it.isPicked,
            })
        .toList();

    final firstGot = _items.firstOrNull?.gotController.text.trim();
    final amountParsed = double.tryParse(_amount.text.trim());
    final amountMinor = amountParsed != null ? (amountParsed * 100).round() : null;

    final payload = <String, dynamic>{
      'items': updatedItems,
      if (firstGot != null && firstGot.isNotEmpty) 'quantity_got': firstGot,
      if (amountMinor != null && amountMinor > 0) 'amount_minor': amountMinor,
    };

    widget.onComplete(payload);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 16,
      ),
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
          const SizedBox(height: 16),
          Text(
            'Fulfill: ${widget.request.title}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter the quantity you actually got for each item (asked vs. got).',
            style: TextStyle(fontSize: 13, color: AppTheme.muted),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final it = _items[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.canvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: it.isPicked,
                        activeColor: AppTheme.secondary,
                        onChanged: (val) => setState(() => it.isPicked = val ?? false),
                      ),
                      Expanded(
                        child: it.isExtra
                            ? Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: it.nameController,
                                      autofocus: true,
                                      decoration: const InputDecoration(
                                        hintText: 'Extra item name (e.g. Avocado)',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16, color: AppTheme.muted),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _removeExtraItem(index),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                  Text(
                                    'Asked: ${it.quantityAsked ?? '1'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 105,
                        child: TextField(
                          controller: it.gotController,
                          decoration: InputDecoration(
                            labelText: it.isExtra ? 'Qty Got' : 'Got Qty',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addExtraItem,
            icon: const Icon(Icons.add, size: 18, color: AppTheme.secondary),
            label: const Text(
              'Add extra grocery / item bought',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Total Cost / Expense (optional)',
              hintText: 'e.g. 14.50 (records to household ledger)',
              prefixIcon: Icon(Icons.attach_money, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Complete & Record'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
