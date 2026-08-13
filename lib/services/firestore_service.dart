import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_model.dart';
import '../models/weight_entry_model.dart';
import '../utils/app_config.dart';
import 'storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// All Firestore access gates through AppConfig.isRealFirebase
  bool get _canUseFirestore => AppConfig.isRealFirebase;

  DocumentReference _userDoc(String userId) => _firestore.collection('users').doc(userId);
  CollectionReference _profilesCol(String userId) => _userDoc(userId).collection('profiles');
  CollectionReference _weightHistoryCol(String userId, String profileId) =>
      _profilesCol(userId).doc(profileId).collection('weightHistory');

  Future<void> createOrUpdateUserDoc(String userId, String email) async {
    if (!_canUseFirestore) return;
    try {
      await _userDoc(userId).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<List<UserProfile>> getProfiles(String userId) async {
    if (_canUseFirestore) {
      try {
        final snapshot = await _profilesCol(userId).get();
        final profiles = snapshot.docs.map((doc) {
          return UserProfile.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
        await StorageService.saveProfilesLocally(userId, profiles);
        return profiles;
      } catch (_) {}
    }
    return StorageService.getLocalProfiles(userId);
  }

  /// Real-time stream — available for future use or widgets that want live updates.
  Stream<List<UserProfile>> getProfilesStream(String userId) {
    if (_canUseFirestore) {
      return _profilesCol(userId).snapshots().map((snapshot) {
        final profiles = snapshot.docs.map((doc) {
          return UserProfile.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
        StorageService.saveProfilesLocally(userId, profiles);
        return profiles;
      });
    }
    return Stream.value(StorageService.getLocalProfiles(userId));
  }

  Future<void> saveProfile(String userId, UserProfile profile) async {
    if (_canUseFirestore) {
      try {
        await _profilesCol(userId).doc(profile.id).set(profile.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }

    final existing = StorageService.getLocalProfiles(userId);
    final idx = existing.indexWhere((p) => p.id == profile.id);
    if (idx >= 0) {
      existing[idx] = profile;
    } else {
      existing.add(profile);
    }
    await StorageService.saveProfilesLocally(userId, existing);
  }

  Future<void> deleteProfile(String userId, String profileId) async {
    final profiles = await getProfiles(userId);
    if (profiles.length <= 1) {
      throw Exception('Cannot delete the last profile. At least one profile is required.');
    }

    if (_canUseFirestore) {
      try {
        await _profilesCol(userId).doc(profileId).delete();
      } catch (_) {}
    }

    final updated = profiles.where((p) => p.id != profileId).toList();
    await StorageService.saveProfilesLocally(userId, updated);
  }

  /// Fetch weight history — all entries (caller is responsible for filtering to 7 days).
  Future<List<WeightEntry>> getWeightHistory(String userId, String profileId) async {
    if (_canUseFirestore) {
      try {
        final snapshot = await _weightHistoryCol(userId, profileId)
            .orderBy('loggedAt', descending: false)
            .get();
        final entries = snapshot.docs.map((doc) {
          return WeightEntry.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
        await StorageService.saveWeightHistoryLocally(profileId, entries);
        return entries;
      } catch (_) {}
    }
    return StorageService.getLocalWeightHistory(profileId);
  }

  /// Real-time stream for weight history.
  Stream<List<WeightEntry>> getWeightHistoryStream(String userId, String profileId) {
    if (_canUseFirestore) {
      return _weightHistoryCol(userId, profileId)
          .orderBy('loggedAt', descending: false)
          .snapshots()
          .map((snapshot) {
        final entries = snapshot.docs.map((doc) {
          return WeightEntry.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
        StorageService.saveWeightHistoryLocally(profileId, entries);
        return entries;
      });
    }
    return Stream.value(StorageService.getLocalWeightHistory(profileId));
  }

  Future<void> addWeightEntry(String userId, String profileId, WeightEntry entry) async {
    if (_canUseFirestore) {
      try {
        await _weightHistoryCol(userId, profileId).doc(entry.id).set(entry.toMap());
      } catch (_) {}
    }

    final existing = StorageService.getLocalWeightHistory(profileId);
    existing.add(entry);
    existing.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    await StorageService.saveWeightHistoryLocally(profileId, existing);
  }
}
