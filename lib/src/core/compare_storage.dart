import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Ҳамон `web/src/utils/compare.js` — то 5 объявлений дар сравнение.
const String kCompareListingsKey = 'compare_listings';
const int kMaxCompareListings = 5;

Future<List<int>> getCompareIds() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(kCompareListingsKey);
  if (raw == null || raw.isEmpty) return [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded.map((e) => int.tryParse(e.toString()) ?? 0).where((id) => id > 0).toList();
  } catch (_) {
    return [];
  }
}

Future<void> _saveCompareIds(List<int> ids) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(kCompareListingsKey, jsonEncode(ids));
}

/// Агар алакай 5 бошад ва илова кардан мехоҳед — `false`.
Future<bool> toggleCompare(int listingId) async {
  if (listingId <= 0) return false;
  final ids = await getCompareIds();
  if (ids.contains(listingId)) {
    await _saveCompareIds(ids.where((i) => i != listingId).toList());
    return true;
  }
  if (ids.length >= kMaxCompareListings) return false;
  await _saveCompareIds([...ids, listingId]);
  return true;
}

Future<void> removeFromCompare(int listingId) async {
  final ids = await getCompareIds();
  await _saveCompareIds(ids.where((i) => i != listingId).toList());
}

Future<bool> isInCompare(int listingId) async {
  final ids = await getCompareIds();
  return ids.contains(listingId);
}
