import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 固定費リスト保存
Future<void> saveFixedCosts(List<Map<String, dynamic>> fixedCosts) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('fixed_costs', jsonEncode(fixedCosts));
}

/// 固定費リスト読み込み
Future<List<Map<String, dynamic>>> loadFixedCosts() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('fixed_costs');
  if (raw == null) return [];
  final decoded = jsonDecode(raw) as List;
  // Map<String, dynamic>型に変換
  return decoded
      .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
      .toList();
}

DateTime _addInterval(DateTime date, String frequency) {
  switch (frequency) {
    case 'FixedFrequency.monthly':
      return DateTime(date.year, date.month + 1, date.day);
    case 'FixedFrequency.halfYearly':
      return DateTime(date.year, date.month + 6, date.day);
    case 'FixedFrequency.yearly':
      return DateTime(date.year + 1, date.month, date.day);
    default:
      return DateTime(date.year, date.month + 1, date.day);
  }
}

DateTime calculateNextDate(int payDay, String frequency,
    [DateTime? from]) {
  final now = from ?? DateTime.now();
  DateTime next = DateTime(now.year, now.month, payDay);
  if (!next.isAfter(now)) {
    next = _addInterval(next, frequency);
  }
  while (!next.isAfter(now)) {
    next = _addInterval(next, frequency);
  }
  return next;
}

/// アプリ起動時に呼び出して、必要な固定費を自動で支出に追加
Future<void> autoAddFixedCosts() async {
  final prefs = await SharedPreferences.getInstance();

  // Load fixed costs
  final fixedRaw = prefs.getString('fixed_costs');
  final List<Map<String, dynamic>> fixedCosts = fixedRaw == null
      ? []
      : (jsonDecode(fixedRaw) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  // Load expenses
  final expRaw = prefs.getString('expenses');
  final List<Map<String, dynamic>> expenses = expRaw == null
      ? []
      : (jsonDecode(expRaw) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  final now = DateTime.now();

  for (final cost in fixedCosts) {
    // Backwards compatibility: if nextDate is missing, calculate it
    DateTime nextDate;
    if (cost.containsKey('nextDate')) {
      nextDate = DateTime.parse(cost['nextDate']);
    } else {
      nextDate = calculateNextDate(cost['payDay'], cost['frequency']);
    }

    while (!nextDate.isAfter(now)) {
      expenses.add({
        'amount': cost['amount'],
        'category': cost['parent'],
        'subcategory': cost['child'],
        'date': nextDate.toIso8601String(),
      });
      nextDate = _addInterval(nextDate, cost['frequency']);
    }

    cost['nextDate'] = nextDate.toIso8601String();
  }

  await prefs.setString('expenses', jsonEncode(expenses));
  await prefs.setString('fixed_costs', jsonEncode(fixedCosts));
}
