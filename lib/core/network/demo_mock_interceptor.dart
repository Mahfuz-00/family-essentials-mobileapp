import 'dart:io';
import 'package:dio/dio.dart';

/// Intercepts network failures (when API is offline / unhosted) and serves
/// rich seeded demo data so the mobile app can be evaluated completely offline.
class DemoMockInterceptor extends Interceptor {
  /// Latches to true when backend is offline so all subsequent requests
  /// respond with 0ms latency without waiting for timeouts.
  static bool isOfflineMode = false;
  static String activePlanTier = 'pilot';
  static int usedCallsThisMonth = 2;
  static final List<Map<String, dynamic>> householdMessages = [
    {
      'id': 1,
      'sender_id': 2,
      'sender_name': 'Sarah Rahman',
      'recipient_id': null,
      'text': 'Hey! Are you heading past the grocery store on your way home today?',
      'created_at': '2:15 PM',
    },
    {
      'id': 2,
      'sender_id': 1,
      'sender_name': 'Tanvir Rahman',
      'recipient_id': null,
      'text': 'Yes! I checked the Pantry list—picking up milk, eggs, and sourdough.',
      'created_at': '2:18 PM',
    },
  ];

  static Map<String, dynamic> _planDetailsFor(String tier) {
    switch (tier) {
      case 'starter':
        return {
          'key': 'starter',
          'label': 'Starter Family',
          'price': '\$0',
          'seat_cap': 2,
          'place_cap': 2,
          'monthly_requests': 50,
          'pantry_items_cap': 20,
          'member_calls_cap': 0,
          'chat_messages_cap': 30,
          'receipt_scans_cap': 5,
        };
      case 'household_pro':
      case 'standard':
        return {
          'key': 'household_pro',
          'label': 'Household Pro',
          'price': '\$24.99/mo',
          'seat_cap': 10,
          'place_cap': 25,
          'monthly_requests': 1000,
          'pantry_items_cap': 500,
          'member_calls_cap': 60,
          'chat_messages_cap': 1500,
          'receipt_scans_cap': 200,
        };
      case 'enterprise':
        return {
          'key': 'enterprise',
          'label': 'Enterprise Household',
          'price': '\$49.99/mo',
          'seat_cap': 25,
          'place_cap': 100,
          'monthly_requests': 5000,
          'pantry_items_cap': 2500,
          'member_calls_cap': 9999,
          'chat_messages_cap': 9999,
          'receipt_scans_cap': 1000,
        };
      case 'pilot':
      default:
        return {
          'key': 'pilot',
          'label': 'Pilot Family Tier',
          'price': '\$14.99/mo',
          'seat_cap': 5,
          'place_cap': 10,
          'monthly_requests': 300,
          'pantry_items_cap': 100,
          'member_calls_cap': 15,
          'chat_messages_cap': 300,
          'receipt_scans_cap': 50,
        };
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final authHeader = options.headers['Authorization'] as String?;
    final isDemoToken = authHeader != null && authHeader.contains('demo-token-');

    if (isOfflineMode || isDemoToken) {
      final mock = _resolveMock(options.path, options.method.toUpperCase(), options);
      if (mock != null) {
        handler.resolve(
          Response(
            requestOptions: options,
            data: mock,
            statusCode: 200,
            statusMessage: 'OK (Offline Cache)',
          ),
        );
        return;
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final authHeader = err.requestOptions.headers['Authorization'] as String?;
    final isDemoToken = authHeader != null && authHeader.contains('demo-token-');

    final isConnectionError = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.transformTimeout ||
        err.type == DioExceptionType.unknown ||
        err.error is SocketException ||
        (err.response != null && err.response!.statusCode! >= 500);

    if (isConnectionError) {
      isOfflineMode = true;
    }

    if (!isConnectionError && !isOfflineMode && !isDemoToken) {
      handler.next(err);
      return;
    }

    final path = err.requestOptions.path;
    final method = err.requestOptions.method.toUpperCase();

    final mockResponse = _resolveMock(path, method, err.requestOptions);
    if (mockResponse != null) {
      handler.resolve(
        Response(
          requestOptions: err.requestOptions,
          data: mockResponse,
          statusCode: 200,
          statusMessage: 'OK (Demo Fallback)',
        ),
      );
      return;
    }

    handler.next(err);
  }

  dynamic _resolveMock(String path, String method, RequestOptions options) {
    final bodyMap = options.data is Map
        ? (options.data as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    // Auth login / register
    if (path.contains('/auth/login') || path.contains('/auth/register')) {
      return {
        'token': 'demo-token-12345',
        'user': {
          'id': 1,
          'name': bodyMap['name'] as String? ?? 'Tanvir Rahman',
          'email': bodyMap['email'] as String? ?? 'tanvir@familyessentials.app',
          'phone': bodyMap['phone'] as String? ?? '+15550000002',
          'timezone': 'UTC',
          'active_tenant_id': 1,
          'email_verified': true,
          'phone_verified': true,
          'is_platform_admin': false,
          'phone_verified_at': '2026-10-16T12:00:00Z',
          'location_notifications_opt_in': true,
          'voice_opt_in': true,
          'voice_escalation_opt_in': true,
          'alert_style': 'sound',
        },
      };
    }

    // Phone verification
    if (path.contains('/auth/phone/verify')) {
      return {
        'user': {
          'id': 1,
          'name': 'Tanvir Rahman',
          'email': 'tanvir@familyessentials.app',
          'phone': '+15550000002',
          'timezone': 'UTC',
          'active_tenant_id': 1,
          'email_verified': true,
          'phone_verified': true,
          'is_platform_admin': false,
          'location_notifications_opt_in': true,
          'voice_opt_in': true,
          'alert_style': 'sound',
        },
      };
    }

    // Auth profile
    if (path.endsWith('/auth/me')) {
      return {
        'data': {
          'id': 1,
          'name': 'Tanvir Rahman',
          'email': 'tanvir@familyessentials.app',
          'phone': '+15550000002',
          'timezone': 'UTC',
          'active_tenant_id': 1,
          'email_verified': true,
          'phone_verified': true,
          'is_platform_admin': false,
          'phone_verified_at': '2026-10-16T12:00:00Z',
          'location_notifications_opt_in': true,
          'voice_opt_in': true,
          'voice_escalation_opt_in': true,
          'alert_style': 'sound',
        },
      };
    }

    // Memberships (/v1/auth/tenants & /v1/tenant/memberships)
    if (path.contains('/auth/tenants') || path.contains('/tenant/memberships')) {
      return {
        'data': [
          {
            'id': 1,
            'tenant_id': 1,
            'tenant_name': 'The Tanvir Household',
            'role': 'tenant_admin',
            'is_active': true,
            'tenant': {
              'id': 1,
              'name': 'The Tanvir Household',
              'slug': 'the-tanvir-household',
              'status': 'active',
              'subscription_tier': activePlanTier,
            },
          },
        ],
      };
    }

    // Members
    if (path.contains('/tenant/members')) {
      return {
        'data': [
          {'user_id': 1, 'name': 'Tanvir Rahman', 'role': 'tenant_admin', 'email': 'tanvir@familyessentials.app'},
          {'user_id': 2, 'name': 'Sarah Rahman', 'role': 'member', 'email': 'sarah@familyessentials.app'},
        ],
      };
    }

    // Tenant Roles
    if (path.contains('/tenant/roles')) {
      return {
        'roles': {
          'tenant_admin': {'label': 'Household admin', 'detail': 'Full control, including roles and billing'},
          'co_admin': {'label': 'Co-admin', 'detail': 'Runs the household day to day, cannot change roles'},
          'member': {'label': 'Household member', 'detail': 'Creates, claims and completes requests'},
          'junior': {'label': 'Junior', 'detail': 'Raises requests and completes their own; cannot dispatch'},
        },
        'can_manage_roles': true,
      };
    }

    // Tenant Quotas
    if (path.contains('/tenant/quotas')) {
      final plan = _planDetailsFor(activePlanTier);
      final seatCap = plan['seat_cap'] as int;
      final placeCap = plan['place_cap'] as int;
      final reqCap = plan['monthly_requests'] as int;
      final pantryCap = plan['pantry_items_cap'] as int;
      final callCap = plan['member_calls_cap'] as int;
      final chatCap = plan['chat_messages_cap'] as int;
      return {
        'plan': plan,
        'enforced': true,
        'members_limit': seatCap,
        'members_count': 2,
        'voice_calls_daily_limit': callCap,
        'voice_calls_used_today': usedCallsThisMonth,
        'meters': [
          {
            'key': 'seats',
            'label': 'Family member seats',
            'used': 2,
            'cap': seatCap,
            'remaining': (seatCap - 2).clamp(0, 9999),
            'at_cap': 2 >= seatCap,
          },
          {
            'key': 'places',
            'label': 'Saved places & geofences',
            'used': 2,
            'cap': placeCap,
            'remaining': (placeCap - 2).clamp(0, 9999),
            'at_cap': 2 >= placeCap,
          },
          {
            'key': 'requests',
            'label': 'Errands & tasks this month',
            'used': 6,
            'cap': reqCap,
            'remaining': (reqCap - 6).clamp(0, 9999),
            'at_cap': 6 >= reqCap,
          },
          {
            'key': 'pantry',
            'label': 'Tracked Pantry items',
            'used': 6,
            'cap': pantryCap,
            'remaining': (pantryCap - 6).clamp(0, 9999),
            'at_cap': 6 >= pantryCap,
          },
          {
            'key': 'voice',
            'label': 'Member calls this month',
            'used': usedCallsThisMonth,
            'cap': callCap,
            'remaining': (callCap - usedCallsThisMonth).clamp(0, 9999),
            'at_cap': callCap == 0 || usedCallsThisMonth >= callCap,
          },
          {
            'key': 'chat',
            'label': 'AI & Member chat messages',
            'used': householdMessages.length,
            'cap': chatCap,
            'remaining': (chatCap - householdMessages.length).clamp(0, 9999),
            'at_cap': householdMessages.length >= chatCap,
          },
        ],
      };
    }

    // Requests Board
    if (path.contains('/requests/board')) {
      return {
        'counts': {
          'overdue': 1,
          'due_today': 2,
          'assigned_to_me': 2,
          'backlog': 2,
          'completed_today': 1,
        },
        'overdue': [
          {
            'id': 101,
            'title': 'Fix leaking kitchen tap',
            'status': 'in_progress',
            'priority': 'urgent',
            'quantity': null,
            'quantity_got': null,
            'items': [],
            'notes': 'Washer needs replacing under the sink',
            'category': 'maintenance',
            'store_name': null,
            'due_at': '2026-11-11T18:00:00Z',
            'assignee': {'id': 1, 'name': 'Tanvir Rahman'},
          },
        ],
        'due_today': [
          {
            'id': 102,
            'title': 'Weekly Organic Grocery Run',
            'status': 'in_progress',
            'priority': 'normal',
            'quantity': '4 items',
            'quantity_got': '3 of 4 items picked',
            'items': [
              {
                'name': 'Organic Whole Milk',
                'quantity_asked': '2 gal',
                'quantity_got': '2 gal',
                'is_picked': true,
              },
              {
                'name': 'Free-range Eggs',
                'quantity_asked': '1 dozen',
                'quantity_got': '1 dozen',
                'is_picked': true,
              },
              {
                'name': 'Sourdough Bread',
                'quantity_asked': '1 loaf',
                'quantity_got': '1 loaf',
                'is_picked': true,
              },
              {
                'name': 'Organic Bananas',
                'quantity_asked': '1 bunch',
                'quantity_got': null,
                'is_picked': false,
              },
            ],
            'category': 'grocery',
            'store_name': 'Whole Foods Market',
            'due_at': '2026-11-13T19:00:00Z',
            'amount_minor': 4850,
            'ledger_id': 1,
            'assignee': {'id': 1, 'name': 'Tanvir Rahman'},
          },
          {
            'id': 103,
            'title': 'Collect prescription from CVS',
            'status': 'pending',
            'priority': 'high',
            'quantity': '1 pack',
            'quantity_got': null,
            'items': [],
            'category': 'health',
            'store_name': 'CVS Pharmacy',
            'due_at': '2026-11-13T20:30:00Z',
            'assignee': {'id': 2, 'name': 'Sarah Rahman'},
          },
        ],
        'assigned_to_me': [
          {
            'id': 102,
            'title': 'Weekly Organic Grocery Run',
            'status': 'in_progress',
            'priority': 'normal',
            'quantity': '4 items',
            'quantity_got': '3 of 4 items picked',
            'items': [
              {
                'name': 'Organic Whole Milk',
                'quantity_asked': '2 gal',
                'quantity_got': '2 gal',
                'is_picked': true,
              },
              {
                'name': 'Free-range Eggs',
                'quantity_asked': '1 dozen',
                'quantity_got': '1 dozen',
                'is_picked': true,
              },
              {
                'name': 'Sourdough Bread',
                'quantity_asked': '1 loaf',
                'quantity_got': '1 loaf',
                'is_picked': true,
              },
              {
                'name': 'Organic Bananas',
                'quantity_asked': '1 bunch',
                'quantity_got': null,
                'is_picked': false,
              },
            ],
            'category': 'grocery',
            'store_name': 'Whole Foods Market',
            'due_at': '2026-11-13T19:00:00Z',
            'amount_minor': 4850,
            'ledger_id': 1,
            'assignee': {'id': 1, 'name': 'Tanvir Rahman'},
          },
          {
            'id': 104,
            'title': 'Replace HVAC Air Filters',
            'status': 'pending',
            'priority': 'normal',
            'quantity': '2 filters',
            'quantity_got': null,
            'items': [],
            'category': 'maintenance',
            'due_at': '2026-11-14T10:00:00Z',
            'assignee': {'id': 1, 'name': 'Tanvir Rahman'},
          },
        ],
        'backlog': [
          {
            'id': 105,
            'title': 'Order more whole bean coffee',
            'status': 'pending',
            'priority': 'low',
            'items': [],
            'category': 'pantry',
            'store_name': 'Whole Foods Market',
          },
          {
            'id': 106,
            'title': 'Smoke detector 9V batteries',
            'status': 'pending',
            'priority': 'normal',
            'items': [],
            'category': 'home',
            'store_name': 'Corner Hardware',
          },
        ],
        'completed_today': [
          {
            'id': 107,
            'title': 'School forms drop-off',
            'status': 'completed',
            'priority': 'normal',
            'items': [],
            'category': 'school',
            'completed_at': '2026-11-13T14:00:00Z',
            'assignee': {'id': 1, 'name': 'Tanvir Rahman'},
          },
        ],
      };
    }

    // Single Request detail
    final reqMatch = RegExp(r'/requests/(\d+)').firstMatch(path);
    if (reqMatch != null && method == 'GET') {
      final reqId = int.tryParse(reqMatch.group(1)!) ?? 102;
      return {
        'data': {
          'id': reqId,
          'title': reqId == 101
              ? 'Fix leaking kitchen tap'
              : (reqId == 103
                  ? 'Collect prescription from CVS'
                  : 'Weekly Organic Grocery Run'),
          'status': 'in_progress',
          'priority': 'normal',
          'quantity': '4 items',
          'quantity_got': '3 of 4 items picked',
          'items': [
            {
              'name': 'Organic Whole Milk',
              'quantity_asked': '2 gal',
              'quantity_got': '2 gal',
              'is_picked': true,
            },
            {
              'name': 'Free-range Eggs',
              'quantity_asked': '1 dozen',
              'quantity_got': '1 dozen',
              'is_picked': true,
            },
            {
              'name': 'Sourdough Bread',
              'quantity_asked': '1 loaf',
              'quantity_got': '1 loaf',
              'is_picked': true,
            },
            {
              'name': 'Organic Bananas',
              'quantity_asked': '1 bunch',
              'quantity_got': null,
              'is_picked': false,
            },
          ],
          'notes': 'Check organic produce section first',
          'category': 'grocery',
          'store_name': 'Whole Foods Market',
          'due_at': '2026-11-13T19:00:00Z',
          'amount_minor': 4850,
          'ledger_id': 1,
          'assignee': {'id': 1, 'name': 'Tanvir Rahman'},
          'requested_by': {'id': 2, 'name': 'Sarah Rahman'},
          'location_trigger': {
            'place_id': 3,
            'direction': 'enter',
            'place_name': 'Whole Foods Market',
          },
          'history': [
            {
              'id': 1,
              'action': 'Assigned to Tanvir Rahman',
              'actor_name': 'Sarah Rahman',
              'created_at': '2026-11-13T10:00:00Z',
            },
            {
              'id': 2,
              'action': 'Started task',
              'actor_name': 'Tanvir Rahman',
              'created_at': '2026-11-13T11:15:00Z',
            },
          ],
          'voice_calls': [],
        },
      };
    }

    // Ledgers list / create / update
    if (path.contains('/ledgers') && !path.contains('/summary') && !path.contains('/entries')) {
      if (method == 'GET') {
        return {
          'data': [
            {
              'id': 1,
              'name': 'Household budget',
              'currency': 'USD',
              'my_role': 'owner',
              'is_default': true,
              'monthly_budget_minor': 250000,
              'weekly_budget_minor': 60000,
              'yearly_budget_minor': 3000000,
            },
          ],
        };
      }
      return {
        'data': {
          'id': 1,
          'name': bodyMap['name'] as String? ?? 'Household budget',
          'currency': 'USD',
          'is_default': true,
          'monthly_budget_minor': bodyMap['monthly_budget_minor'] as int? ?? 250000,
          'weekly_budget_minor': bodyMap['weekly_budget_minor'] as int? ?? 60000,
          'yearly_budget_minor': bodyMap['yearly_budget_minor'] as int? ?? 3000000,
        },
      };
    }

    // Ledger summary
    if (path.contains('/summary')) {
      final period =
          options.queryParameters['period_type'] ??
          options.queryParameters['period'] ??
          'monthly';
      if (period == 'weekly') {
        final summaryData = {
          'currency': 'USD',
          'period': 'weekly',
          'period_type': 'weekly',
          'budget_minor': 60000,
          'remaining_budget_minor': 35500,
          'budget_percent_used': 41,
          'is_over_budget': false,
          'weekly_budget_minor': 60000,
          'yearly_budget_minor': 3000000,
          'expense_minor': 24500,
          'income_minor': 87500,
          'total_expense_minor': 24500,
          'total_income_minor': 87500,
          'net_minor': 63000,
          'by_category': [
            {'category': 'grocery', 'label': 'Grocery', 'expense_minor': 14500, 'total_minor': 14500, 'share': 0.59},
            {'category': 'utility_bill', 'label': 'Utilities', 'expense_minor': 4500, 'total_minor': 4500, 'share': 0.18},
            {'category': 'household', 'label': 'Household', 'expense_minor': 3500, 'total_minor': 3500, 'share': 0.14},
            {'category': 'other', 'label': 'Other', 'expense_minor': 2000, 'total_minor': 2000, 'share': 0.09},
          ],
          'weekly_breakdown': [
            {'week': 1, 'label': 'Mon–Tue', 'expense_minor': 6500, 'income_minor': 87500},
            {'week': 2, 'label': 'Wed–Thu', 'expense_minor': 8000, 'income_minor': 0},
            {'week': 3, 'label': 'Fri–Sun', 'expense_minor': 10000, 'income_minor': 0},
          ],
        };
        return {'data': summaryData, ...summaryData};
      } else if (period == 'yearly') {
        final summaryData = {
          'currency': 'USD',
          'period': 'yearly',
          'period_type': 'yearly',
          'budget_minor': 3000000,
          'remaining_budget_minor': 786000,
          'budget_percent_used': 74,
          'is_over_budget': false,
          'weekly_budget_minor': 60000,
          'yearly_budget_minor': 3000000,
          'expense_minor': 2214000,
          'income_minor': 4200000,
          'total_expense_minor': 2214000,
          'total_income_minor': 4200000,
          'net_minor': 1986000,
          'by_category': [
            {'category': 'rent', 'label': 'Rent & Mortgage', 'expense_minor': 1440000, 'total_minor': 1440000, 'share': 0.65},
            {'category': 'grocery', 'label': 'Grocery', 'expense_minor': 294000, 'total_minor': 294000, 'share': 0.13},
            {'category': 'utility_bill', 'label': 'Utilities', 'expense_minor': 222000, 'total_minor': 222000, 'share': 0.10},
            {'category': 'household', 'label': 'Household', 'expense_minor': 112800, 'total_minor': 112800, 'share': 0.05},
            {'category': 'healthcare', 'label': 'Healthcare', 'expense_minor': 82200, 'total_minor': 82200, 'share': 0.04},
            {'category': 'other', 'label': 'Other', 'expense_minor': 63000, 'total_minor': 63000, 'share': 0.03},
          ],
          'weekly_breakdown': [
            {'week': 1, 'label': 'Q1', 'expense_minor': 540000, 'income_minor': 1050000},
            {'week': 2, 'label': 'Q2', 'expense_minor': 555000, 'income_minor': 1050000},
            {'week': 3, 'label': 'Q3', 'expense_minor': 560000, 'income_minor': 1050000},
            {'week': 4, 'label': 'Q4', 'expense_minor': 559000, 'income_minor': 1050000},
          ],
        };
        return {'data': summaryData, ...summaryData};
      }
      final summaryData = {
        'currency': 'USD',
        'period': 'monthly',
        'period_type': 'monthly',
        'budget_minor': 250000,
        'remaining_budget_minor': 65500,
        'budget_percent_used': 74,
        'is_over_budget': false,
        'weekly_budget_minor': 60000,
        'yearly_budget_minor': 3000000,
        'expense_minor': 184500,
        'income_minor': 350000,
        'total_expense_minor': 184500,
        'total_income_minor': 350000,
        'net_minor': 165500,
        'by_category': [
          {'category': 'rent', 'label': 'Rent & Mortgage', 'expense_minor': 120000, 'total_minor': 120000, 'share': 0.65},
          {'category': 'grocery', 'label': 'Grocery', 'expense_minor': 24500, 'total_minor': 24500, 'share': 0.13},
          {'category': 'utility_bill', 'label': 'Utilities', 'expense_minor': 18500, 'total_minor': 18500, 'share': 0.10},
          {'category': 'household', 'label': 'Household', 'expense_minor': 9400, 'total_minor': 9400, 'share': 0.05},
          {'category': 'healthcare', 'label': 'Healthcare', 'expense_minor': 6850, 'total_minor': 6850, 'share': 0.04},
          {'category': 'other', 'label': 'Other', 'expense_minor': 5250, 'total_minor': 5250, 'share': 0.03},
        ],
        'weekly_breakdown': [
          {'week': 1, 'label': 'Week 1', 'expense_minor': 132000, 'income_minor': 350000},
          {'week': 2, 'label': 'Week 2', 'expense_minor': 24500, 'income_minor': 0},
          {'week': 3, 'label': 'Week 3', 'expense_minor': 18500, 'income_minor': 0},
          {'week': 4, 'label': 'Week 4', 'expense_minor': 9500, 'income_minor': 0},
        ],
      };
      return {'data': summaryData, ...summaryData};
    }

    // Ledger entries
    if (path.contains('/entries')) {
      if (method != 'GET') {
        return {
          'data': {
            'id': DateTime.now().millisecondsSinceEpoch % 10000,
            'ledger_id': 1,
            'direction': bodyMap['direction'] as String? ?? 'out',
            'amount_minor': (bodyMap['amount_minor'] as num?)?.toInt() ?? 0,
            'category': bodyMap['category'] as String? ?? 'other',
            'description': bodyMap['description'] as String? ?? 'Ledger Entry',
            'source': bodyMap['source'] as String? ?? 'manual',
            'logged_by': {'id': 1, 'name': 'Tanvir Rahman'},
            'created_at': DateTime.now().toIso8601String(),
          },
        };
      }
      return {
        'data': [
          {
            'id': 1,
            'ledger_id': 1,
            'description': 'Monthly Apartment Rent',
            'category': 'rent',
            'amount_minor': 120000,
            'direction': 'out',
            'source': 'recurring',
            'occurred_on': '2026-11-01',
            'created_at': '2026-11-01T09:00:00Z',
            'logged_by': {'id': 1, 'name': 'Tanvir Rahman'},
            'paid_by': {'id': 1, 'name': 'Tanvir Rahman'},
          },
          {
            'id': 2,
            'ledger_id': 1,
            'description': 'Weekly Fresh Grocery Run',
            'category': 'grocery',
            'amount_minor': 24500,
            'direction': 'out',
            'source': 'request',
            'occurred_on': '2026-11-13',
            'created_at': '2026-11-13T14:20:00Z',
            'logged_by': {'id': 1, 'name': 'Tanvir Rahman'},
            'paid_by': {'id': 1, 'name': 'Tanvir Rahman'},
          },
          {
            'id': 3,
            'ledger_id': 1,
            'description': 'Electric & Gas Utility Bill',
            'category': 'utility_bill',
            'amount_minor': 18500,
            'direction': 'out',
            'source': 'manual',
            'occurred_on': '2026-11-05',
            'created_at': '2026-11-05T11:30:00Z',
            'logged_by': {'id': 1, 'name': 'Tanvir Rahman'},
            'paid_by': {'id': 1, 'name': 'Tanvir Rahman'},
          },
          {
            'id': 4,
            'ledger_id': 1,
            'description': 'Monthly Salary Contribution',
            'category': 'salary',
            'amount_minor': 350000,
            'direction': 'in',
            'source': 'manual',
            'occurred_on': '2026-11-01',
            'created_at': '2026-11-01T08:00:00Z',
            'logged_by': {'id': 2, 'name': 'Sarah Rahman'},
            'paid_by': {'id': 2, 'name': 'Sarah Rahman'},
          },
        ],
      };
    }

    // Finances Overview
    if (path.contains('/finances/overview')) {
      return {
        'data': {
          'currency': 'USD',
          'total_assets_minor': 56270000,
          'total_liabilities_minor': 29920000,
          'net_worth_minor': 26350000,
          'savings_minor': 2850000,
          'investments_minor': 7420000,
          'mortgage_minor': 28500000,
          'loans_minor': 1420000,
          'monthly_budget_minor': 250000,
          'total_monthly_expenses_minor': 184500,
          'active_goals_count': 3,
          'pending_taxes_minor': 340000,
          'goals': {
            'active_count': 3,
            'achieved_count': 1,
            'total_saved_minor': 970000,
            'total_target_minor': 2850000,
          },
          'taxes': {
            'pending_count': 1,
            'pending_minor': 340000,
          },
        },
      };
    }

    // Financial Goals
    if (path.contains('/finances/goals')) {
      if (method == 'GET') {
        return {
          'data': [
            {
              'id': 1,
              'name': 'Emergency Rainy Day Fund',
              'category': 'savings',
              'target_amount_minor': 1000000,
              'current_amount_minor': 450000,
              'currency': 'USD',
              'target_date': '2027-07-01',
              'status': 'active',
              'notes': '6 months living expenses in HYSA',
              'progress_percent': 45.0,
            },
            {
              'id': 2,
              'name': 'Summer Family Beach Holiday',
              'category': 'vacation',
              'target_amount_minor': 350000,
              'current_amount_minor': 200000,
              'currency': 'USD',
              'target_date': '2027-03-15',
              'status': 'active',
              'notes': 'Flights & coastal rental',
              'progress_percent': 57.1,
            },
            {
              'id': 3,
              'name': 'Home Solar & Energy Battery',
              'category': 'home_improvement',
              'target_amount_minor': 1500000,
              'current_amount_minor': 320000,
              'currency': 'USD',
              'target_date': '2028-01-01',
              'status': 'active',
              'notes': 'Roof solar array installation',
              'progress_percent': 21.3,
            },
          ],
        };
      }
      return {'data': {'id': 99, 'status': 'ok'}};
    }

    // Financial Liabilities
    if (path.contains('/finances/liabilities')) {
      if (method == 'GET') {
        return {
          'data': [
            {
              'id': 1,
              'name': 'Primary Home Mortgage',
              'type': 'mortgage',
              'lender': 'Chase Home Finance',
              'principal_amount_minor': 34000000,
              'remaining_balance_minor': 28500000,
              'monthly_payment_minor': 185000,
              'interest_rate_bps': 415,
              'interest_rate_percent': 4.15,
              'due_day_of_month': 1,
              'currency': 'USD',
              'status': 'active',
              'notes': '30-year fixed rate mortgage',
            },
            {
              'id': 2,
              'name': 'Family Vehicle Loan',
              'type': 'loan',
              'lender': 'Ally Auto',
              'principal_amount_minor': 2800000,
              'remaining_balance_minor': 1420000,
              'monthly_payment_minor': 38500,
              'interest_rate_bps': 375,
              'interest_rate_percent': 3.75,
              'due_day_of_month': 15,
              'currency': 'USD',
              'status': 'active',
            },
          ],
        };
      }
      return {'data': {'id': 99, 'status': 'ok'}};
    }

    // Financial Assets
    if (path.contains('/finances/assets')) {
      if (method == 'GET') {
        return {
          'data': [
            {
              'id': 1,
              'name': 'Primary Family Residence',
              'type': 'real_estate',
              'institution': 'Zillow Valuation',
              'balance_minor': 46000000,
              'currency': 'USD',
              'notes': 'Estimated real estate market valuation',
            },
            {
              'id': 2,
              'name': 'High-Yield Savings Account',
              'type': 'cash',
              'institution': 'Marcus by Goldman Sachs',
              'balance_minor': 2850000,
              'contribution_monthly_minor': 50000,
              'return_rate_bps': 450,
              'return_rate_percent': 4.5,
              'currency': 'USD',
              'notes': '4.5% APY compounding monthly',
            },
            {
              'id': 3,
              'name': 'S&P 500 Index Portfolio',
              'type': 'investment',
              'institution': 'Vanguard (VFIAX)',
              'balance_minor': 7420000,
              'contribution_monthly_minor': 60000,
              'return_rate_bps': 850,
              'return_rate_percent': 8.5,
              'currency': 'USD',
            },
          ],
        };
      }
      return {'data': {'id': 99, 'status': 'ok'}};
    }

    // Financial Taxes
    if (path.contains('/finances/taxes')) {
      if (method == 'GET') {
        return {
          'data': [
            {
              'id': 1,
              'name': 'Estimated Household Income Tax 2026',
              'type': 'income_tax',
              'tax_year': 2026,
              'amount_minor': 340000,
              'due_date': '2027-01-15',
              'status': 'pending',
              'currency': 'USD',
              'notes': 'Q4 estimated federal payment',
            },
            {
              'id': 2,
              'name': 'Municipal Property Tax',
              'type': 'property_tax',
              'tax_year': 2026,
              'amount_minor': 185000,
              'due_date': '2026-10-15',
              'status': 'paid',
              'paid_at': '2026-10-15T10:00:00Z',
              'currency': 'USD',
            },
          ],
        };
      }
      return {'data': {'id': 99, 'status': 'ok'}};
    }

    // Geofences evaluate
    if (path.contains('/geofences/evaluate')) {
      return {
        'transitions': <Map<String, dynamic>>[],
        'shopping_lists': <Map<String, dynamic>>[],
        'location_notifications': <Map<String, dynamic>>[],
      };
    }

    // Place Needs (/places/:id/requests)
    if (path.contains('/places/') && path.endsWith('/requests') && method == 'GET') {
      return {
        'place': {
          'id': 3,
          'name': 'Whole Foods Market',
          'category': 'grocery',
          'latitude': 23.8103,
          'longitude': 90.4125,
          'radius_meters': 300,
        },
        'data': [
          {
            'id': 102,
            'title': 'Weekly Organic Grocery Run',
            'status': 'in_progress',
            'quantity': '4 items',
          },
        ],
      };
    }

    // Places
    if (path.contains('/places')) {
      if (method != 'GET') {
        return {
          'data': {
            'id': DateTime.now().millisecondsSinceEpoch % 10000,
            'name': bodyMap['name'] as String? ?? 'Saved Place',
            'category': bodyMap['category'] as String? ?? 'grocery',
            'address': bodyMap['address'] as String?,
            'latitude': (bodyMap['latitude'] as num?)?.toDouble() ?? 23.8103,
            'longitude': (bodyMap['longitude'] as num?)?.toDouble() ?? 90.4125,
            'radius_meters': (bodyMap['radius_meters'] as num?)?.toInt() ?? 300,
          },
        };
      }
      return {
        'data': [
          {
            'id': 1,
            'name': 'Home',
            'category': 'home',
            'latitude': 23.8040,
            'longitude': 90.4070,
            'radius_meters': 250,
          },
          {
            'id': 2,
            'name': 'Office',
            'category': 'office',
            'latitude': 23.7980,
            'longitude': 90.4150,
            'radius_meters': 300,
          },
          {
            'id': 3,
            'name': 'Whole Foods Market',
            'category': 'grocery',
            'latitude': 23.8103,
            'longitude': 90.4125,
            'radius_meters': 300,
          },
          {
            'id': 4,
            'name': 'CVS Pharmacy',
            'category': 'pharmacy',
            'latitude': 23.8130,
            'longitude': 90.4160,
            'radius_meters': 200,
          },
        ],
      };
    }

    // Pantry Essentials
    if (path.contains('/essentials')) {
      if (method != 'GET') {
        return {
          'data': {
            'id': DateTime.now().millisecondsSinceEpoch % 10000,
            'name': bodyMap['name'] as String? ?? 'Household Essential',
            'category': bodyMap['category'] as String? ?? 'Groceries',
            'default_store': bodyMap['default_store'] as String? ?? 'Whole Foods Market',
            'pack_size': bodyMap['pack_size'] as String? ?? '1 Pack',
            'cadence_days': (bodyMap['cadence_days'] as num?)?.toInt() ?? 14,
            'threshold': (bodyMap['threshold'] as num?)?.toInt() ?? 1,
            'stock_level': (bodyMap['stock_level'] as num?)?.toInt() ??
                (bodyMap['quantity'] as num?)?.toInt() ??
                2,
            'is_active': true,
            'is_due': false,
            'last_restocked_at': DateTime.now().toIso8601String(),
            'next_due_at': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
            'days_until_due': 14,
          },
        };
      }
      return {
        'summary': {
          'total': 6,
          'due': 2,
          'safety_stock': 4,
          'cadence': 2,
          'total_spent_minor': 14250,
          'projected_restock_minor': 2450,
        },
        'data': [
          {
            'id': 1,
            'name': 'Organic Whole Milk',
            'category': 'Groceries',
            'default_store': 'Whole Foods Market',
            'pack_size': '1 Gallon',
            'cadence_days': 7,
            'threshold': 2,
            'stock_level': 1,
            'is_active': true,
            'is_due': true,
            'due_reason': 'Low safety stock (1 of 2 threshold)',
            'last_restocked_at': '2026-11-06T10:00:00Z',
            'next_due_at': '2026-11-13T10:00:00Z',
            'days_until_due': 0,
          },
          {
            'id': 2,
            'name': 'Grade A Large Eggs',
            'category': 'Groceries',
            'default_store': 'Whole Foods Market',
            'pack_size': '12 Pack',
            'cadence_days': 7,
            'threshold': 2,
            'stock_level': 1,
            'is_active': true,
            'is_due': true,
            'due_reason': 'Low safety stock (1 of 2 threshold)',
            'last_restocked_at': '2026-11-06T10:00:00Z',
            'next_due_at': '2026-11-13T10:00:00Z',
            'days_until_due': 0,
          },
          {
            'id': 3,
            'name': 'Extra Virgin Olive Oil',
            'category': 'Pantry',
            'default_store': 'Trader Joe\'s',
            'pack_size': '750ml Bottle',
            'cadence_days': 30,
            'threshold': 1,
            'stock_level': 2,
            'is_active': true,
            'is_due': false,
            'last_restocked_at': '2026-10-25T14:00:00Z',
            'next_due_at': '2026-11-24T14:00:00Z',
            'days_until_due': 11,
          },
          {
            'id': 4,
            'name': 'Laundry Detergent Pods',
            'category': 'Cleaning',
            'default_store': 'Target',
            'pack_size': '42 Pods Tub',
            'cadence_days': 21,
            'threshold': 1,
            'stock_level': 2,
            'is_active': true,
            'is_due': false,
            'last_restocked_at': '2026-11-01T16:00:00Z',
            'next_due_at': '2026-11-22T16:00:00Z',
            'days_until_due': 9,
          },
          {
            'id': 5,
            'name': 'Paper Towels',
            'category': 'Household',
            'default_store': 'Costco',
            'pack_size': '12 Giant Rolls',
            'cadence_days': 30,
            'threshold': 2,
            'stock_level': 3,
            'is_active': true,
            'is_due': false,
            'last_restocked_at': '2026-10-28T11:00:00Z',
            'next_due_at': '2026-11-27T11:00:00Z',
            'days_until_due': 14,
          },
          {
            'id': 6,
            'name': 'Organic Medium Roast Coffee',
            'category': 'Pantry',
            'default_store': 'Whole Foods Market',
            'pack_size': '12oz Bag',
            'cadence_days': 14,
            'threshold': 1,
            'stock_level': 2,
            'is_active': true,
            'is_due': false,
            'last_restocked_at': '2026-11-05T09:00:00Z',
            'next_due_at': '2026-11-19T09:00:00Z',
            'days_until_due': 6,
          },
        ],
      };
    }

    // Recurring Rules
    if (path.contains('/recurring-rules')) {
      if (method != 'GET') {
        return {
          'data': {
            'id': DateTime.now().millisecondsSinceEpoch % 10000,
            'title': bodyMap['title'] as String? ?? 'Recurring Rule',
            'cadence': bodyMap['cadence'] as String? ?? 'weekly',
            'weekday': (bodyMap['weekday'] as num?)?.toInt() ?? 6,
            'day_of_month': (bodyMap['day_of_month'] as num?)?.toInt(),
            'quantity': bodyMap['quantity'] as String?,
            'priority': bodyMap['priority'] as String? ?? 'normal',
            'active': bodyMap['active'] as bool? ?? true,
            'next_run_on': '2026-11-20',
          },
        };
      }
      return {
        'data': [
          {
            'id': 1,
            'title': 'Weekly Organic Grocery Run',
            'cadence': 'weekly',
            'weekday': 6,
            'priority': 'normal',
            'category': 'grocery',
            'place_name': 'Whole Foods Market',
            'place_id': 3,
            'assignee_id': 1,
            'assignee': {'id': 1, 'name': 'Tanvir Rahman'},
            'active': true,
            'next_run_on': '2026-11-14',
            'notes': 'Milk, eggs, fresh produce and pantry staples',
          },
          {
            'id': 2,
            'title': 'Take out recycling & compost',
            'cadence': 'weekly',
            'weekday': 2,
            'priority': 'normal',
            'category': 'home',
            'place_name': 'Home',
            'place_id': 1,
            'assignee_id': 2,
            'assignee': {'id': 2, 'name': 'Sarah Rahman'},
            'active': true,
            'next_run_on': '2026-11-17',
          },
          {
            'id': 3,
            'title': 'Deep clean kitchen & microwave',
            'cadence': 'weekly',
            'weekday': 7,
            'priority': 'normal',
            'category': 'cleaning',
            'place_name': 'Home',
            'place_id': 1,
            'assignee_id': 1,
            'assignee': {'id': 1, 'name': 'Tanvir Rahman'},
            'active': true,
            'next_run_on': '2026-11-15',
          },
          {
            'id': 4,
            'title': 'Replace HVAC Air Filters',
            'cadence': 'monthly',
            'day_of_month': 1,
            'priority': 'normal',
            'category': 'maintenance',
            'place_name': 'Home',
            'place_id': 1,
            'assignee_id': 1,
            'assignee': {'id': 1, 'name': 'Tanvir Rahman'},
            'active': true,
            'next_run_on': '2026-12-01',
          },
        ],
      };
    }

    // Billing Invoices
    if (path.contains('/billing/invoices') && method == 'GET') {
      return {
        'data': [
          {
            'id': 101,
            'invoice_number': 'INV-2026-1101',
            'tier': 'household_pro',
            'amount_cents': 2900,
            'currency': 'USD',
            'status': 'paid',
            'payment_method': 'card',
            'created_at': '2026-11-01T00:00:00Z',
            'paid_at': '2026-11-01T00:01:00Z',
            'line_items': [
              {'description': 'FairShare Household Pro Monthly Subscription', 'amount_cents': 2900}
            ],
          },
          {
            'id': 102,
            'invoice_number': 'INV-2026-1001',
            'tier': 'household_pro',
            'amount_cents': 2900,
            'currency': 'USD',
            'status': 'paid',
            'payment_method': 'card',
            'created_at': '2026-10-01T00:00:00Z',
            'paid_at': '2026-10-01T00:01:00Z',
            'line_items': [
              {'description': 'FairShare Household Pro Monthly Subscription', 'amount_cents': 2900}
            ],
          },
          {
            'id': 103,
            'invoice_number': 'INV-2026-0901',
            'tier': 'family_plus',
            'amount_cents': 1500,
            'currency': 'USD',
            'status': 'paid',
            'payment_method': 'card',
            'created_at': '2026-09-01T00:00:00Z',
            'paid_at': '2026-09-01T00:01:00Z',
            'line_items': [
              {'description': 'FairShare Family Plus Monthly Subscription', 'amount_cents': 1500}
            ],
          },
        ],
      };
    }

    // Billing Payment Methods
    if (path.contains('/billing/payment-methods') && method == 'GET') {
      return {
        'data': [
          {
            'id': 'pm_1',
            'brand': 'Visa',
            'last4': '4242',
            'exp_month': 12,
            'exp_year': 2028,
            'is_default': true,
          },
          {
            'id': 'pm_2',
            'brand': 'Mastercard',
            'last4': '8888',
            'exp_month': 8,
            'exp_year': 2027,
            'is_default': false,
          },
        ],
        'cash_enabled': true,
      };
    }

    // Notifications
    if (path.contains('/notifications') && method == 'GET') {
      return {
        'data': [
          {
            'id': 1,
            'title': 'Arrived at Whole Foods Market',
            'body': '3 shopping items needed: Organic Milk, Free-range Eggs, Sourdough Bread.',
            'type': 'geofence_arrival',
            'created_at': '2026-11-13T16:30:00Z',
            'read_at': null,
          },
          {
            'id': 2,
            'title': 'Chore Assigned',
            'body': 'Sarah assigned "Collect prescription from CVS" to you.',
            'type': 'assignment',
            'created_at': '2026-11-13T14:15:00Z',
            'read_at': '2026-11-13T14:30:00Z',
          },
          {
            'id': 3,
            'title': 'Budget Warning',
            'body': 'Weekly grocery expense reached 82% of budget limit.',
            'type': 'budget_alert',
            'created_at': '2026-11-13T11:00:00Z',
            'read_at': '2026-11-13T12:00:00Z',
          },
        ],
      };
    }

    // Voice Calls Quota & Logs
    if (path.contains('/voice-calls/quota') && method == 'GET') {
      return {
        'used_today': 1,
        'daily_budget': 15,
        'max_attempts_per_request': 3,
      };
    }

    if (path.contains('/voice-calls') && method == 'GET') {
      return {
        'data': [
          {
            'id': 1,
            'request_title': 'Collect prescription from CVS',
            'status': 'completed',
            'reason': 'Overdue chore escalation',
            'duration_seconds': 38,
            'created_at': '2026-11-13T15:00:00Z',
          },
        ],
      };
    }

    // Billing plan upgrade
    if (path.contains('/billing/upgrade') && method == 'POST') {
      if (options.data is Map && options.data['tier'] is String) {
        activePlanTier = options.data['tier'] as String;
      }
      return {
        'status': 'success',
        'tier': activePlanTier,
      };
    }

    // Household Member Chat (GET & POST)
    if (path.contains('/household/messages') && method == 'GET') {
      final plan = _planDetailsFor(activePlanTier);
      return {
        'plan': {
          'key': plan['key'],
          'label': plan['label'],
          'price': plan['price'],
          'chat_cap': plan['chat_messages_cap'],
          'chat_used': householdMessages.length,
          'calls_cap': plan['member_calls_cap'],
          'calls_used': usedCallsThisMonth,
        },
        'members': [
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
        ],
        'messages': householdMessages,
      };
    }

    if (path.contains('/household/messages') && method == 'POST') {
      final plan = _planDetailsFor(activePlanTier);
      final chatCap = plan['chat_messages_cap'] as int;
      final text = options.data is Map
          ? (options.data['text'] as String? ?? '')
          : '';
      final recipientId = options.data is Map
          ? options.data['recipient_id'] as int?
          : null;
      final newMsg = {
        'id': householdMessages.length + 1,
        'sender_id': 1,
        'sender_name': 'Tanvir Rahman',
        'recipient_id': recipientId,
        'text': text,
        'created_at': 'Just now',
      };
      householdMessages.add(newMsg);
      return {
        'data': newMsg,
        'chat_used': householdMessages.length,
        'chat_cap': chatCap,
        'remaining_messages': (chatCap - householdMessages.length).clamp(0, 9999),
      };
    }

    // Direct household member call
    if (path.contains('/members/') && path.endsWith('/call') && method == 'POST') {
      final plan = _planDetailsFor(activePlanTier);
      final callCap = plan['member_calls_cap'] as int;
      usedCallsThisMonth++;
      return {
        'message': 'Call connected to household member.',
        'phone': '+8801711000002',
        'call_id': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'remaining_calls': (callCap - usedCallsThisMonth).clamp(0, 9999),
        'quota': callCap,
        'used': usedCallsThisMonth,
      };
    }

    // AI Family Dispatcher (NLP)
    if (path.contains('/requests/parse-nlp') && method == 'POST') {
      final text = options.data is Map ? (options.data['text'] as String? ?? '') : '';
      return {
        'parsed': {
          'title': text.isNotEmpty ? text : 'Errand from AI Dispatcher',
          'store_name': text.toLowerCase().contains('whole foods')
              ? 'Whole Foods Market'
              : (text.toLowerCase().contains('target') ? 'Target' : 'Local Store'),
          'assignee_name': text.toLowerCase().contains('sarah') ? 'Sarah Rahman' : 'Tanvir Rahman',
          'assignee_id': text.toLowerCase().contains('sarah') ? 2 : 1,
          'priority': text.toLowerCase().contains('urgent') || text.toLowerCase().contains('asap') ? 'urgent' : 'normal',
          'due_at': '2026-11-14T18:00:00Z',
        },
        'created': true,
        'message': 'AI Family Dispatcher processed request successfully.',
      };
    }

    // Feedback
    if (path.contains('/feedback')) {
      if (method != 'GET') {
        return {
          'data': {
            'id': DateTime.now().millisecondsSinceEpoch % 10000,
            'type': bodyMap['type'] as String? ?? 'bug',
            'status': 'new',
            'priority': bodyMap['priority'] as String? ?? 'normal',
            'subject': bodyMap['subject'] as String? ?? 'Feedback Report',
            'body': bodyMap['body'] as String? ?? '',
            'created_at': DateTime.now().toIso8601String(),
          },
        };
      }
      return {
        'data': [
          {
            'id': 1,
            'type': 'praise',
            'status': 'resolved',
            'priority': 'normal',
            'subject': 'Multi-item grocery list & offline mode',
            'body': 'Loving the new multi-item grocery list and offline mode!',
            'resolution_note': 'Thank you for your feedback!',
            'created_at': '2026-11-12T10:00:00Z',
          },
        ],
      };
    }

    // Create / Update ServiceRequest (/v1/requests or /v1/requests/:id)
    if (path.contains('/requests') && (method == 'POST' || method == 'PATCH')) {
      return {
        'data': {
          'id': DateTime.now().millisecondsSinceEpoch % 10000,
          'title': bodyMap['title'] as String? ?? 'Household Errand',
          'status': 'pending',
          'priority': bodyMap['priority'] as String? ?? 'normal',
          'quantity': bodyMap['quantity'] as String?,
          'store_name': bodyMap['store_name'] as String?,
          'due_at': bodyMap['due_at'] as String?,
          'items': bodyMap['items'] as List? ?? const [],
          'assignee': bodyMap['assignee_id'] != null
              ? {'id': bodyMap['assignee_id'], 'name': 'Tanvir Rahman'}
              : null,
          'location_trigger': bodyMap['location_trigger_place_id'] != null
              ? {
                  'place_id': bodyMap['location_trigger_place_id'],
                  'direction': bodyMap['location_trigger_direction'] ?? 'enter',
                  'place_name': 'Saved Place',
                }
              : null,
          'history': const [],
          'voice_calls': const [],
        },
      };
    }

    // Generic fallback for POST/PATCH/DELETE actions
    if (method != 'GET') {
      return {
        'data': {'id': 1, 'status': 'success', 'title': 'Updated', 'name': 'Updated'},
        'message': 'Saved successfully (Demo mode)',
      };
    }

    return null;
  }
}
