/// Base Failure class to model errors across all layers of Clean Architecture.
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// Authentication-related failures.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});

  factory AuthFailure.fromFirebaseException(
    String code,
    String? originalMessage,
  ) {
    switch (code) {
      case 'user-not-found':
        return const AuthFailure(
          'No user found with this email.',
          code: 'user-not-found',
        );
      case 'wrong-password':
        return const AuthFailure(
          'Invalid credentials provided.',
          code: 'wrong-password',
        );
      case 'invalid-email':
        return const AuthFailure(
          'The email address is badly formatted.',
          code: 'invalid-email',
        );
      case 'user-disabled':
        return const AuthFailure(
          'This user account has been disabled.',
          code: 'user-disabled',
        );
      case 'email-already-in-use':
        return const AuthFailure(
          'An account already exists for this email.',
          code: 'email-already-in-use',
        );
      case 'operation-not-allowed':
        return const AuthFailure(
          'Authentication operation not allowed.',
          code: 'operation-not-allowed',
        );
      case 'weak-password':
        return const AuthFailure(
          'The password is too weak.',
          code: 'weak-password',
        );
      case 'network-request-failed':
        return const AuthFailure(
          'Network error. Please check your connection.',
          code: 'network-request-failed',
        );
      default:
        return AuthFailure(
          originalMessage ?? 'An unknown authentication error occurred.',
          code: code,
        );
    }
  }
}

/// Firestore database or Firebase Storage failures.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});

  factory ServerFailure.fromFirebaseException(
    String code,
    String? originalMessage,
  ) {
    switch (code) {
      case 'permission-denied':
        return const ServerFailure(
          'Access denied. You do not have permission to view or modify this resource.',
          code: 'permission-denied',
        );
      case 'not-found':
        return const ServerFailure(
          'The requested resource was not found.',
          code: 'not-found',
        );
      case 'already-exists':
        return const ServerFailure(
          'The document or resource already exists.',
          code: 'already-exists',
        );
      case 'resource-exhausted':
        return const ServerFailure(
          'Database quota exceeded. Please contact support.',
          code: 'resource-exhausted',
        );
      case 'failed-precondition':
        return const ServerFailure(
          'Operation failed due to database state issues.',
          code: 'failed-precondition',
        );
      case 'unavailable':
        return const ServerFailure(
          'Service is temporarily offline. Changes will be synced when you go online.',
          code: 'unavailable',
        );
      default:
        return ServerFailure(
          originalMessage ?? 'A database error occurred.',
          code: code,
        );
    }
  }
}

/// Connectivity and general network failures.
class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'No internet connection detected.'})
      : super(message, code: 'no-connection');
}

/// Local storage / Cache failures.
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}
