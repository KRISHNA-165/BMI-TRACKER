import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';
import '../models/unit_preference.dart';
import '../models/weight_entry_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/bmi_calculator.dart';
import 'auth_provider.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class ProfileState {
  final List<UserProfile> profiles;
  final UserProfile? activeProfile;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.profiles = const [],
    this.activeProfile,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    List<UserProfile>? profiles,
    UserProfile? activeProfile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profiles: profiles ?? this.profiles,
      activeProfile: activeProfile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final FirestoreService _firestoreService;
  final String userId;
  final String userEmail;

  ProfileNotifier(this._firestoreService, this.userId, this.userEmail)
      : super(const ProfileState(isLoading: true)) {
    loadProfiles();
  }

  Future<void> loadProfiles() async {
    if (userId.isEmpty) {
      state = const ProfileState(isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _firestoreService.createOrUpdateUserDoc(userId, userEmail);
      List<UserProfile> profiles = await _firestoreService.getProfiles(userId);

      // CRITICAL FIX: If user has no profiles yet (new user signup), do NOT create a fake profile!
      // Leave activeProfile = null so AuthWrapper renders UserDetailsScreen for mandatory onboarding!
      if (profiles.isEmpty) {
        state = ProfileState(
          profiles: const [],
          activeProfile: null,
          isLoading: false,
        );
        return;
      }

      // Check saved active profile ID
      final savedId = StorageService.getActiveProfileId();
      UserProfile? active;
      if (savedId != null) {
        active = profiles.firstWhere((p) => p.id == savedId, orElse: () => profiles.first);
      } else {
        active = profiles.first;
      }
      await StorageService.setActiveProfileId(active.id);

      state = ProfileState(
        profiles: profiles,
        activeProfile: active,
        isLoading: false,
      );
    } catch (e) {
      state = ProfileState(
        profiles: const [],
        activeProfile: null,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Switch currently active profile
  Future<void> setActiveProfile(UserProfile profile) async {
    await StorageService.setActiveProfileId(profile.id);
    state = ProfileState(
      profiles: state.profiles,
      activeProfile: profile,
      isLoading: false,
    );
  }

  /// Create a new profile under the user account (or first profile during onboarding)
  Future<UserProfile> createProfile({
    required String name,
    required String gender,
    required DateTime dob,
    required double heightCm,
    required double weightKg,
    required UnitPreference unitPreference,
  }) async {
    final bmi = BmiCalculator.calculateBmi(weightKg: weightKg, heightCm: heightCm);
    final category = BmiCalculator.getCategory(bmi);

    final newProfile = UserProfile(
      id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      gender: gender,
      dob: dob,
      heightCm: heightCm,
      weightKg: weightKg,
      unitPreference: unitPreference,
      currentBmi: bmi,
      bmiCategory: category,
      updatedAt: DateTime.now(),
    );

    await _firestoreService.saveProfile(userId, newProfile);

    // Initial weight log
    final initialEntry = WeightEntry(
      id: 'entry_${DateTime.now().millisecondsSinceEpoch}',
      weightKg: weightKg,
      loggedAt: DateTime.now(),
    );
    await _firestoreService.addWeightEntry(userId, newProfile.id, initialEntry);

    final updatedList = [...state.profiles, newProfile];
    await StorageService.setActiveProfileId(newProfile.id);

    state = ProfileState(
      profiles: updatedList,
      activeProfile: newProfile,
      isLoading: false,
    );

    return newProfile;
  }

  /// Update existing profile body metrics
  Future<void> updateProfileMetrics({
    required String profileId,
    String? name,
    String? gender,
    DateTime? dob,
    double? heightCm,
    double? weightKg,
    UnitPreference? unitPreference,
  }) async {
    final idx = state.profiles.indexWhere((p) => p.id == profileId);
    if (idx == -1) return;

    final current = state.profiles[idx];
    final updatedHeight = heightCm ?? current.heightCm;
    final updatedWeight = weightKg ?? current.weightKg;
    final updatedBmi = BmiCalculator.calculateBmi(weightKg: updatedWeight, heightCm: updatedHeight);
    final updatedCategory = BmiCalculator.getCategory(updatedBmi);

    final updatedProfile = current.copyWith(
      name: name ?? current.name,
      gender: gender ?? current.gender,
      dob: dob ?? current.dob,
      heightCm: updatedHeight,
      weightKg: updatedWeight,
      unitPreference: unitPreference ?? current.unitPreference,
      currentBmi: updatedBmi,
      bmiCategory: updatedCategory,
      updatedAt: DateTime.now(),
    );

    await _firestoreService.saveProfile(userId, updatedProfile);

    // If weight changed, log a new entry in weight history subcollection
    if (weightKg != null && weightKg != current.weightKg) {
      final entry = WeightEntry(
        id: 'entry_${DateTime.now().millisecondsSinceEpoch}',
        weightKg: weightKg,
        loggedAt: DateTime.now(),
      );
      await _firestoreService.addWeightEntry(userId, profileId, entry);
    }

    final updatedList = List<UserProfile>.from(state.profiles);
    updatedList[idx] = updatedProfile;

    state = ProfileState(
      profiles: updatedList,
      activeProfile: state.activeProfile?.id == profileId ? updatedProfile : state.activeProfile,
      isLoading: false,
    );
  }
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  final firestoreService = ref.watch(firestoreServiceProvider);

  if (authUser == null) {
    return ProfileNotifier(firestoreService, '', '');
  }
  return ProfileNotifier(firestoreService, authUser.uid, authUser.email ?? 'user@example.com');
});
