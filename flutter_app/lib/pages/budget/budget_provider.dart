// lib/pages/budget/budget_provider.dart
// Matches existing project pattern: Provider + ChangeNotifier, ApiService calls,
// SharedPreferences for memberType / familyId checks.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FamilyBudgetProvider extends ChangeNotifier {
  static const String _baseUrl = 'http://localhost:8000/api';

  // ── State ──────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> budgets = [];
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> futureEvents = [];
  List<Map<String, dynamic>> inventoryCategories = [];
  List<Map<String, dynamic>> familyInventoryItems = [];
  List<Map<String, dynamic>> familyMembers = [];
  Map<String, dynamic>? selectedBudget;
  Map<String, dynamic>? analyticsData;

  bool isLoading = false;
  bool isParentUser = false;
  String? errorMessage;

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isParentUser = (prefs.getString('memberType') ?? '') == 'Parent';
    await loadReferenceData();
    await loadBudgets();
    await loadFutureEvents();
  }

  // ── Auth header helper ─────────────────────────────────────────────────────
  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    errorMessage = msg;
    notifyListeners();
  }

  Map<String, dynamic> _normalizeBudget(Map<String, dynamic> budget) {
    final allocations = List<Map<String, dynamic>>.from(budget['allocations'] ?? []);
    return {
      ...budget,
      'budget_type': budget['budget_type'] ?? 'household',
      'period_type': budget['period_type'] ?? 'monthly',
      'total_spent': (budget['spent_amount'] ?? budget['total_spent'] ?? 0),
      'remaining_amount': (budget['remaining_amount'] ?? ((budget['total_amount'] ?? 0) - (budget['spent_amount'] ?? 0))),
      'emergency_fund_amount': budget['emergency_fund_amount'] ?? 0,
      'emergency_fund_spent': budget['emergency_fund_spent'] ?? 0,
      'categories': allocations.map((allocation) {
        final category = allocation['inventory_category_id'];
        final categoryId = category is Map
            ? (category['_id']?.toString() ?? '')
            : (category?.toString() ?? '');
        final title = category is Map ? (category['title'] ?? 'Uncategorized') : 'Uncategorized';
        return {
          '_id': categoryId,
          'category_id': categoryId,
          'name': title,
          'allocated_amount': allocation['allocated_amount'] ?? 0,
          'spent_amount': allocation['spent_amount'] ?? 0,
          'threshold_percentage': allocation['threshold_percentage'] ?? 15,
          'color': '#4CAF50',
        };
      }).toList(),
    };
  }

  Future<void> loadReferenceData() async {
    try {
      final headers = await _headers();
      final results = await Future.wait([
        http.get(Uri.parse('$_baseUrl/inventory-categories'), headers: headers),
        http.get(Uri.parse('$_baseUrl/inventory/all-items'), headers: headers),
        http.get(Uri.parse('$_baseUrl/members'), headers: headers),
      ]);

      if (results[0].statusCode == 200) {
        final data = jsonDecode(results[0].body);
        inventoryCategories = List<Map<String, dynamic>>.from(data['data']['categories'] ?? []);
      }

      if (results[1].statusCode == 200) {
        final data = jsonDecode(results[1].body);
        familyInventoryItems = List<Map<String, dynamic>>.from(data['data']['items'] ?? []);
      }

      if (results[2].statusCode == 200) {
        final data = jsonDecode(results[2].body);
        familyMembers = List<Map<String, dynamic>>.from(data['data']['members'] ?? []);
      }

      notifyListeners();
    } catch (_) {}
  }

  // ── Budgets ────────────────────────────────────────────────────────────────
  Future<void> loadBudgets() async {
    _setLoading(true);
    _setError(null);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/budget/periods'),
        headers: await _headers(),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        budgets = List<Map<String, dynamic>>.from(data['data']['period_budgets'] ?? [])
            .map((budget) => _normalizeBudget(Map<String, dynamic>.from(budget)))
            .toList();
      } else {
        _setError(data['message'] ?? 'Failed to load budgets');
      }
    } catch (e) {
      _setError('Network error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> createBudget(Map<String, dynamic> payload) async {
    final headers = await _headers();

    final periodResponse = await http.post(
      Uri.parse('$_baseUrl/budget/periods'),
      headers: headers,
      body: jsonEncode({
        'title': payload['title'],
        'period_type': payload['period_type'] ?? 'monthly',
        'start_date': payload['start_date'] ?? DateTime.now().toIso8601String(),
        'end_date': payload['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'total_amount': payload['total_amount'],
        'currency': payload['currency'] ?? 'EGP',
        'threshold_percentage': payload['threshold_percentage'] ?? 15,
      }),
    );

    final periodData = jsonDecode(periodResponse.body);
    if (periodResponse.statusCode != 201) {
      throw Exception(periodData['message'] ?? 'Failed to create budget');
    }

    final periodBudget = Map<String, dynamic>.from(periodData['data']['period_budget'] ?? {});
    final periodId = periodBudget['_id']?.toString();

    final allocations = List<Map<String, dynamic>>.from(payload['allocations'] ?? []);
    if (periodId != null && periodId.isNotEmpty && allocations.isNotEmpty) {
      final allocationResponse = await http.put(
        Uri.parse('$_baseUrl/budget/periods/$periodId/allocations'),
        headers: headers,
        body: jsonEncode({'allocations': allocations}),
      );
      if (allocationResponse.statusCode != 200) {
        final allocationData = jsonDecode(allocationResponse.body);
        throw Exception(allocationData['message'] ?? 'Failed to save budget allocations');
      }
    }

    final allowances = List<Map<String, dynamic>>.from(payload['allowances'] ?? []);
    if (periodId != null && periodId.isNotEmpty && allowances.isNotEmpty) {
      final allowanceResponse = await http.put(
        Uri.parse('$_baseUrl/budget/periods/$periodId/allowances'),
        headers: headers,
        body: jsonEncode({'allowances': allowances}),
      );
      if (allowanceResponse.statusCode != 200) {
        final allowanceData = jsonDecode(allowanceResponse.body);
        throw Exception(allowanceData['message'] ?? 'Failed to save member allowances');
      }
    }

    await loadReferenceData();
    await loadBudgets();
    return _normalizeBudget(periodBudget);
  }

  Future<void> updateBudget(String budgetId, Map<String, dynamic> payload) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/budget/periods/$budgetId'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      await loadBudgets();
    } else {
      throw Exception(data['message'] ?? 'Failed to update budget');
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/budget/periods/$budgetId'),
      headers: await _headers(),
    );
    if (res.statusCode == 204) {
      budgets.removeWhere((b) => b['_id'] == budgetId);
      notifyListeners();
    } else {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Failed to delete budget');
    }
  }

  Future<void> selectBudget(String budgetId) async {
    _setLoading(true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/budget/periods/$budgetId'),
        headers: await _headers(),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final raw = data['data']['period_budget'];
        selectedBudget = raw != null ? _normalizeBudget(Map<String, dynamic>.from(raw)) : null;
        await loadExpenses(budgetId: budgetId);
        await loadAnalytics(budgetId);
      }
    } finally {
      _setLoading(false);
    }
  }

  // ── Expenses ───────────────────────────────────────────────────────────────
  Future<void> loadExpenses({String? budgetId}) async {
    _setLoading(true);
    try {
      String url = '$_baseUrl/budget/analytics';
      if (budgetId != null && budgetId.isNotEmpty) {
        url += '?period_budget_id=$budgetId';
      }
      final res = await http.get(Uri.parse(url), headers: await _headers());
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        expenses = List<Map<String, dynamic>>.from(data['data']['expense_details'] ?? []);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/budgets/expenses/new'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      if (selectedBudget != null) {
        await selectBudget(selectedBudget!['_id']);
      }
      return data['data']['expense'];
    }
    throw Exception(data['message'] ?? 'Failed to create expense');
  }

  Future<void> deleteExpense(String expenseId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/budgets/expenses/$expenseId'),
      headers: await _headers(),
    );
    if (res.statusCode == 204) {
      expenses.removeWhere((e) => e['_id'] == expenseId);
      notifyListeners();
    } else {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Failed to delete expense');
    }
  }

  // ── Expense Requests (child → parent approval) ─────────────────────────────
  Future<Map<String, dynamic>> submitExpenseRequest(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/budget/expense-requests'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) return data['data']['expense'];
    throw Exception(data['message'] ?? 'Failed to submit request');
  }

  Future<List<Map<String, dynamic>>> getExpenseRequests({String? status}) async {
    var url = '$_baseUrl/budget/expense-requests';
    if (status != null) url += '?status=$status';
    final res = await http.get(Uri.parse(url), headers: await _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['data']['requests'] ?? []);
    }
    throw Exception(data['message'] ?? 'Failed to load requests');
  }

  Future<void> approveExpenseRequest(String expenseId) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/budget/expense-requests/$expenseId/approve'),
      headers: await _headers(),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['message'] ?? 'Failed to approve');
  }

  Future<void> rejectExpenseRequest(String expenseId) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/budget/expense-requests/$expenseId/reject'),
      headers: await _headers(),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['message'] ?? 'Failed to reject');
  }

  Future<void> uploadReceiptPhoto(String expenseId, String photoUrl) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/budgets/expenses/$expenseId/photo'),
      headers: await _headers(),
      body: jsonEncode({'receipt_photo_url': photoUrl}),
    );
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Failed to upload photo');
    }
    // Refresh expenses
    if (selectedBudget != null) await loadExpenses(budgetId: selectedBudget!['_id']);
  }

  Future<void> useEmergencyFund(
      String budgetId, String categoryId, double amount, String description) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/budgets/$budgetId/emergency'),
      headers: await _headers(),
      body: jsonEncode({
        'budget_category_id': categoryId,
        'amount': amount,
        'description': description,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      await selectBudget(budgetId);
    } else {
      throw Exception(data['message'] ?? 'Failed to use emergency fund');
    }
  }

  // ── Analytics ──────────────────────────────────────────────────────────────
  Future<void> loadAnalytics(String budgetId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/budget/analytics?period_budget_id=$budgetId'),
        headers: await _headers(),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        analyticsData = data['data'];
        expenses = List<Map<String, dynamic>>.from(data['data']['expense_details'] ?? []);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getBudgetAlerts(String budgetId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/budgets/$budgetId/alerts'),
      headers: await _headers(),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return data['data'];
    throw Exception(data['message'] ?? 'Failed to load alerts');
  }

  // ── Future Events ──────────────────────────────────────────────────────────
  Future<void> loadFutureEvents() async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/budgets/future-events/all'),
        headers: await _headers(),
      );
      final data = jsonDecode(res.body);
      print('✓ loadFutureEvents response: Status=${res.statusCode}');
      if (res.statusCode == 200) {
        final rawEvents = List<Map<String, dynamic>>.from(data['data']['events'] ?? []);
        futureEvents = rawEvents.map((e) => {
          ...e,
          'name': (e['title'] ?? e['name'] ?? '').toString(),
          'expected_date': (e['event_date'] ?? e['expected_date'] ?? '').toString(),
          'estimated_cost': e['estimated_cost'] ?? 0,
          'saved_amount': e['total_contributed_money'] ?? e['saved_amount'] ?? 0,
        }).toList();
        print('✓ loadFutureEvents mapped ${futureEvents.length} events!');
        notifyListeners();
      } else {
        print('✗ loadFutureEvents failed: ${res.statusCode} - ${data['message']}');
      }
    } catch (e) {
      print('✗ loadFutureEvents error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createFutureEvent(Map<String, dynamic> payload) async {
    final normalizedPayload = {
      'title': (payload['title'] ?? payload['name'] ?? '').toString().trim(),
      'description': (payload['description'] ?? '').toString(),
      'event_date': (payload['event_date'] ?? payload['expected_date'] ?? DateTime.now().toIso8601String()).toString(),
      'estimated_cost': (payload['estimated_cost'] ?? payload['cost'] ?? 0),
      'funding_source': (payload['funding_source'] ?? 'budget').toString(),
      'required_points': (payload['required_points'] ?? 0),
    };

    final res = await http.post(
      Uri.parse('$_baseUrl/budgets/future-events'),
      headers: await _headers(),
      body: jsonEncode(normalizedPayload),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      await loadFutureEvents();
    } else {
      throw Exception(data['message'] ?? 'Failed to create event');
    }
  }

  Future<void> updateFutureEvent(String eventId, Map<String, dynamic> payload) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/budgets/future-events/$eventId'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      await loadFutureEvents();
    } else {
      throw Exception(data['message'] ?? 'Failed to update event');
    }
  }

  Future<void> deleteFutureEvent(String eventId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/budgets/future-events/$eventId'),
      headers: await _headers(),
    );
    if (res.statusCode == 204) {
      futureEvents.removeWhere((e) => e['_id'] == eventId);
      notifyListeners();
    } else {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Failed to delete event');
    }
  }

  // ── Cross-module links ─────────────────────────────────────────────────────
  Future<void> linkReceiptToExpense(
      String budgetId, String categoryId, String receiptId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/budgets/link/receipt'),
      headers: await _headers(),
      body: jsonEncode({
        'budget_id': budgetId,
        'budget_category_id': categoryId,
        'receipt_id': receiptId,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      await selectBudget(budgetId);
    } else {
      throw Exception(data['message'] ?? 'Failed to link receipt');
    }
  }

  Future<void> linkRedeemToExpense(
      String budgetId, String categoryId, String redeemId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/budgets/link/redeem'),
      headers: await _headers(),
      body: jsonEncode({
        'budget_id': budgetId,
        'budget_category_id': categoryId,
        'redeem_id': redeemId,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      await selectBudget(budgetId);
    } else {
      throw Exception(data['message'] ?? 'Failed to link redemption');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get activeReminders =>
      futureEvents.where((e) => e['should_remind'] == true).toList();

  double getTotalSpent(Map<String, dynamic> budget) =>
      (budget['total_spent'] ?? 0).toDouble();

  double getRemainingAmount(Map<String, dynamic> budget) =>
      (budget['remaining_amount'] ?? 0).toDouble();

  double getEmergencyRemaining(Map<String, dynamic> budget) =>
      (budget['emergency_fund_remaining'] ?? 0).toDouble();
}