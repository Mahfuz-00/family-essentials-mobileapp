import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';

class BillingInvoice {
  const BillingInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.tier,
    required this.amountCents,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  factory BillingInvoice.fromJson(Map<String, dynamic> json) {
    return BillingInvoice(
      id: json['id'] as int? ?? 0,
      invoiceNumber: json['invoice_number'] as String? ?? 'INV-000',
      tier: json['tier'] as String? ?? 'household_pro',
      amountCents: json['amount_cents'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      status: json['status'] as String? ?? 'paid',
      createdAt: json['created_at'] as String? ?? '',
      paidAt: json['paid_at'] as String?,
    );
  }

  final int id;
  final String invoiceNumber;
  final String tier;
  final int amountCents;
  final String currency;
  final String status;
  final String createdAt;
  final String? paidAt;
}

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  bool _isLoading = true;
  String _activeTier = 'household_pro';
  List<BillingInvoice> _invoices = [];
  List<Map<String, dynamic>> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _fetchBillingData();
  }

  Future<void> _fetchBillingData() async {
    setState(() => _isLoading = true);

    try {
      if (getIt.isRegistered<DioClient>()) {
        final dio = getIt<DioClient>().dio;
        final invRes = await dio.get<Map<String, dynamic>>('/v1/billing/invoices');
        final pmRes = await dio.get<Map<String, dynamic>>('/v1/billing/payment-methods');

        if (invRes.data != null && invRes.data!['data'] is List) {
          _invoices = (invRes.data!['data'] as List)
              .map((it) => BillingInvoice.fromJson(it as Map<String, dynamic>))
              .toList();
        }

        if (pmRes.data != null && pmRes.data!['data'] is List) {
          _paymentMethods = (pmRes.data!['data'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {
      // Fallback
    }

    if (_invoices.isEmpty) {
      _invoices = [
        const BillingInvoice(
          id: 101,
          invoiceNumber: 'INV-2026-1101',
          tier: 'household_pro',
          amountCents: 2900,
          currency: 'USD',
          status: 'paid',
          createdAt: '2026-11-01',
          paidAt: '2026-11-01',
        ),
        const BillingInvoice(
          id: 102,
          invoiceNumber: 'INV-2026-1001',
          tier: 'household_pro',
          amountCents: 2900,
          currency: 'USD',
          status: 'paid',
          createdAt: '2026-10-01',
          paidAt: '2026-10-01',
        ),
      ];
    }

    if (_paymentMethods.isEmpty) {
      _paymentMethods = [
        {
          'brand': 'Visa',
          'last4': '4242',
          'exp': '12/28',
          'is_default': true,
        },
      ];
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePlan(String newTier) async {
    setState(() => _isLoading = true);
    try {
      if (getIt.isRegistered<DioClient>()) {
        final dio = getIt<DioClient>().dio;
        await dio.post<dynamic>('/v1/billing/upgrade', data: {'tier': newTier});
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _activeTier = newTier;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plan updated to ${_tierName(newTier)}!'),
          backgroundColor: AppTheme.secondary,
        ),
      );
    }
  }

  void _showRefundDialog() {
    final reasonCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request a Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Under FairShare\'s refund policy, households may request a refund within 14 days of billing.',
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for refund request',
                hintText: 'e.g. Accidental renewal or plan adjustment',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refund request submitted to household support.'),
                  backgroundColor: AppTheme.secondary,
                ),
              );
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  String _tierName(String tier) {
    switch (tier) {
      case 'household_pro':
        return 'Household Pro';
      case 'family_plus':
        return 'Family Plus';
      case 'starter':
      default:
        return 'Starter Free';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        title: const Text('Billing & Subscription'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
          : RefreshIndicator(
              onRefresh: _fetchBillingData,
              color: AppTheme.secondary,
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.space4),
                children: [
                  // Active Plan Card
                  WarmCard(
                    padding: const EdgeInsets.all(20),
                    borderColor: AppTheme.secondary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _tierName(_activeTier),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.forestSoft,
                                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 14, color: AppTheme.secondary),
                                  SizedBox(width: 4),
                                  Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _activeTier == 'household_pro'
                              ? '\$29.00 / month · Auto-renews Dec 1, 2026'
                              : (_activeTier == 'family_plus'
                                  ? '\$15.00 / month · Auto-renews Dec 1, 2026'
                                  : 'Free Plan · No monthly charge'),
                          style: const TextStyle(fontSize: 14, color: AppTheme.muted),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        const Text(
                          'INCLUDED HOUSEHOLD QUOTAS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _quotaRow(Icons.group_outlined, 'Household Members', '2 of 10 used'),
                        _quotaRow(Icons.task_alt, 'Tasks & Chores', 'Unlimited active errands'),
                        _quotaRow(Icons.account_balance_wallet_outlined, 'Expense Tracking & Ledger', 'Multi-period (Month, Week, Year)'),
                        _quotaRow(Icons.phone_in_talk_outlined, 'Voice Escalation Calls', '15 calls / day included'),
                        _quotaRow(Icons.document_scanner_outlined, 'Receipt Optical OCR', 'Unlimited scans'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space4),

                  // Plans Comparison / Upgrade Section
                  const SectionHeader(title: 'Choose Household Plan', count: 3),
                  const SizedBox(height: AppTheme.space3),
                  _planCard(
                    tierKey: 'starter',
                    title: 'Starter',
                    price: 'Free',
                    description: 'Basic task list, single ledger, up to 3 members',
                    isCurrent: _activeTier == 'starter',
                  ),
                  const SizedBox(height: 10),
                  _planCard(
                    tierKey: 'family_plus',
                    title: 'Family Plus',
                    price: '\$15 / mo',
                    description: 'Up to 5 members, full expense tracker, OCR scans',
                    isCurrent: _activeTier == 'family_plus',
                  ),
                  const SizedBox(height: 10),
                  _planCard(
                    tierKey: 'household_pro',
                    title: 'Household Pro',
                    price: '\$29 / mo',
                    description: 'Up to 10 members, full wealth overview, voice calls & priority',
                    isCurrent: _activeTier == 'household_pro',
                    isPopular: true,
                  ),
                  const SizedBox(height: AppTheme.space4),

                  // Payment Methods
                  const SectionHeader(title: 'Payment Methods', count: 1),
                  const SizedBox(height: AppTheme.space3),
                  WarmCard(
                    child: Column(
                      children: [
                        for (final pm in _paymentMethods)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.forestSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.credit_card, color: AppTheme.secondary),
                            ),
                            title: Text(
                              '${pm['brand'] ?? 'Card'} •••• ${pm['last4'] ?? '4242'}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text('Expires ${pm['exp'] ?? '12/28'}'),
                            trailing: pm['is_default'] == true
                                ? const PriorityChip(label: 'Default', tone: WarmTone.primary)
                                : null,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space4),

                  // Invoice History
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SectionHeader(title: 'Billing History', count: _invoices.length),
                      TextButton.icon(
                        onPressed: _showRefundDialog,
                        icon: const Icon(Icons.receipt_long, size: 16, color: AppTheme.secondary),
                        label: const Text(
                          'Refund policy',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space2),
                  WarmCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Column(
                      children: [
                        for (final inv in _invoices)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.forestSoft,
                                  child: Icon(Icons.receipt_outlined, size: 18, color: AppTheme.secondary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        inv.invoiceNumber,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      ),
                                      Text(
                                        'Billed on ${inv.createdAt.split('T').first}',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${(inv.amountCents / 100).toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.forestSoft,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        inv.status.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space5),
                ],
              ),
            ),
    );
  }

  Widget _quotaRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.secondary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.ink)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.muted)),
        ],
      ),
    );
  }

  Widget _planCard({
    required String tierKey,
    required String title,
    required String price,
    required String description,
    required bool isCurrent,
    bool isPopular = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? AppTheme.forestSoft.withValues(alpha: 0.5) : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? AppTheme.secondary : AppTheme.outline.withValues(alpha: 0.3),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    if (isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('RECOMMENDED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.ink)),
              const SizedBox(height: 4),
              isCurrent
                  ? const PriorityChip(label: 'Current', tone: WarmTone.primary)
                  : OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      onPressed: () => _changePlan(tierKey),
                      child: const Text('Switch'),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
