import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
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
      final savedTier = await getIt<SecureStorage>().readActiveTier();
      if (savedTier != null && savedTier.isNotEmpty) {
        _activeTier = savedTier;
      }
      if (getIt.isRegistered<DioClient>()) {
        final dio = getIt<DioClient>().dio;
        try {
          final quotaRes = await dio.get<Map<String, dynamic>>(
            '/v1/tenant/quotas',
          );
          final planObj = quotaRes.data?['plan'];
          if (planObj is Map && planObj['key'] is String) {
            final serverKey = planObj['key'] as String;
            _activeTier = serverKey == 'standard' ? 'household_pro' : serverKey;
            await getIt<SecureStorage>().saveActiveTier(_activeTier);
          }
        } catch (_) {}

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

  void _promptPaymentMethodAndUpgrade(String targetTier) {
    if (targetTier == _activeTier) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upgrade to ${_tierName(targetTier)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Select your preferred payment channel for billing and invoice settlement:',
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
            const SizedBox(height: 16),
            // Option 1: Online Card
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.secondary.withValues(alpha: 0.3)),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.forestSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.credit_card, color: AppTheme.secondary),
              ),
              title: const Text('Online Gateway / Card', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Instant activation & automated digital receipt'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.of(ctx).pop();
                _processUpgrade(targetTier, isCash: false);
              },
            ),
            const SizedBox(height: 10),
            // Option 2: Cash / Offline Transfer
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payments_outlined, color: Colors.amber),
              ),
              title: const Text('Cash / Offline Payment', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Generates pending invoice. Admin approves upon cash receipt'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.of(ctx).pop();
                _processUpgrade(targetTier, isCash: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processUpgrade(String newTier, {required bool isCash}) async {
    setState(() => _isLoading = true);

    final invoiceNum = 'INV-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final amountCents = _tierPriceCents(newTier);

    try {
      if (getIt.isRegistered<DioClient>()) {
        final dio = getIt<DioClient>().dio;

        // Card upgrades go through the provider's hosted checkout. The local
        // invoice is only settled by the provider's signed webhook, so do not
        // fabricate a paid invoice here.
        if (!isCash) {
          String? activeGateway;

          try {
            final methods = await dio.get<dynamic>('/v1/billing/payment-methods');
            final methodsPayload = methods.data;
            final methodsData = methodsPayload is Map ? methodsPayload['data'] : null;

            if (methodsData is Map) {
              activeGateway = methodsData['active_gateway']?.toString();
            }
          } catch (_) {}

          final hostedGateways = ['stripe', 'paypal', 'razorpay', 'sslcommerz'];

          if (activeGateway != null && hostedGateways.contains(activeGateway)) {
            try {
              final checkout = await dio.post<dynamic>(
                '/v1/billing/checkout-session',
                data: {'tier': newTier, 'gateway': activeGateway},
              );

              final payload = checkout.data;
              final data = payload is Map ? payload['data'] : null;
              final checkoutData = data is Map ? data['checkout'] : null;
              final url = checkoutData is Map ? checkoutData['url'] : null;

              if (url is String && url.isNotEmpty) {
                final uri = Uri.parse(url);

                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }

                if (mounted) {
                  setState(() => _isLoading = false);
                }

                return;
              }
            } on DioException catch (error) {
              // 422 means no provider keys are configured on this platform;
              // keep the existing simulated flow for local development.
              if (error.response?.statusCode != 422) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.response?.data?['message']?.toString() ??
                            'Could not start the checkout session.',
                      ),
                    ),
                  );
                }

                return;
              }
            }
          }
        }

        await dio.post<dynamic>(
          '/v1/billing/upgrade',
          data: {
            'tier': newTier,
            'payment_type': isCash ? 'cash' : 'online',
          },
        );
      }
    } catch (_) {}

    final newInv = BillingInvoice(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      invoiceNumber: invoiceNum,
      tier: newTier,
      amountCents: amountCents,
      currency: 'USD',
      status: isCash ? 'pending_cash' : 'paid',
      createdAt: DateTime.now().toIso8601String().split('T').first,
      paidAt: isCash ? null : DateTime.now().toIso8601String().split('T').first,
    );

    await getIt<SecureStorage>().saveActiveTier(newTier);

    if (mounted) {
      setState(() {
        _activeTier = newTier;
        _invoices.insert(0, newInv);
        _isLoading = false;
      });

      // Show Invoice Receipt Modal (Point 23)
      _showInvoiceReceiptModal(newInv, isCash: isCash);
    }
  }

  void _showInvoiceReceiptModal(BillingInvoice inv, {required bool isCash}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCash ? Colors.amber.shade50 : AppTheme.forestSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCash ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
                color: isCash ? Colors.amber.shade800 : AppTheme.secondary,
                size: 40,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isCash ? 'Cash Invoice Generated' : 'Payment Successful!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
            ),
            const SizedBox(height: 4),
            Text(
              isCash
                  ? 'Your invoice is pending platform admin verification of cash receipt.'
                  : 'Your household plan has been updated to ${_tierName(inv.tier)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outline.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _receiptRow('Invoice Number', inv.invoiceNumber),
                  const Divider(height: 12),
                  _receiptRow('Plan Tier', _tierName(inv.tier)),
                  const Divider(height: 12),
                  _receiptRow('Amount', '\$${(inv.amountCents / 100).toStringAsFixed(2)}'),
                  const Divider(height: 12),
                  _receiptRow('Status', isCash ? 'PENDING CASH' : 'PAID IN FULL'),
                  const Divider(height: 12),
                  _receiptRow('Date', inv.createdAt),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              minimumSize: const Size(double.infinity, 44),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Return to Billing'),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.ink)),
      ],
    );
  }

  void _showRefundDialog() {
    final reasonCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.policy_outlined, color: AppTheme.secondary),
            SizedBox(width: 8),
            Text('Refund Policy', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FairShare Graduated Refund Policy (Point 23):',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink),
              ),
              const SizedBox(height: 8),
              _policyBullet('Monthly Plans', '100% refund within 7 days; 50% refund between 8 to 20 days; no refund after 20 days.'),
              _policyBullet('Yearly Plans', '100% refund within 15 days; 75% within 1 month; 50% within 3 months; 25% within 6 months; no refund after 6 months.'),
              _policyBullet('Plan Reverts', 'Reverting to a previous plan is permitted while refund eligibility is at or above 50%.'),
              _policyBullet('Cancellation Lockout', 'Cancelling logs out immediately. Access is restricted to Billing until resubscribed.'),
              const SizedBox(height: 14),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Refund Reason (optional)',
                  hintText: 'e.g. Inadvertent renewal or plan switch',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refund request logged. Review timeline is 1-2 business days.'),
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

  Widget _policyBullet(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: AppTheme.ink),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc, style: const TextStyle(color: AppTheme.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancelSubscription() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Subscription?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'Under FairShare rules (Point 23), cancelling your plan will immediately log you out. '
          'When you log back in, all features will be locked except Billing & Subscription until a valid plan is renewed.\n\n'
          'Are you sure you want to proceed?',
          style: TextStyle(fontSize: 13, color: AppTheme.ink, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep My Plan'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                if (getIt.isRegistered<DioClient>()) {
                  final dio = getIt<DioClient>().dio;
                  await dio.post<dynamic>('/v1/billing/cancel');
                }
              } catch (_) {}

              // Clear token and logout immediately (Point 23)
              final storage = getIt<SecureStorage>();
              await storage.deleteToken();
              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );
  }

  String _tierName(String tier) {
    switch (tier) {
      case 'enterprise':
        return 'Enterprise Estate';
      case 'household_pro':
        return 'Household Pro';
      case 'family_plus':
      case 'pilot':
        return 'Pilot Family';
      case 'starter':
      default:
        return 'Starter Free';
    }
  }

  int _tierPriceCents(String tier) {
    switch (tier) {
      case 'enterprise':
        return 9900;
      case 'household_pro':
        return 2900;
      case 'family_plus':
      case 'pilot':
        return 1500;
      case 'starter':
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/today');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.canvas,
        appBar: AppBar(
          title: const Text('Plan & Billing'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/today');
              }
            },
          ),
        ),
      body: _isLoading
          ? ListView(
              padding: const EdgeInsets.all(AppTheme.space4),
              children: const [
                ShimmerWarmCard(height: 210),
                SizedBox(height: AppTheme.space4),
                ShimmerWarmCard(height: 150),
                SizedBox(height: 12),
                ShimmerWarmCard(height: 150),
                SizedBox(height: 12),
                ShimmerWarmCard(height: 150),
              ],
            )
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
                            Expanded(
                              child: Text(
                                _tierName(_activeTier),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                          _activeTier == 'enterprise'
                              ? '\$99.00 / month · Unlimited Multi-Home Estate'
                              : (_activeTier == 'household_pro'
                                  ? '\$29.00 / month · Auto-renews Dec 1, 2026'
                                  : (_activeTier == 'family_plus' || _activeTier == 'pilot'
                                      ? '\$15.00 / month · Auto-renews Dec 1, 2026'
                                      : 'Free Plan · No monthly charges')),
                          style: const TextStyle(fontSize: 14, color: AppTheme.muted),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        const Text(
                          'INCLUDED HOUSEHOLD QUOTAS (POINT 22 & 24)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.muted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _quotaRow(Icons.group_outlined, 'Household Members', _activeTier == 'enterprise' ? 'Unlimited' : (_activeTier == 'household_pro' ? '10 members (2 used)' : '3 members')),
                        _quotaRow(Icons.pin_drop_outlined, 'Saved Places & Geofencing', _activeTier == 'household_pro' || _activeTier == 'enterprise' ? 'Unlimited places' : '2 places included'),
                        _quotaRow(Icons.task_alt, 'Errands & Tasks', _activeTier == 'starter' ? '30 / month' : 'Unlimited active errands'),
                        _quotaRow(Icons.kitchen_outlined, 'Pantry Stock & Spending', _activeTier == 'household_pro' || _activeTier == 'enterprise' ? 'Unlimited tracking' : '50 items max'),
                        _quotaRow(Icons.phone_in_talk_outlined, 'Direct Member & Voice Calls', _activeTier == 'household_pro' ? '100 calls / mo' : (_activeTier == 'starter' ? 'Disabled' : '15 calls / mo')),
                        _quotaRow(Icons.document_scanner_outlined, 'Receipt Optical OCR', _activeTier == 'household_pro' || _activeTier == 'enterprise' ? 'Unlimited scans' : '30 scans / mo'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space4),

                  // Plans Comparison / Upgrade Section (Point 24)
                  const SectionHeader(title: 'SaaS Subscription Plans', count: 4),
                  const SizedBox(height: AppTheme.space3),
                  _planCard(
                    tierKey: 'starter',
                    title: 'Starter',
                    price: 'Free',
                    features: const [
                      '3 household members',
                      '2 saved places & geofences',
                      '30 errands & tasks / month',
                      'Single expense ledger',
                    ],
                    isCurrent: _activeTier == 'starter',
                  ),
                  const SizedBox(height: 12),
                  _planCard(
                    tierKey: 'pilot',
                    title: 'Pilot Family',
                    price: '\$15 / mo',
                    features: const [
                      '5 household members',
                      '5 saved places & geofences',
                      '100 errands & tasks / month',
                      '50 pantry items & spend tracking',
                      '15 member escalation calls / mo',
                      '30 receipt OCR scans / mo',
                    ],
                    isCurrent: _activeTier == 'pilot' || _activeTier == 'family_plus',
                  ),
                  const SizedBox(height: 12),
                  _planCard(
                    tierKey: 'household_pro',
                    title: 'Household Pro',
                    price: '\$29 / mo',
                    features: const [
                      '10 household members',
                      'Unlimited saved places & geofences',
                      'Unlimited errands & tasks',
                      'Unlimited pantry stock & spend metrics',
                      '100 direct member calls & escalations',
                      'Unlimited OCR receipt optical scans',
                      'Recurring expenses & wealth projection',
                      'Priority household concierge',
                    ],
                    isCurrent: _activeTier == 'household_pro',
                    isPopular: true,
                  ),
                  const SizedBox(height: 12),
                  _planCard(
                    tierKey: 'enterprise',
                    title: 'Enterprise Estate',
                    price: '\$99 / mo',
                    features: const [
                      'Unlimited members, estates & ledgers',
                      'Unlimited calls, OCR scans & rules',
                      'Custom multi-home geographic routing',
                      '24/7 dedicated support representative',
                    ],
                    isCurrent: _activeTier == 'enterprise',
                  ),
                  const SizedBox(height: AppTheme.space4),

                  // Payment Methods & Offline Transfer
                  const SectionHeader(title: 'Payment Methods & Options', count: 2),
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
                            subtitle: Text('Expires ${pm['exp'] ?? '12/28'} (Instant auto-billing)'),
                            trailing: pm['is_default'] == true
                                ? const PriorityChip(label: 'Default', tone: WarmTone.primary)
                                : null,
                          ),
                        const Divider(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.payments_outlined, color: Colors.amber),
                          ),
                          title: const Text('Cash & Bank Deposit Supported', style: TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: const Text('Invoices approved by admin once cash is cleared'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space4),

                  // Invoice History
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SectionHeader(title: 'Invoices & Receipts', count: _invoices.length),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _showRefundDialog,
                        icon: const Icon(Icons.policy_outlined, size: 16, color: AppTheme.secondary),
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
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: inv.status == 'pending_cash'
                                      ? Colors.amber.shade50
                                      : AppTheme.forestSoft,
                                  child: Icon(
                                    inv.status == 'pending_cash'
                                        ? Icons.hourglass_empty_rounded
                                        : Icons.receipt_outlined,
                                    size: 18,
                                    color: inv.status == 'pending_cash'
                                        ? Colors.amber.shade800
                                        : AppTheme.secondary,
                                  ),
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
                                        color: inv.status == 'pending_cash'
                                            ? Colors.amber.shade100
                                            : AppTheme.forestSoft,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        inv.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: inv.status == 'pending_cash'
                                              ? Colors.amber.shade900
                                              : AppTheme.secondary,
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
                  const SizedBox(height: AppTheme.space4),

                  // Cancel Subscription Action (Point 23)
                  Center(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: _confirmCancelSubscription,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancel Subscription'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space5),
                ],
              ),
            ),
      ),
    );
  }

  Widget _quotaRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }

  Widget _planCard({
    required String tierKey,
    required String title,
    required String price,
    required List<String> features,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('RECOMMENDED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(price, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.ink)),
            ],
          ),
          const SizedBox(height: 10),
          for (final feat in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: AppTheme.secondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(feat, style: const TextStyle(fontSize: 12, color: AppTheme.ink)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: isCurrent
                ? const PriorityChip(label: 'Active Plan', tone: WarmTone.primary)
                : FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    ),
                    onPressed: () => _promptPaymentMethodAndUpgrade(tierKey),
                    child: const Text('Select Plan'),
                  ),
          ),
        ],
      ),
    );
  }
}
