import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/compare_storage.dart';

class CompareIdsNotifier extends StateNotifier<List<int>?> {
  CompareIdsNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await getCompareIds();
  }

  Future<void> refresh() async {
    state = await getCompareIds();
  }

  /// `true` агар амалиёт иҷро шуд; `false` агар лимити 5 расид.
  Future<bool> toggle(int listingId) async {
    final ok = await toggleCompare(listingId);
    state = await getCompareIds();
    return ok;
  }

  Future<void> remove(int listingId) async {
    await removeFromCompare(listingId);
    state = await getCompareIds();
  }
}

final compareIdsProvider = StateNotifierProvider<CompareIdsNotifier, List<int>?>((ref) {
  return CompareIdsNotifier();
});
