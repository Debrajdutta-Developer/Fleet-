import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';
import '../domain/user_entity.dart';

/// Provider for AuthRepository mapping implementation details to domain specifications.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    localStorage: ref.watch(localStorageServiceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

/// StreamProvider listening to raw Firebase Auth authentication changes.
final authStateChangesProvider = StreamProvider<UserEntity?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// StateProvider holding current authenticated UserEntity profile,
/// initialized as a sync provider for reactive UI consumption.
final currentUserProvider = StateProvider<UserEntity?>((ref) {
  final asyncUser = ref.watch(authStateChangesProvider);
  return asyncUser.valueOrNull;
});

/// UI Controller state holding authentication status indicators.
class AuthState {
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.isLoading = false, this.errorMessage});

  AuthState copyWith({bool? isLoading, String? errorMessage}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// StateNotifier controller handling Authentication screen behaviors (login, signup, logouts).
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthController({required AuthRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const AuthState());

  /// Log in action handler.
  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update global current user cache
      _ref.read(currentUserProvider.notifier).state = user;

      state = const AuthState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Registration action handler.
  Future<bool> signUp(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Update global current user cache
      _ref.read(currentUserProvider.notifier).state = user;

      state = const AuthState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Google Sign-In action handler.
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repository.signInWithGoogle();
      _ref.read(currentUserProvider.notifier).state = user;
      state = const AuthState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Phone number OTP code verification request.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
  }) async {
    state = state.copyWith(isLoading: true);
    await _repository.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        state = const AuthState();
        onCodeSent(verificationId);
      },
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
      },
    );
  }

  /// Phone number OTP verification code authentication.
  Future<bool> signInWithPhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repository.signInWithPhoneNumber(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      _ref.read(currentUserProvider.notifier).state = user;
      state = const AuthState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Sign out current session action.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.signOut();
      _ref.read(currentUserProvider.notifier).state = null;
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

/// Provider exposing our reactive AuthController.
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final repository = ref.watch(authRepositoryProvider);
    return AuthController(repository: repository, ref: ref);
  },
);
