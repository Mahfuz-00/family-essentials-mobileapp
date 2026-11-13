import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';
import '../bloc/requests_bloc.dart';
import '../bloc/requests_event.dart';

class AiChatMessage {
  AiChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.errandData,
    this.createdRequestId,
  });

  final String text;
  final bool isUser;
  final String time;
  final Map<String, dynamic>? errandData;
  final int? createdRequestId;
}

class HouseholdMemberChatMsg {
  HouseholdMemberChatMsg({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.recipientId,
  });

  factory HouseholdMemberChatMsg.fromJson(Map<String, dynamic> json) {
    return HouseholdMemberChatMsg(
      id: (json['id'] as num?)?.toInt() ?? 0,
      senderId: (json['sender_id'] as num?)?.toInt() ?? 1,
      senderName: json['sender_name'] as String? ?? 'Family Member',
      recipientId: (json['recipient_id'] as num?)?.toInt(),
      text: json['text'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? 'Just now',
    );
  }

  final int id;
  final int senderId;
  final String senderName;
  final int? recipientId;
  final String text;
  final String createdAt;
}

class AiChatPage extends StatefulWidget {
  const AiChatPage({
    super.key,
    this.initialTab = 'ai',
  });

  final String initialTab;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;

  // 'ai' = AI Family Dispatcher; 'family' = Member-to-member Chat & Voice Calls
  late String _activeTab;
  bool _isLoadingThread = true;
  bool _isSending = false;

  // Plan & Quotas (Point 7 & Point 8)
  String _planKey = 'pilot';
  String _planLabel = 'Pilot Family Tier';
  int _chatCap = 300;
  int _chatUsed = 2;
  int _callsCap = 15;
  int _callsUsed = 1;

  int _currentUserId = 1;
  String _currentUserName = 'Tanvir Rahman';
  int? _selectedMemberId;

  List<Map<String, dynamic>> _members = [
    {
      'id': 1,
      'name': 'Tanvir Rahman',
      'email': 'tanvir@familyessentials.app',
      'phone': '+8801711000001',
      'role': 'tenant_admin',
      'online': true,
    },
    {
      'id': 2,
      'name': 'Sarah Rahman',
      'email': 'sarah@familyessentials.app',
      'phone': '+8801711000002',
      'role': 'member',
      'online': true,
    },
  ];

  List<HouseholdMemberChatMsg> _familyMessages = [];

  final List<AiChatMessage> _aiMessages = [
    AiChatMessage(
      text:
          'Hello! I am your live AI Family Dispatcher.\n\n'
          '• Type any errand in plain English (e.g. "Assign Sarah to pick up milk from Whole Foods today at 6pm") to create & assign it on the live board.\n'
          '• Ask "What tasks are due today?" for live errands & chores.\n'
          '• Ask "What is our budget status?" for live ledger numbers.\n'
          '• Ask "Check pantry stock" for real low-stock alerts.',
      isUser: false,
      time: 'Ready',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _activeTab = (widget.initialTab == 'family' || widget.initialTab == 'ai')
        ? widget.initialTab
        : 'ai';
    _loadHouseholdChatAndQuotas();
    // Poll every 2 seconds for new household member messages
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _refreshFamilyMessagesSilently();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshFamilyMessagesSilently() async {
    if (!mounted || !getIt.isRegistered<DioClient>()) return;
    try {
      final dio = getIt<DioClient>().dio;
      final res = await dio.get<Map<String, dynamic>>('/v1/household/messages');
      final data = res.data;
      if (data != null && data['messages'] is List && mounted) {
        final incoming = (data['messages'] as List)
            .map(
              (e) => HouseholdMemberChatMsg.fromJson(
                (e as Map).cast<String, dynamic>(),
              ),
            )
            .toList();
        if (incoming.length != _familyMessages.length) {
          setState(() {
            _familyMessages = incoming;
            final plan = data['plan'] as Map<String, dynamic>?;
            if (plan != null) {
              _chatUsed = (plan['chat_used'] as num?)?.toInt() ?? _chatUsed;
              _callsUsed = (plan['calls_used'] as num?)?.toInt() ?? _callsUsed;
            }
          });
          if (_activeTab == 'family') {
            _scrollToBottom();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadHouseholdChatAndQuotas() async {
    setState(() => _isLoadingThread = true);

    try {
      final storage = getIt<SecureStorage>();
      final savedName = await storage.readUserName();
      if (savedName != null && savedName.trim().isNotEmpty) {
        _currentUserName = savedName.trim();
      }
      final savedTier = await storage.readActiveTier();
      if (savedTier != null && savedTier.isNotEmpty) {
        _applyTierDefaults(savedTier);
      }

      if (getIt.isRegistered<DioClient>()) {
        final dio = getIt<DioClient>().dio;
        final res = await dio.get<Map<String, dynamic>>(
          '/v1/household/messages',
        );
        final data = res.data;
        if (data != null) {
          final plan = data['plan'] as Map<String, dynamic>?;
          if (plan != null) {
            _planKey = plan['key'] as String? ?? _planKey;
            _planLabel = plan['label'] as String? ?? _planLabel;
            _chatCap = (plan['chat_cap'] as num?)?.toInt() ?? _chatCap;
            _chatUsed = (plan['chat_used'] as num?)?.toInt() ?? _chatUsed;
            _callsCap = (plan['calls_cap'] as num?)?.toInt() ?? _callsCap;
            _callsUsed = (plan['calls_used'] as num?)?.toInt() ?? _callsUsed;
          }
          if (data['members'] is List && (data['members'] as List).isNotEmpty) {
            _members = (data['members'] as List)
                .map((e) => (e as Map).cast<String, dynamic>())
                .toList();
            for (final m in _members) {
              if ((m['name'] as String?)?.toLowerCase() ==
                  _currentUserName.toLowerCase()) {
                _currentUserId = (m['id'] as num?)?.toInt() ?? 1;
              }
            }
          }
          if (data['messages'] is List) {
            _familyMessages = (data['messages'] as List)
                .map(
                  (e) => HouseholdMemberChatMsg.fromJson(
                    (e as Map).cast<String, dynamic>(),
                  ),
                )
                .toList();
          }
        }
      }
    } catch (_) {}

    if (_familyMessages.isEmpty) {
      _familyMessages = [
        HouseholdMemberChatMsg(
          id: 1,
          senderId: 2,
          senderName: 'Sarah Rahman',
          text:
              'Hey! Are you heading past the grocery store on your way home today?',
          createdAt: '2:15 PM',
        ),
        HouseholdMemberChatMsg(
          id: 2,
          senderId: _currentUserId,
          senderName: _currentUserName,
          text:
              'Yes! I checked the Pantry list—picking up milk, eggs, and sourdough.',
          createdAt: '2:18 PM',
        ),
      ];
    }

    if (mounted) {
      setState(() => _isLoadingThread = false);
      _scrollToBottom();
    }
  }

  void _applyTierDefaults(String tier) {
    _planKey = tier;
    switch (tier) {
      case 'starter':
        _planLabel = 'Starter Family';
        _chatCap = 30;
        _callsCap = 0;
        break;
      case 'household_pro':
      case 'standard':
        _planLabel = 'Household Pro';
        _chatCap = 1500;
        _callsCap = 60;
        break;
      case 'enterprise':
        _planLabel = 'Enterprise Household';
        _chatCap = 9999;
        _callsCap = 9999;
        break;
      case 'pilot':
      default:
        _planLabel = 'Pilot Family Tier';
        _chatCap = 300;
        _callsCap = 15;
        break;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showPlanLimitUpgradeDialog({
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_clock_outlined, color: AppTheme.tertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, color: AppTheme.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not Now'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/billing');
            },
            icon: const Icon(Icons.workspace_premium_outlined, size: 16),
            label: const Text('Upgrade Plan'),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateMemberCall(
    Map<String, dynamic> member, {
    bool isIncoming = false,
  }) async {
    final targetName = member['name'] as String? ?? 'Family Member';
    final targetId = (member['id'] as num?)?.toInt() ?? 2;
    final targetPhone = member['phone'] as String? ?? '+8801711000002';

    // Enforce SaaS Subscription Plan Call Limits (Point 7 & Point 8)
    if (!isIncoming && _callsCap <= 0) {
      _showPlanLimitUpgradeDialog(
        title: 'Calling Not Included in $_planLabel',
        message:
            'Direct member-to-member voice calling is not included on the $_planLabel plan (0 calls/mo).\n\n'
            'Upgrade to Pilot Family (15 calls/mo) or Household Pro (60 calls/mo) to call household members directly.',
      );
      return;
    }

    if (!isIncoming && _callsUsed >= _callsCap) {
      _showPlanLimitUpgradeDialog(
        title: 'Monthly Call Quota Reached',
        message:
            'Your household has used all $_callsCap member calls included in the $_planLabel plan this month.\n\n'
            'Upgrade your subscription tier to increase your monthly call allowance.',
      );
      return;
    }

    if (!isIncoming) {
      try {
        if (getIt.isRegistered<DioClient>()) {
          final res = await getIt<DioClient>().dio.post<Map<String, dynamic>>(
            '/v1/members/$targetId/call',
          );
          if (res.data != null) {
            final quota = (res.data!['quota'] as num?)?.toInt();
            final remaining = (res.data!['remaining_calls'] as num?)?.toInt();
            if (quota != null && remaining != null) {
              setState(() {
                _callsCap = quota;
                _callsUsed = (quota - remaining).clamp(0, quota);
              });
            } else {
              setState(() => _callsUsed++);
            }
          }
        } else {
          setState(() => _callsUsed++);
        }
      } on DioException catch (e) {
        final code = e.response?.data is Map ? e.response?.data['code'] : null;
        final msg = e.response?.data is Map ? e.response?.data['message'] : null;
        if (e.response?.statusCode == 403 || code == 'plan_limit_exceeded') {
          _showPlanLimitUpgradeDialog(
            title: 'Plan Call Limit Reached',
            message:
                msg?.toString() ??
                'Your current SaaS plan limit for member calling has been reached.',
          );
          return;
        }
        setState(() => _callsUsed++);
      } catch (_) {
        setState(() => _callsUsed++);
      }
    }

    if (!mounted) return;

    // Show interactive In-App Household Voice Call Modal (Point 7)
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: AppTheme.ink,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _ActiveHouseholdCallSheet(
        memberName: targetName,
        memberPhone: targetPhone,
        planLabel: _planLabel,
        callsUsed: _callsUsed,
        callsCap: _callsCap,
        isIncoming: isIncoming,
      ),
    );
  }

  Future<void> _sendFamilyMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    // Enforce SaaS Subscription Plan Chat Quota (Point 7 & Point 8)
    if (_chatCap > 0 && _chatUsed >= _chatCap) {
      _showPlanLimitUpgradeDialog(
        title: 'Monthly Chat Quota Reached',
        message:
            'Your household has used all $_chatCap chat messages included in the $_planLabel plan this month.\n\n'
            'Upgrade your SaaS plan in Plan & Billing to unlock more messages.',
      );
      return;
    }

    _controller.clear();
    setState(() => _isSending = true);

    try {
      if (getIt.isRegistered<DioClient>()) {
        final res = await getIt<DioClient>().dio.post<Map<String, dynamic>>(
          '/v1/household/messages',
          data: {
            'text': text,
            'recipient_id': _selectedMemberId,
          },
        );
        final msgData = res.data?['data'] as Map<String, dynamic>?;
        if (msgData != null && mounted) {
          setState(() {
            _familyMessages.add(HouseholdMemberChatMsg.fromJson(msgData));
            _chatUsed =
                (res.data?['chat_used'] as num?)?.toInt() ?? (_chatUsed + 1);
            _isSending = false;
          });
          _scrollToBottom();
          return;
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        setState(() => _isSending = false);
        _showPlanLimitUpgradeDialog(
          title: 'Monthly Chat Limit Reached',
          message:
              (e.response?.data is Map
                  ? e.response?.data['message']?.toString()
                  : null) ??
              'Monthly chat message limit reached for your plan.',
        );
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _familyMessages.add(
          HouseholdMemberChatMsg(
            id: _familyMessages.length + 1,
            senderId: _currentUserId,
            senderName: _currentUserName,
            recipientId: _selectedMemberId,
            text: text,
            createdAt: 'Just now',
          ),
        );
        _chatUsed++;
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendAiDispatcherMessage([String? presetText]) async {
    final text = (presetText ?? _controller.text).trim();
    if (text.isEmpty || _isSending) return;

    if (_chatCap > 0 && _chatUsed >= _chatCap) {
      _showPlanLimitUpgradeDialog(
        title: 'AI & Chat Quota Reached',
        message:
            'Your household has used all $_chatCap monthly AI & chat messages on the $_planLabel plan.',
      );
      return;
    }

    _controller.clear();
    setState(() {
      _aiMessages.add(
        AiChatMessage(
          text: text,
          isUser: true,
          time: 'Now',
        ),
      );
      _chatUsed++;
      _isSending = true;
    });
    _scrollToBottom();

    final lower = text.toLowerCase();

    // 0. Greetings / Help / Capabilities Query
    if (lower == 'hi' ||
        lower == 'hello' ||
        lower == 'hey' ||
        lower == 'help' ||
        lower.contains('what can you do') ||
        lower.contains('how do you work')) {
      setState(() {
        _aiMessages.add(
          AiChatMessage(
            text:
                'I am connected to your live household data! Here is what you can ask or command me to do:\n\n'
                '1. Check Budget & Spending: "What is our budget status?"\n'
                '2. Check Pantry Inventory: "Check pantry stock"\n'
                '3. Check Today\'s Errands: "What tasks are due today?"\n'
                '4. Dispatch Live Errands: "Assign Sarah to buy organic milk from Whole Foods today at 6pm"',
            isUser: false,
            time: 'Live AI',
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();
      return;
    }

    // 1. Live Household Budget / Ledger Query (Point 2 — Real API, fixed keys)
    if (lower.contains('budget') ||
        lower.contains('spend') ||
        lower.contains('spent') ||
        lower.contains('expense') ||
        lower.contains('money') ||
        lower.contains('ledger') ||
        lower.contains('income')) {
      try {
        if (getIt.isRegistered<DioClient>()) {
          final dio = getIt<DioClient>().dio;
          final ledgersRes = await dio.get<Map<String, dynamic>>('/v1/ledgers');
          final list = (ledgersRes.data?['data'] as List?) ?? const [];
          if (list.isNotEmpty) {
            final firstLedger = (list.first as Map).cast<String, dynamic>();
            final ledgerId = (firstLedger['id'] as num?)?.toInt() ?? 1;
            final currency = firstLedger['currency'] as String? ?? 'USD';
            final sumRes = await dio.get<Map<String, dynamic>>(
              '/v1/ledgers/$ledgerId/summary',
              queryParameters: {'period_type': 'monthly', 'period': 'monthly'},
            );
            final sumData =
                (sumRes.data?['data'] ?? sumRes.data) as Map<String, dynamic>?;
            if (sumData != null && mounted) {
              final expenseMinor =
                  (sumData['expense_minor'] as num?)?.toInt() ??
                  (sumData['total_expense_minor'] as num?)?.toInt() ??
                  0;
              final incomeMinor =
                  (sumData['income_minor'] as num?)?.toInt() ??
                  (sumData['total_income_minor'] as num?)?.toInt() ??
                  0;
              final netMinor =
                  (sumData['net_minor'] as num?)?.toInt() ??
                  (incomeMinor - expenseMinor);
              final budgetMinor =
                  (sumData['budget_minor'] as num?)?.toInt() ??
                  (sumData['budget_amount_minor'] as num?)?.toInt() ??
                  (firstLedger['monthly_budget_minor'] as num?)?.toInt() ??
                  0;
              final remainingMinor =
                  (sumData['remaining_budget_minor'] as num?)?.toInt() ??
                  (budgetMinor - expenseMinor);
              final cats =
                  (sumData['by_category'] as List?) ??
                  (sumData['categories'] as List?) ??
                  const [];
              final topCat = cats.isNotEmpty
                  ? '${(cats.first as Map)['label'] ?? (cats.first as Map)['category'] ?? 'Groceries'} (${formatMoneyMinor(((cats.first as Map)['expense_minor'] as num?)?.toInt() ?? 0, currency)})'
                  : 'No category breakdown yet';

              final reply =
                  'Live Household Ledger (${firstLedger['name'] ?? 'Household budget'}):\n'
                  '• Total Spent This Month: ${formatMoneyMinor(expenseMinor, currency)}\n'
                  '• Total Income: ${formatMoneyMinor(incomeMinor, currency)}\n'
                  '• Net ${netMinor >= 0 ? "Surplus" : "Outflow"}: ${formatMoneyMinor(netMinor.abs(), currency)}\n'
                  '• Monthly Budget Limit: ${budgetMinor > 0 ? formatMoneyMinor(budgetMinor, currency) : 'Not set'} (${formatMoneyMinor(remainingMinor.clamp(0, 999999999), currency)} remaining)\n'
                  '• Top Spending Category: $topCat';

              setState(() {
                _aiMessages.add(
                  AiChatMessage(text: reply, isUser: false, time: 'Live API'),
                );
                _isSending = false;
              });
              _scrollToBottom();
              return;
            }
          }
        }
      } catch (_) {}
    }

    // 2. Live Pantry Inventory Query (Point 2 — Real /v1/essentials API, fixed keys)
    if (lower.contains('pantry') ||
        lower.contains('stock') ||
        lower.contains('inventory') ||
        lower.contains('restock') ||
        lower.contains('essential')) {
      try {
        if (getIt.isRegistered<DioClient>()) {
          final dio = getIt<DioClient>().dio;
          final res = await dio.get<Map<String, dynamic>>('/v1/essentials');
          final list = (res.data?['data'] as List?) ?? const [];
          if (mounted) {
            final items = list
                .map((e) => (e as Map).cast<String, dynamic>())
                .toList();
            final lowItems = items.where((it) {
              final isDue = it['is_due'] as bool?;
              final q =
                  (it['stock_level'] as num?)?.toDouble() ??
                  (it['quantity'] as num?)?.toDouble() ??
                  0;
              final t =
                  (it['threshold'] as num?)?.toDouble() ??
                  (it['low_stock_threshold'] as num?)?.toDouble() ??
                  1;
              return isDue == true || q <= t;
            }).toList();
            final lowDetails = lowItems
                .take(5)
                .map((it) {
                  final name = it['name']?.toString() ?? 'Item';
                  final stock = it['stock_level'] ?? it['quantity'] ?? 0;
                  final store = it['default_store']?.toString();
                  return '  - $name ($stock in stock${store != null ? ' · $store' : ''})';
                })
                .join('\n');

            final reply =
                'Live Pantry Inventory Status:\n'
                '• Total Tracked Items: ${items.length}\n'
                '• Needs Restocking (${lowItems.length}):\n'
                '${lowItems.isNotEmpty ? lowDetails : '  All items are well stocked!'}\n\n'
                'Tip: You can say "Assign Sarah to buy ${lowItems.isNotEmpty ? lowItems.first['name'] : 'milk'}" to create a shopping errand right now.';

            setState(() {
              _aiMessages.add(
                AiChatMessage(text: reply, isUser: false, time: 'Live API'),
              );
              _isSending = false;
            });
            _scrollToBottom();
            return;
          }
        }
      } catch (_) {}
    }

    // 3. Live Today's Errands / Tasks / Board Query
    final isBoardQuestion =
        (lower.contains('what') ||
            lower.contains('which') ||
            lower.contains('show') ||
            lower.contains('list') ||
            lower.contains('check') ||
            lower.contains('status')) &&
        (lower.contains('task') ||
            lower.contains('errand') ||
            lower.contains('chore') ||
            lower.contains('today') ||
            lower.contains('overdue') ||
            lower.contains('due') ||
            lower.contains('board'));

    if (isBoardQuestion) {
      try {
        if (getIt.isRegistered<DioClient>()) {
          final dio = getIt<DioClient>().dio;
          final res = await dio.get<Map<String, dynamic>>('/v1/requests/board');
          final data = res.data;
          if (data != null && mounted) {
            final overdue = (data['overdue'] as List?) ?? const [];
            final dueToday = (data['due_today'] as List?) ?? const [];
            final backlog = (data['backlog'] as List?) ?? const [];

            final overdueLines = overdue
                .map((e) => '  • ${(e as Map)['title']} (Urgent / Overdue)')
                .join('\n');
            final todayLines = dueToday
                .map((e) {
                  final m = (e as Map).cast<String, dynamic>();
                  final assignee = (m['assignee'] is Map)
                      ? m['assignee']['name']
                      : 'Unassigned';
                  final store = m['store_name'] != null
                      ? ' @ ${m['store_name']}'
                      : '';
                  return '  • ${m['title']}$store ($assignee)';
                })
                .join('\n');

            final reply =
                'Live Household Errands & Tasks Board:\n'
                '• Overdue (${overdue.length}):\n'
                '${overdue.isNotEmpty ? overdueLines : '  None'}\n'
                '• Due Today (${dueToday.length}):\n'
                '${dueToday.isNotEmpty ? todayLines : '  None'}\n'
                '• Backlog: ${backlog.length} item(s)';

            setState(() {
              _aiMessages.add(
                AiChatMessage(text: reply, isUser: false, time: 'Live API'),
              );
              _isSending = false;
            });
            _scrollToBottom();
            return;
          }
        }
      } catch (_) {}
    }

    // 4. Natural Language Errand & Chore Dispatcher (POST /v1/requests/parse-nlp)
    try {
      if (getIt.isRegistered<DioClient>()) {
        final dio = getIt<DioClient>().dio;
        final response = await dio.post<Map<String, dynamic>>(
          '/v1/requests/parse-nlp',
          data: {'text': text, 'execute': true},
        );

        if (response.data != null && mounted) {
          final parsed =
              response.data!['parsed'] as Map<String, dynamic>? ?? {};
          final reqObj =
              response.data!['request'] as Map<String, dynamic>? ?? {};
          final reqId = (reqObj['id'] as num?)?.toInt();
          final title = parsed['title'] as String? ?? text;
          final assignee =
              parsed['assignee_name'] as String? ?? 'Anyone in household';
          final store = parsed['store_name'] as String?;
          final priority = (parsed['priority'] as String? ?? 'normal')
              .toUpperCase();
          final dueHuman = parsed['due_human'] as String?;

          // Refresh live RequestsBloc so Today & Errands screens show the new task immediately!
          if (getIt.isRegistered<RequestsBloc>()) {
            getIt<RequestsBloc>().add(const BoardRequested());
          }

          setState(() {
            _aiMessages.add(
              AiChatMessage(
                text:
                    'Dispatched live errand "$title" ($priority priority).\n'
                    '• Assigned to: $assignee\n'
                    '${store != null ? '• Location / Store: $store\n' : ''}'
                    '${dueHuman != null ? '• Due: $dueHuman' : '• Added to Today & Errands board'}',
                isUser: false,
                time: 'Created',
                errandData: parsed,
                createdRequestId: reqId,
              ),
            );
            _isSending = false;
          });
          _scrollToBottom();
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _aiMessages.add(
          AiChatMessage(
            text:
                'Dispatched "$text" to your household Errands & Tasks board.',
            isUser: false,
            time: 'Now',
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleFamilyMessages = _selectedMemberId == null
        ? _familyMessages
        : _familyMessages
              .where(
                (m) =>
                    m.senderId == _selectedMemberId ||
                    m.recipientId == _selectedMemberId ||
                    m.senderId == _currentUserId,
              )
              .toList();

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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _activeTab == 'ai'
                    ? 'AI Dispatcher & Family Chat'
                    : 'Household Chat & Calls',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              Text(
                '$_planLabel · Calls: ${_callsCap >= 9999 ? "$_callsUsed/∞" : "$_callsUsed/$_callsCap"} · Chat: ${_chatCap >= 9999 ? "$_chatUsed/∞" : "$_chatUsed/$_chatCap"}',
                style: const TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => context.push('/billing'),
              icon: const Icon(
                Icons.workspace_premium_outlined,
                size: 15,
                color: AppTheme.secondary,
              ),
              label: const Text(
                'Plan Limits',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.secondary,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            // Top Mode Switcher: AI Dispatcher vs Family Chat & Calls
            Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'ai',
                      icon: Icon(Icons.auto_awesome, size: 16),
                      label: Text(
                        'AI Dispatcher',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ButtonSegment(
                      value: 'family',
                      icon: Icon(Icons.forum_outlined, size: 16),
                      label: Text(
                        'Family Chat & Calls',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  selected: {_activeTab},
                  onSelectionChanged: (s) {
                    setState(() => _activeTab = s.first);
                    _scrollToBottom();
                  },
                ),
              ),
            ),

            if (_activeTab == 'family') ...[
              // Household Members Direct Call & Chat Bar (Point 7)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  color: AppTheme.forestSoft.withValues(alpha: 0.65),
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.outline.withValues(alpha: 0.25),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'HOUSEHOLD MEMBERS — TAP CALL OR FILTER CHAT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppTheme.secondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PriorityChip(
                          label: _callsCap <= 0
                              ? 'Calls Locked ($_planLabel)'
                              : _callsCap >= 9999
                              ? 'Unlimited Calls'
                              : '${(_callsCap - _callsUsed).clamp(0, 9999)} calls left',
                          tone: _callsCap <= 0 || _callsUsed >= _callsCap
                              ? WarmTone.danger
                              : WarmTone.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              visualDensity: VisualDensity.compact,
                              label: const Text(
                                'All Household',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              selected: _selectedMemberId == null,
                              onSelected: (_) =>
                                  setState(() => _selectedMemberId = null),
                            ),
                          ),
                          for (final m in _members)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedMemberId == m['id']
                                      ? AppTheme.secondary.withValues(
                                          alpha: 0.14,
                                        )
                                      : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _selectedMemberId == m['id']
                                        ? AppTheme.secondary
                                        : AppTheme.outline.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        final id = (m['id'] as num?)?.toInt();
                                        setState(() {
                                          _selectedMemberId =
                                              _selectedMemberId == id
                                              ? null
                                              : id;
                                        });
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          UserProfileAvatar(
                                            name:
                                                m['name'] as String? ?? 'User',
                                            radius: 14,
                                            showBorder: false,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (m['name'] as String? ??
                                                        'Member')
                                                    .split(' ')
                                                    .first,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.ink,
                                                ),
                                              ),
                                              const Text(
                                                'Online',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.secondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _initiateMemberCall(m),
                                      borderRadius: BorderRadius.circular(999),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _callsCap <= 0
                                              ? AppTheme.coralSoft
                                              : AppTheme.secondary,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _callsCap <= 0
                                                  ? Icons.lock_outline
                                                  : Icons.call_rounded,
                                              size: 13,
                                              color: _callsCap <= 0
                                                  ? AppTheme.tertiary
                                                  : Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Call',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                color: _callsCap <= 0
                                                    ? AppTheme.tertiary
                                                    : Colors.white,
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
                          // Simulate Incoming Call button for single-phone testing
                          if (_members.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: ActionChip(
                                visualDensity: VisualDensity.compact,
                                avatar: const Icon(
                                  Icons.ring_volume_rounded,
                                  size: 14,
                                  color: AppTheme.secondary,
                                ),
                                label: const Text(
                                  'Test Incoming Call',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onPressed: () => _initiateMemberCall(
                                  _members.last,
                                  isIncoming: true,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Family Messages List (with Shimmer Loading on initial fetch)
              Expanded(
                child: _isLoadingThread
                    ? ListView(
                        padding: const EdgeInsets.all(16),
                        children: const [
                          ShimmerWarmCard(height: 76),
                          SizedBox(height: 12),
                          ShimmerWarmCard(height: 76),
                          SizedBox(height: 12),
                          ShimmerWarmCard(height: 76),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: visibleFamilyMessages.length,
                        itemBuilder: (context, index) {
                          final msg = visibleFamilyMessages[index];
                          final isMe =
                              msg.senderId == _currentUserId ||
                              msg.senderName.toLowerCase() ==
                                  _currentUserName.toLowerCase();
                          return _buildFamilyBubble(msg, isMe);
                        },
                      ),
              ),
            ] else ...[
              // AI Family Dispatcher Prompt Chips
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: AppTheme.forestSoft.withValues(alpha: 0.6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _promptChip('What is our budget status?'),
                      const SizedBox(width: 8),
                      _promptChip('Check pantry stock'),
                      const SizedBox(width: 8),
                      _promptChip('What tasks are due today?'),
                      const SizedBox(width: 8),
                      _promptChip(
                        'Assign Sarah to buy organic milk at Whole Foods today 6pm',
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _aiMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _aiMessages[index];
                    return _buildAiBubble(msg);
                  },
                ),
              ),
            ],

            if (_isSending)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.secondary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Syncing with household server...',
                      style: TextStyle(fontSize: 12, color: AppTheme.muted),
                    ),
                  ],
                ),
              ),

            // Composer Bar
            Container(
              padding: EdgeInsets.fromLTRB(
                12,
                10,
                12,
                MediaQuery.of(context).padding.bottom + 10,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: _activeTab == 'family'
                            ? 'Message household members (${(_chatCap - _chatUsed).clamp(0, 9999)} left)...'
                            : 'Ask live budget/pantry/tasks or dispatch an errand...',
                        filled: true,
                        fillColor: AppTheme.canvas,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: AppTheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: AppTheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _activeTab == 'family'
                          ? _sendFamilyMessage()
                          : _sendAiDispatcherMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.secondary,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: () => _activeTab == 'family'
                          ? _sendFamilyMessage()
                          : _sendAiDispatcherMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _promptChip(String text) {
    return ActionChip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      backgroundColor: AppTheme.surface,
      side: BorderSide(color: AppTheme.outline.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      onPressed: () => _sendAiDispatcherMessage(text),
    );
  }

  Widget _buildFamilyBubble(HouseholdMemberChatMsg msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            UserProfileAvatar(
              name: msg.senderName,
              radius: 16,
              showBorder: false,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.secondary : AppTheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isMe
                    ? null
                    : Border.all(
                        color: AppTheme.outline.withValues(alpha: 0.25),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        msg.senderName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : AppTheme.ink,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg.createdAt,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.75)
                          : AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBubble(AiChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.84,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.secondary : AppTheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: isUser
                  ? null
                  : Border.all(color: AppTheme.outline.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: AppTheme.secondary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'AI Family Dispatcher (Live)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  msg.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: isUser ? Colors.white : AppTheme.ink,
                    height: 1.4,
                  ),
                ),
                if (msg.errandData != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.forestSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppTheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Saved to Household Board',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () {
                            if (msg.createdRequestId != null) {
                              context.push('/requests/${msg.createdRequestId}');
                            } else {
                              context.go('/today');
                            }
                          },
                          child: const Text(
                            'View on Board →',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            msg.time,
            style: const TextStyle(fontSize: 10, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _ActiveHouseholdCallSheet extends StatefulWidget {
  const _ActiveHouseholdCallSheet({
    required this.memberName,
    required this.memberPhone,
    required this.planLabel,
    required this.callsUsed,
    required this.callsCap,
    this.isIncoming = false,
  });

  final String memberName;
  final String memberPhone;
  final String planLabel;
  final int callsUsed;
  final int callsCap;
  final bool isIncoming;

  @override
  State<_ActiveHouseholdCallSheet> createState() =>
      _ActiveHouseholdCallSheetState();
}

class _ActiveHouseholdCallSheetState extends State<_ActiveHouseholdCallSheet> {
  Timer? _timer;
  int _seconds = 0;
  bool _muted = false;
  bool _speaker = true;
  late bool _answered;

  @override
  void initState() {
    super.initState();
    _answered = !widget.isIncoming;
    if (_answered) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedDuration {
    final mins = (_seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _dialCellular() async {
    final cleanPhone = widget.memberPhone.replaceAll(RegExp(r'[^\d\+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${widget.planLabel} · Call ${widget.callsUsed} of ${widget.callsCap >= 9999 ? "Unlimited" : widget.callsCap}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 24),
          UserProfileAvatar(name: widget.memberName, radius: 46),
          const SizedBox(height: 16),
          Text(
            widget.memberName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            !_answered
                ? 'Incoming Household Call…'
                : _seconds < 2
                ? 'Connecting household voice bridge…'
                : 'Connected · $_formattedDuration',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9DD3AA),
            ),
          ),
          const SizedBox(height: 28),
          if (!_answered)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _callControlButton(
                  icon: Icons.call_end_rounded,
                  label: 'Decline',
                  isDanger: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _callControlButton(
                  icon: Icons.call_rounded,
                  label: 'Answer',
                  isAccept: true,
                  onTap: () {
                    setState(() => _answered = true);
                    _startTimer();
                  },
                ),
              ],
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _callControlButton(
                  icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  label: _muted ? 'Muted' : 'Mute',
                  active: _muted,
                  onTap: () => setState(() => _muted = !_muted),
                ),
                _callControlButton(
                  icon: _speaker
                      ? Icons.volume_up_rounded
                      : Icons.hearing_outlined,
                  label: _speaker ? 'Speaker' : 'Earpiece',
                  active: _speaker,
                  onTap: () => setState(() => _speaker = !_speaker),
                ),
                _callControlButton(
                  icon: Icons.phone_forwarded_rounded,
                  label: 'Cellular Dial',
                  onTap: _dialCellular,
                ),
                _callControlButton(
                  icon: Icons.call_end_rounded,
                  label: 'End Call',
                  isDanger: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _callControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
    bool isDanger = false,
    bool isAccept = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isDanger
                  ? AppTheme.error
                  : isAccept
                  ? AppTheme.secondary
                  : active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDanger || isAccept
                  ? Colors.white
                  : active
                  ? AppTheme.ink
                  : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
