/// AppConfig — single source of truth for app-wide runtime mode.
///
/// isDemoMode = true  → local SharedPreferences only, no Firebase
/// isDemoMode = false → real Firebase Auth + Firestore (production)
class AppConfig {
  AppConfig._();

  static bool _isDemoMode = true; // safe default before initialize()
  static bool _initialized = false;

  /// Must be called once in main() after Firebase initialization attempt.
  static void initialize({required bool isDemoMode}) {
    _isDemoMode = isDemoMode;
    _initialized = true;
  }

  static bool get isDemoMode {
    assert(_initialized, 'AppConfig.initialize() must be called before accessing isDemoMode.');
    return _isDemoMode;
  }

  static bool get isRealFirebase => !_isDemoMode;
}
