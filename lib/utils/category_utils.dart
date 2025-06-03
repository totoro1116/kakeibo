// lib/utils/category_utils.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// カテゴリーマップをSharedPreferencesに保存
Future<void> saveCategories(Map<String, List<String>> categories) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('categories', jsonEncode(categories));
}

/// SharedPreferencesからカテゴリーマップを読み込む
Future<Map<String, List<String>>> loadCategories() async {
  final prefs = await SharedPreferences.getInstance();
  final dynamic raw = prefs.get('categories');

  // ★ 型チェック ★
  if (raw is String) {
    // 正常なStringならJSONデコード
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded
        .map((key, value) => MapEntry(key, List<String>.from(value as List)));
  } else {
    // String以外（Listとかnull）が入ってたら → 旧データクリアしてデフォルトを返す
    await prefs.remove('categories');
    return {
      '食費': ['お菓子', '弁当', '外食'],
      '光熱費': ['電気', 'ガス', '水道'],
      '趣味': ['ゲーム', '本', '映画'],
      '交通': ['電車', 'バス', 'タクシー'],
      '雑費': ['文房具', '日用品', 'その他'],
    };
  }
}
