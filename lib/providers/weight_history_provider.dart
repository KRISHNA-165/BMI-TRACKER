import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weight_entry_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'profile_provider.dart';

class WeightHistoryState {
  /// All entries stored in Firestore/local cache (full history)
  final List<WeightEntry> allEntries;

  /// Filtered to the past 7 days — what the chart displays
  final List<WeightEntry> last7DaysEntries;

  final bool isLoading;
  final String? error;

  const WeightHistoryState({
    this.allEntries = const [],
    this.last7DaysEntries = const [],
    this.isLoading = false,
    this.error,
  });

  WeightHistoryState copyWith({
    List<WeightEntry>? allEntries,
    List<WeightEntry>? last7DaysEntries,
    bool? isLoading,
    String? error,
  }) {
    return WeightHistoryState(
      allEntries: allEntries ?? this.allEntries,
      last7DaysEntries: last7DaysEntries ?? this.last7DaysEntries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Filter a list of WeightEntry to only those logged within the past 7 days.
List<WeightEntry> filterLast7Days(List<WeightEntry> entries) {
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  return entries.where((e) => e.loggedAt.isAfter(cutoff)).toList()
    ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
}

class WeightHistoryNotifier extends StateNotifier<WeightHistoryState> {
  final FirestoreService _firestoreService;
  final String userId;
  final String? profileId;

  WeightHistoryNotifier(this._firestoreService, this.userId, this.profileId)
      : super(const WeightHistoryState(isLoading: true)) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    if (userId.isEmpty || profileId == null || profileId!.isEmpty) {
      state = const WeightHistoryState(isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final all = await _firestoreService.getWeightHistory(userId, profileId!);
      state = WeightHistoryState(
        allEntries: all,
        last7DaysEntries: filterLast7Days(all),
        isLoading: false,
      );
    } catch (e) {
      state = WeightHistoryState(
        allEntries: const [],
        last7DaysEntries: const [],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addEntry(double weightKg) async {
    if (userId.isEmpty || profileId == null) return;
    final newEntry = WeightEntry(
      id: 'entry_${DateTime.now().millisecondsSinceEpoch}',
      weightKg: weightKg,
      loggedAt: DateTime.now(),
    );
    await _firestoreService.addWeightEntry(userId, profileId!, newEntry);

    final updatedAll = [...state.allEntries, newEntry]
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

    state = state.copyWith(
      allEntries: updatedAll,
      last7DaysEntries: filterLast7Days(updatedAll),
    );
  }
}

final weightHistoryProvider =
    StateNotifierProvider<WeightHistoryNotifier, WeightHistoryState>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  final profileState = ref.watch(profileNotifierProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  return WeightHistoryNotifier(
    firestoreService,
    authUser?.uid ?? '',
    profileState.activeProfile?.id,
  );
});
