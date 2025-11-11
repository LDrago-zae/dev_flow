// auth_service.dart
import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication service handling both Supabase and Google Sign-In
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  GoogleSignInAccount? _currentGoogleUser;
  String _errorMessage = '';

  // Stream controllers for state changes
  final StreamController<User?> _userController =
      StreamController<User?>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  /// Required scopes for the application
  static const List<String> scopes = <String>['email', 'profile'];

  /// Current Supabase user getter
  User? get currentUser => _supabase.auth.currentUser;

  /// Google user getter
  GoogleSignInAccount? get currentGoogleUser => _currentGoogleUser;

  /// Error message getter
  String get errorMessage => _errorMessage;

  /// Stream for user changes
  Stream<User?> get userChanges => _userController.stream;

  /// Stream for error messages
  Stream<String> get errorChanges => _errorController.stream;

  /// Initialize the authentication service
  Future<void> initialize({String? clientId, String? serverClientId}) async {
    try {
      await _googleSignIn.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );

      // Listen to authentication events
      _googleSignIn.authenticationEvents
          .listen(_handleGoogleAuthenticationEvent)
          .onError(_handleAuthenticationError);

      // Listen to Supabase auth state changes
      _supabase.auth.onAuthStateChange.listen((data) {
        final AuthState state = data;
        _userController.add(state.session?.user);
      });
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    }
  }

  /// Handle Google authentication events
  Future<void> _handleGoogleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn():
        _currentGoogleUser = event.user;
        break;
      case GoogleSignInAuthenticationEventSignOut():
        _currentGoogleUser = null;
        break;
    }
  }

  /// Handle authentication errors
  Future<void> _handleAuthenticationError(Object e) async {
    _setError(
      e is GoogleSignInException
          ? _errorMessageFromSignInException(e)
          : 'Unknown error: $e',
    );
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    _errorController.add(message);
  }

  /// Sign in with Google and link with Supabase
  Future<bool> signInWithGoogle() async {
    try {
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .authenticate();
      if (googleUser == null) {
        _setError('Google sign-in cancelled');
        print('❌ Google Sign-In: User cancelled');
        return false;
      }

      print('✅ Google Sign-In: User authenticated: ${googleUser.email}');

      // Get authentication tokens from Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        _setError('Google sign-in failed: No ID token received');
        print('❌ Google Sign-In: idToken is null');
        return false;
      }

      print('✅ Google Sign-In: Got ID token, signing in to Supabase...');

      // Sign in to Supabase with Google OAuth
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
      );

      if (response.user != null) {
        print(
          '✅ Google Sign-In: Supabase sign-in successful: ${response.user!.email}',
        );
        // Check if profile exists, create if not
        await _ensureProfileExists(response.user!);
        return true;
      } else {
        _setError(
          'Failed to sign in with Google: No user returned from Supabase',
        );
        print('❌ Google Sign-In: Supabase returned null user');
        return false;
      }
    } catch (e, stackTrace) {
      final errorMsg = 'Google sign-in failed: $e';
      _setError(errorMsg);
      print('❌ Google Sign-In Error: $errorMsg');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Ensure user profile exists in database
  Future<void> _ensureProfileExists(User user) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        // Create new profile
        await _supabase.from('profiles').insert({
          'id': user.id,
          'email': user.email,
          'name': user.userMetadata?['full_name'] ?? 'User',
          'avatar_url': user.userMetadata?['avatar_url'],
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error ensuring profile exists: $e');
    }
  }

  /// Email and password sign up
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Create profile in database
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'name': 'User', // Default name
          'updated_at': DateTime.now().toIso8601String(),
        });
        return true;
      } else {
        _setError('Failed to create account');
        return false;
      }
    } catch (e) {
      _setError('Sign up failed: $e');
      return false;
    }
  }

  /// Email and password sign in
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response.user != null;
    } catch (e) {
      _setError('Sign in failed: $e');
      return false;
    }
  }

  /// Sign out from both Google and Supabase
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await _googleSignIn.disconnect();
      _currentGoogleUser = null;
      _errorMessage = '';
    } catch (e) {
      _setError('Sign out failed: $e');
    }
  }

  /// Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Error message helper
  String _errorMessageFromSignInException(GoogleSignInException e) {
    return switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'Sign in canceled',
      _ => 'GoogleSignInException ${e.code}: ${e.description}',
    };
  }

  /// Dispose resources
  void dispose() {
    _userController.close();
    _errorController.close();
  }
}
