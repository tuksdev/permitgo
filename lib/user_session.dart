// lib/permitgo/user_session.dart

/// A simple class to manage application-wide user session data.
/// This acts as a placeholder for a real authentication/state management solution.
class UserSession {
  // Static variable to hold the currently logged-in user's ID.
  // NOTE: In a real application, you would load this from a secure source 
  // (like SharedPreferences or a state management store) after login.
  static String? _currentUserId;

  /// Returns the ID of the currently logged-in user.
  /// This must be a non-null String for the renewal screen to work.
  static String get currentUserId {
    // For testing and development, you can return a hardcoded value 
    // until proper login is implemented.
    if (_currentUserId == null) {
      // !!! IMPORTANT: Replace 'TEST_USER_ID_123' with the actual user ID 
      // retrieved after successful login in your app.
      print("WARNING: UserSession.currentUserId is being accessed before being set. Using fallback ID.");
      return 'TEST_USER_ID_123'; 
    }
    return _currentUserId!;
  }

  /// Sets the user ID upon successful login.
  static void setUserId(String userId) {
    _currentUserId = userId;
    print("User ID set to: $userId");
  }

  /// Clears the user ID upon logout.
  static void clearSession() {
    _currentUserId = null;
    print("User session cleared.");
  }

  /// Optional: Check if a user is currently logged in.
  static bool get isLoggedIn => _currentUserId != null;
}