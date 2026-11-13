import 'dart:io';
import 'package:dio/dio.dart';

/// Intercepts network failures (when API is offline / unhosted) and serves
/// rich seeded demo data so the mobile app can be evaluated completely offline.
class DemoMockInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isConnectionError = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.unknown ||
        err.error is SocketException ||
        (err.response != null && err.response!.statusCode! >= 500);

    if (!isConnectionError) {
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
    // Auth login / register
    if (path.contains('/auth/login') || path.contains('/auth/register')) {
      return {
        'token': 'demo-token-12345',
        'user': {
          'id': 1,
          'name': 'Tanvir Rahman (Demo)',
          'email': 'tanvir@familyessentials.app',
          'phone': '+15550000002',
          'timezone': 'UTC',
          'active_tenant_id': 1,
          'phone_verified_at': '2026-10-16T12:00:00Z',
          'location_notifications_opt_in': true,
          'voice_escalation_opt_in': true,
          'alert_style': 'balanced',
        },
      };
    }

    // Auth profile
    if (path.endsWith('/auth/me')) {
      return {
        'data': {
          'id': 1,
          'name': 'Tanvir Rahman (Demo)',
          'email': 'tanvir@familyessentials.app',
          'phone': '+15550000002',
          'timezone': 'UTC',
          'active_tenant_id': 1,
          'phone_verified_at': '2026-10-16T12:00:00Z',
          'location_notifications_opt_in': true,
          'voice_escalation_opt_in': true,
          'alert_style': 'balanced',
        },
      };
    }

    // Memberships
    if (path.contains('/tenant/memberships')) {
      return {
        'data': [
          {
            'id': 1,
            'tenant_id': 1,
            'tenant_name': 'The Tanvir Household',
            'role': 'admin',
            'is_active': true,
          }
        ],
      };
    }

    // Members
    if (path.contains('/tenant/members')) {
      return {
        'data': [
          {'user_id': 1, 'name': 'Tanvir Rahman'},
          {'user_id': 2, 'name': 'Sarah Rahman'},
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

    // Ledgers list
    if (path.endsWith('/ledgers') && method == 'GET') {
      return {
        'data': [
          {
            'id': 1,
            'name': 'Household budget',
            'currency': 'USD',
            'my_role': 'owner',
            'monthly_budget_minor': 250000,
            'weekly_budget_minor': 60000,
            'yearly_budget_minor': 3000000,
          },
        ],
      };
    }

    // Ledger summary
    if (path.contains('/summary')) {
      return {
        'currency': 'USD',
        'period': 'month',
        'budget_minor': 250000,
        'weekly_budget_minor': 60000,
        'yearly_budget_minor': 3000000,
        'total_expense_minor': 184500,
        'total_income_minor': 350000,
        'net_minor': 165500,
        'by_category': [
          {'category': 'rent', 'total_minor': 120000},
          {'category': 'grocery', 'total_minor': 24500},
          {'category': 'utility_bill', 'total_minor': 18500},
          {'category': 'household', 'total_minor': 9400},
          {'category': 'healthcare', 'total_minor': 6850},
          {'category': 'other', 'total_minor': 5250},
        ],
      };
    }

    // Ledger entries
    if (path.contains('/entries')) {
      return {
        'data': [
          {
            'id': 1,
            'description': 'Monthly Apartment Rent',
            'category': 'rent',
            'amount_minor': 120000,
            'direction': 'expense',
            'occurred_on': '2026-11-01',
            'paid_by': {'id': 1, 'name': 'Tanvir Rahman'},
          },
          {
            'id': 2,
            'description': 'Weekly Fresh Grocery Run',
            'category': 'grocery',
            'amount_minor': 24500,
            'direction': 'expense',
            'occurred_on': '2026-11-13',
            'paid_by': {'id': 1, 'name': 'Tanvir Rahman'},
          },
          {
            'id': 3,
            'description': 'Electric & Gas Utility Bill',
            'category': 'utility_bill',
            'amount_minor': 18500,
            'direction': 'expense',
            'occurred_on': '2026-11-05',
            'paid_by': {'id': 1, 'name': 'Tanvir Rahman'},
          },
          {
            'id': 4,
            'description': 'Monthly Salary Contribution',
            'category': null,
            'amount_minor': 350000,
            'direction': 'income',
            'occurred_on': '2026-11-01',
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
          'monthly_budget_minor': 250000,
          'total_monthly_expenses_minor': 184500,
          'active_goals_count': 3,
          'pending_taxes_minor': 340000,
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

    // Places
    if (path.contains('/places')) {
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

    // Generic fallback for POST/PATCH/DELETE actions
    if (method != 'GET') {
      return {
        'data': {'id': 1, 'status': 'success'},
        'message': 'Saved successfully (Demo mode)',
      };
    }

    return null;
  }
}
