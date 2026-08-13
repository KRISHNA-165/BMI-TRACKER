import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/app_config.dart';
import 'storage_service.dart';

class AuthUser {
  final String uid;
  final String? email;
  final bool isDemo;
  final bool isEmailVerified;

  AuthUser({
    required this.uid,
    required this.email,
    this.isDemo = false,
    this.isEmailVerified = true,
  });
}

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream of Auth user changes — driven by AppConfig.isDemoMode.
  Stream<AuthUser?> get authStateChanges {
    if (AppConfig.isRealFirebase) {
      return _firebaseAuth.authStateChanges().asyncMap((user) async {
        if (user != null) {
          return AuthUser(
            uid: user.uid,
            email: user.email,
            isDemo: false,
            isEmailVerified: user.emailVerified,
          );
        }
        return null;
      });
    } else {
      // Demo mode — emit local session from SharedPreferences once
      final controller = StreamController<AuthUser?>();
      final demoEmail = StorageService.getDemoUserEmail();
      final demoId = StorageService.getDemoUserId();
      if (demoEmail != null && demoId != null) {
        controller.add(AuthUser(uid: demoId, email: demoEmail, isDemo: true));
      } else {
        controller.add(null);
      }
      return controller.stream;
    }
  }

  AuthUser? get currentUser {
    if (AppConfig.isRealFirebase && _firebaseAuth.currentUser != null) {
      final user = _firebaseAuth.currentUser!;
      return AuthUser(
        uid: user.uid,
        email: user.email,
        isDemo: false,
        isEmailVerified: user.emailVerified,
      );
    }
    final demoEmail = StorageService.getDemoUserEmail();
    final demoId = StorageService.getDemoUserId();
    if (demoEmail != null && demoId != null) {
      return AuthUser(uid: demoId, email: demoEmail, isDemo: true);
    }
    return null;
  }

  /// Sign In with Email & Password
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (AppConfig.isRealFirebase) {
      try {
        final credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final user = credential.user!;
        return AuthUser(
          uid: user.uid,
          email: user.email,
          isDemo: false,
          isEmailVerified: user.emailVerified,
        );
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      }
      // Real Firebase errors propagate — no silent fallback when credentials are configured.
    }

    // Demo Mode — local session
    final demoId = 'demo_${email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
    await StorageService.setDemoUserSession(email.trim(), demoId);
    return AuthUser(uid: demoId, email: email.trim(), isDemo: true);
  }

  /// Register / Account Creation with Email & Password
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (AppConfig.isRealFirebase) {
      try {
        final credential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final user = credential.user!;
        try {
          await user.sendEmailVerification();
        } catch (_) {}
        return AuthUser(
          uid: user.uid,
          email: user.email,
          isDemo: false,
          isEmailVerified: user.emailVerified,
        );
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      }
    }

    // Demo Mode
    final demoId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    await StorageService.setDemoUserSession(email.trim(), demoId);
    return AuthUser(uid: demoId, email: email.trim(), isDemo: true);
  }

  /// Sign In with Google
  Future<AuthUser?> signInWithGoogle() async {
    if (AppConfig.isRealFirebase) {
      try {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null; // Cancelled by user

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _firebaseAuth.signInWithCredential(credential);
        final user = userCredential.user!;
        return AuthUser(
          uid: user.uid,
          email: user.email,
          isDemo: false,
          isEmailVerified: true,
        );
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      }
    }

    // Demo Google Sign In simulation
    const demoEmail = 'google.user@example.com';
    const demoId = 'google_demo_user_123';
    await StorageService.setDemoUserSession(demoEmail, demoId);
    return AuthUser(uid: demoId, email: demoEmail, isDemo: true);
  }

  /// Password Reset Email flow
  Future<void> sendPasswordResetEmail(String email) async {
    if (AppConfig.isRealFirebase) {
      try {
        await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
        return;
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      }
    }
    // Demo mode — silently succeed (no real email sent)
  }

  /// Sign Out
  Future<void> signOut() async {
    if (AppConfig.isRealFirebase) {
      try {
        await _googleSignIn.signOut();
        await _firebaseAuth.signOut();
      } catch (_) {}
    }
    await StorageService.clearDemoUserSession();
  }

  /// Convert raw Firebase exceptions into friendly human-readable messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password combination. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address entered is not valid.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 8 characters with numbers.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please try again in a few minutes.';
      default:
        return e.message ?? 'An authentication error occurred. Please try again.';
    }
  }
}
