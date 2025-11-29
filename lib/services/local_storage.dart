import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String key = "transactions";

  // Kaydet
  static Future<void> saveTransactions(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(list);
    await prefs.setString(key, jsonString);
  }

  // Oku
  static Future<List<Map<String, dynamic>>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);

    if (jsonString == null) return [];

    final List decoded = jsonDecode(jsonString);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
