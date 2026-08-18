import 'user_entity.dart';

/// Contract definition for Authentication functionalities in domain layer.
abstract class AuthRepository {
  /// Stream to listen to auth state updates.
  Stream<UserEntity?> get authStateChanges;

  /// Fetch cached or live current authenticated user details.
  Future<UserEntity?> getCurrentUser();

  /// Authenticate user via email and password credentials.
  /// Throws [AuthFailure] on errors.
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Register a new user account.
  /// Throws [AuthFailure] on errors.
  Future<UserEntity> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  /// Authenticate user via Google Sign-In identity tokens.
  /// Throws [AuthFailure] on errors.
  Future<UserEntity> signInWithGoogle();

  /// Requests Phone OTP code delivery to the specified phone number.
  /// Triggered as part of Phone number authentication.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(dynamic error) onError,
  });

  /// Authenticate user using the verification ID and OTP code.
  /// Throws [AuthFailure] on errors.
  Future<UserEntity> signInWithPhoneNumber({
    required String verificationId,
    required String smsCode,
  });

  /// Sign out current session and flush local tokens.
  Future<void> signOut();

  /// Updates company setup association link.
  Future<void> updateUserCompanyAssociation(String uid, String companyId);
}
