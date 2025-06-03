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
