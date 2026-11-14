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
  String _activeTier = 'pilot';
  List<BillingInvoice> _invoices = [];
  Map<String, dynamic>? _billingConfig;
  List<Map<String, dynamic>> _meters = [];

  /// Mirror of Backend/config/plans.php — the enforced catalogue.
  static const Map<String, Map<String, dynamic>> _plans = {
    'starter': {
      'label': 'Starter Family',
      'price': r'$0',
      'cadence': 'free',
      'seats': 2,
      'places': 2,
      'requests': 50,
      'calls': 0,
      'chats': 30,
      'scans': 5,
      'pantry': 20,
      'features': [
        'Up to 2 family members',
        '2 saved stores & geofences',
        '50 errands per month',
        '30 AI & member chat messages/mo',
        '5 receipt OCR scans/mo',
        'Basic pantry tracker (20 items)',
        'Member-to-member calling not included',
      ],
    },
    'pilot': {
      'label': 'Pilot Family Tier',
      'price': r'$14.99',
      'cadence': 'per month',
      'seats': 5,
      'places': 10,
      'requests': 300,
      'calls': 15,
      'chats': 300,
      'scans': 50,
      'pantry': 100,
      'features': [
        'Up to 5 family members',
        '10 saved stores & geofences',
        '300 errands per month',
        '15 member escalation calls/mo',
        '300 AI & member chat messages/mo',
        '50 receipt OCR scans/mo',
        'Full pantry inventory & cost tracking (100 items)',
        'Multi-period household expense ledgers',
      ],
    },
    'standard': {
      'label': 'Household Pro',
      'price': r'$24.99',
      'cadence': 'per month',
      'seats': 10,
      'places': 25,
      'requests': 1000,
      'calls': 60,
      'chats': 1500,
      'scans': 200,
      'pantry': 500,
      'features': [
        'Up to 10 family members',
        '25 saved stores & geofences',
        '1,000 errands per month',
        '60 member escalation calls/mo',
        '1,500 AI & member chat messages/mo',
        '200 receipt OCR scans/mo',
        'Extended pantry & auto-restock buffer (500 items)',
        'Complete wealth, assets, debt & tax tracking',
        'Household Data Vault & Portability JSON export',
      ],
    },
    'enterprise': {
      'label': 'Enterprise Household',
      'price': r'$49.99',
      'cadence': 'per month',
      'seats': 25,
      'places': 100,
      'requests': 5000,
      'calls': 9999,
      'chats': 9999,
      'scans': 1000,
      'pantry': 2500,
      'features': [
        'Up to 25 family members',
        '100 saved stores & geofences',
        '5,000 errands per month',
        'Unlimited member direct calling & escalation',
        'Unlimited AI family dispatcher & member chat',
        '1,000 receipt OCR scans/mo',
        'Pantry catalog up to 2,500 items',
        'Multi-generational property & estate tracking',
        'Priority platform support & concierge onboarding',
      ],
    },
  };

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
        _activeTier = _normaliseTier(savedTier);
      }
      if (getIt.isRegistered<DioClient>()) {
        final dio = getIt<DioClient>().dio;
        try {
          final quotaRes = await dio.get<Map<String, dynamic>>(
            '/v1/tenant/quotas',
          );
          final planObj = quotaRes.data?['plan'];
          if (planObj is Map && planObj['key'] is String) {
            _activeTier = _normaliseTier(planObj['key'] as String);
            await getIt<SecureStorage>().saveActiveTier(_activeTier);
          }
          final meters = quotaRes.data?['meters'];
          if (meters is List) {
            _meters = meters
                .whereType<Map>()
                .map((meter) => meter.cast<String, dynamic>())
                .toList();
          }
        } catch (_) {}

        final invRes = await dio.get<Map<String, dynamic>>('/v1/billing/invoices');
        final pmRes = await dio.get<Map<String, dynamic>>('/v1/billing/payment-methods');

        if (invRes.data != null && invRes.data!['data'] is List) {
          _invoices = (invRes.data!['data'] as List)
              .map((it) => BillingInvoice.fromJson(it as Map<String, dynamic>))
              .toList();
        }

        final methods = pmRes.data?['data'];
        if (methods is Map) {
          _billingConfig = methods.cast<String, dynamic>();
        }
      }
    } catch (_) {
      // Leave the lists empty: showing invented invoices would be worse.
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

    try {
      if (!getIt.isRegistered<DioClient>()) {
        throw Exception('Billing needs a connection.');
      }

      final dio = getIt<DioClient>().dio;

      // Card upgrades go through the provider's hosted checkout. The local
      // invoice is only settled by the provider's signed webhook.
      if (!isCash) {
        String? activeGateway;

        try {
          final methods = await dio.get<dynamic>('/v1/billing/payment-methods');
          final methodsPayload = methods.data;
          final methodsData = methodsPayload is Map
              ? methodsPayload['data']
              : null;

          if (methodsData is Map) {
            activeGateway = methodsData['active_gateway']?.toString();
          }
        } catch (_) {}

        const hostedGateways = [
          'stripe',
          'paypal',
          'razorpay',
          'sslcommerz',
          'bkash',
          'paystack',
          'mollie',
        ];

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
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );

              if (mounted) {
                setState(() => _isLoading = false);
                _snack(
                  'Complete payment in the browser. Your plan updates when the provider confirms.',
                );
              }

              return;
            }
          } on DioException catch (error) {
            // 422 means no provider keys are configured on this platform; the
            // API's own upgrade path is the correct fallback.
            if (error.response?.statusCode != 422) rethrow;
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

      await getIt<SecureStorage>().saveActiveTier(newTier);
      await _fetchBillingData();

      if (!mounted) return;

      if (_invoices.isNotEmpty) {
        _showInvoiceReceiptModal(_invoices.first, isCash: isCash);
      } else {
        _snack(isCash ? 'Cash invoice created.' : 'Plan updated.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack(_billingMessage(error), error: true);
      }
    }
  }

  String _billingMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }

      return 'Could not update the plan.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      error ? AppTheme.errorSnackBar(message) : AppTheme.successSnackBar(message),
    );
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
                  _receiptRow('Amount', '${inv.currency} ${(inv.amountCents / 100).toStringAsFixed(2)}'),
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
    final invoice = _invoices.isNotEmpty ? _invoices.first : null;
    final reasonCtrl = TextEditingController();
    final amountCtrl = TextEditingController(
      text: invoice == null ? '' : (invoice.amountCents / 100).toStringAsFixed(2),
    );
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
                'FairShare Graduated Refund Policy:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink),
              ),
              const SizedBox(height: 8),
              _policyBullet('Monthly Plans', '100% refund within 7 days; 50% refund between 8 to 20 days; no refund after 20 days.'),
              _policyBullet('Yearly Plans', '100% refund within 15 days; 75% within 1 month; 50% within 3 months; 25% within 6 months; no refund after 6 months.'),
              _policyBullet('Plan Reverts', 'Reverting to a previous plan is permitted while refund eligibility is at or above 50%.'),
              _policyBullet('Cancellation Lockout', 'Cancelling logs out immediately. Access is restricted to Billing until resubscribed.'),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount to refund',
                  prefixText: '${invoice?.currency ?? 'USD'} ',
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
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
            onPressed: () async {
              final amount = (double.tryParse(amountCtrl.text.trim()) ?? 0) * 100;
              if (amount < 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  AppTheme.errorSnackBar('Enter a refund amount of at least 1.00.'),
                );
                return;
              }

              Navigator.of(ctx).pop();

              try {
                if (!getIt.isRegistered<DioClient>()) {
                  throw Exception('Billing is unavailable offline.');
                }

                await getIt<DioClient>().dio.post<Map<String, dynamic>>(
                  '/v1/billing/refund-request',
                  data: {
                    'invoice_id': invoice?.id,
                    'amount_cents': amount.round(),
                    'currency': invoice?.currency ?? 'USD',
                    'reason': reasonCtrl.text.trim().isEmpty
                        ? 'Refund requested from the mobile app.'
                        : reasonCtrl.text.trim(),
                  },
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppTheme.successSnackBar(
                      'Refund request submitted. Review timeline is 1-2 business days.',
                    ),
                  );
                }
              } on DioException catch (error) {
                final data = error.response?.data;
                final message = data is Map && data['message'] is String
                    ? data['message'] as String
                    : 'Could not submit the refund request.';
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(AppTheme.errorSnackBar(message));
                }
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppTheme.errorSnackBar(
                      error.toString().replaceFirst('Exception: ', ''),
                    ),
                  );
                }
              }
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
          'Cancelling your plan will immediately log you out. '
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

              if (!getIt.isRegistered<DioClient>()) {
                _snack('Cancelling the plan needs a connection.', error: true);
                return;
              }

              try {
                await getIt<DioClient>().dio.post<dynamic>('/v1/billing/cancel');
              } catch (error) {
                _snack(_billingMessage(error), error: true);
                return;
              }

              await getIt<SecureStorage>().deleteToken();
              if (mounted) context.go('/login');
            },
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );
  }

  String _normaliseTier(String tier) {
    switch (tier) {
      case 'household_pro':
      case 'standard':
        return 'standard';
      case 'family_plus':
      case 'pilot':
        return 'pilot';
      case 'enterprise':
        return 'enterprise';
      case 'starter':
      default:
        return 'starter';
    }
  }

  Map<String, dynamic> _plan(String tier) =>
      _plans[_normaliseTier(tier)] ?? _plans['starter']!;

  String _tierName(String tier) => _plan(tier)['label']?.toString() ?? 'Plan';

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
                          '${_plan(_activeTier)['price']} · ${_plan(_activeTier)['cadence']}',
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
                        const SizedBox(height: 10),
                        _quotaRow(
                          Icons.group_outlined,
                          'Household Members',
                          _meterLabel('seats', _plan(_activeTier)['seats'] as int),
                        ),
                        _quotaRow(
                          Icons.pin_drop_outlined,
                          'Saved Places & Geofencing',
                          _meterLabel('places', _plan(_activeTier)['places'] as int),
                        ),
                        _quotaRow(
                          Icons.task_alt,
                          'Errands & Tasks / month',
                          _capLabel(_plan(_activeTier)['requests'] as int),
                        ),
                        _quotaRow(
                          Icons.kitchen_outlined,
                          'Pantry Items',
                          _meterLabel('pantry', _plan(_activeTier)['pantry'] as int),
                        ),
                        _quotaRow(
                          Icons.phone_in_talk_outlined,
                          'Member Calls / Voice (today)',
                          _meterLabel('voice', _plan(_activeTier)['calls'] as int),
                        ),
                        _quotaRow(
                          Icons.document_scanner_outlined,
                          'Receipt OCR Scans / month',
                          _capLabel(_plan(_activeTier)['scans'] as int),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space4),

                  // Plans Comparison / Upgrade Section
                  const SectionHeader(title: 'SaaS Subscription Plans', count: 4),
                  const SizedBox(height: AppTheme.space3),
                  for (final entry in _plans.entries) ...[
                    _planCard(
                      tierKey: entry.key,
                      title: entry.value['label'] as String,
                      price: entry.value['cadence'] == 'free'
                          ? entry.value['price'] as String
                          : '${entry.value['price']} / mo',
                      features: (entry.value['features'] as List).cast<String>(),
                      isCurrent: _normaliseTier(_activeTier) == entry.key,
                      isPopular: entry.key == 'standard',
                    ),
                    if (entry.key != _plans.keys.last)
                      const SizedBox(height: 12),
                  ],
                  const SizedBox(height: AppTheme.space4),

                  // Payment & settlement options, read from the platform gateway config.
                  SectionHeader(
                    title: 'Payment & Settlement Options',
                    count: _gatewayCount,
                  ),
                  const SizedBox(height: AppTheme.space3),
                  WarmCard(
                    child: Column(
                      children: [
                        if (_billingConfig == null)
                          const ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.cloud_off_outlined),
                            title: Text('Gateway configuration unavailable'),
                            subtitle: Text('Check the connection and pull to refresh.'),
                          )
                        else ...[
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
                              'Active gateway · ${_gatewayLabel(_billingConfig!['active_gateway']?.toString())}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${(_billingConfig!['mode'] ?? 'sandbox').toString().toUpperCase()} mode · '
                              '${_billingConfig!['currency'] ?? 'USD'}',
                            ),
                            trailing: PriorityChip(
                              label: (_billingConfig!['is_sandbox'] == true) ? 'Sandbox' : 'Live',
                              tone: WarmTone.neutral,
                            ),
                          ),
                          for (final entry in _gateways.entries)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                entry.key == 'cash' || entry.key == 'bank_transfer'
                                    ? Icons.payments_outlined
                                    : Icons.credit_card,
                                color: entry.value['enabled'] == true
                                    ? AppTheme.secondary
                                    : AppTheme.muted,
                              ),
                              title: Text(
                                _gatewayLabel(entry.key),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                entry.value['enabled'] == true
                                    ? '${(entry.value['mode'] ?? 'sandbox').toString().toUpperCase()} · enabled'
                                    : 'Not enabled',
                              ),
                              trailing: entry.value['enabled'] == true
                                  ? const Icon(Icons.check_circle, size: 18, color: AppTheme.secondary)
                                  : null,
                            ),
                        ],
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
                        if (_invoices.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              'No invoices yet.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.muted,
                              ),
                            ),
                          ),
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
                                      '${inv.currency} ${(inv.amountCents / 100).toStringAsFixed(2)}',
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

                  // Cancel Subscription Action
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

  Map<String, dynamic> get _gateways {
    final gateways = _billingConfig?['gateways'];
    if (gateways is! Map) return const {};

    return gateways.map(
      (key, value) => MapEntry(
        key.toString(),
        value is Map ? value.cast<String, dynamic>() : <String, dynamic>{},
      ),
    );
  }

  int get _gatewayCount => _gateways.length;

  String _gatewayLabel(String? key) => switch (key) {
    'stripe' => 'Stripe',
    'paypal' => 'PayPal',
    'razorpay' => 'Razorpay',
    'sslcommerz' => 'SSLCommerz',
    'bkash' => 'bKash',
    'paystack' => 'Paystack',
    'mollie' => 'Mollie',
    'cash' => 'Cash settlement',
    'bank_transfer' => 'Bank transfer',
    _ => 'Not configured',
  };

  String _meterLabel(String key, int fallbackCap) {
    Map<String, dynamic>? meter;
    for (final entry in _meters) {
      if (entry['key'] == key) {
        meter = entry;
        break;
      }
    }

    if (meter == null) return _capLabel(fallbackCap);

    return _capLabel(
      (meter['cap'] as num?)?.toInt() ?? fallbackCap,
      used: (meter['used'] as num?)?.toInt() ?? 0,
    );
  }

  String _capLabel(int cap, {int? used}) {
    if (cap <= 0) return 'Not included';
    if (cap >= 9999) return used == null ? 'Unlimited' : '$used / Unlimited';

    return used == null ? '$cap included' : '$used / $cap';
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
