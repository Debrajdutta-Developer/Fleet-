import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../../core/services/local_storage_service.dart';
import '../data/company_repository_impl.dart';
import '../domain/company_repository.dart';

/// Provider for accessing the CompanyRepository.
final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepositoryImpl(
    localStorage: ref.watch(localStorageServiceProvider),
  );
});

/// State structure for Company Setup operations.
class CompanySetupState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const CompanySetupState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  CompanySetupState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return CompanySetupState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Controller overseeing Company Setup UI actions.
class CompanySetupController extends StateNotifier<CompanySetupState> {
  final CompanyRepository _repository;
  final Ref _ref;

  CompanySetupController({
    required CompanyRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const CompanySetupState());

  /// Triggers company profile registration inside Firestore
  Future<bool> registerCompany({
    required String name,
    required String ownerName,
    String? gstNumber,
    String? panNumber,
    required String phone,
    required String email,
    required String address,
    required String defaultCurrency,
    required String timeZone,
    File? logoFile,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception(
          'User authentication context is missing. Log in again.',
        );
      }

      // 1. Create company record
      final company = await _repository.createCompany(
        name: name,
        ownerName: ownerName,
        ownerUid: currentUser.uid,
        gstNumber: gstNumber,
        panNumber: panNumber,
        phone: phone,
        email: email,
        address: address,
        defaultCurrency: defaultCurrency,
        timeZone: timeZone,
        logoFile: logoFile,
      );

      // 2. Associate the company ID back to the user document inside Firestore (users/{userId})
      final authRepo = _ref.read(authRepositoryProvider);
      await authRepo.updateUserCompanyAssociation(currentUser.uid, company.id);

      // 3. Force refresh current user cache
      final updatedUser = currentUser.copyWith(companyId: company.id);
      _ref.read(currentUserProvider.notifier).state = updatedUser;

      state = const CompanySetupState(isCompleted: true);
      return true;
    } catch (e) {
      state = CompanySetupState(errorMessage: e.toString());
      return false;
    }
  }
}

/// Provider exposing our reactive CompanySetupController.
final companySetupControllerProvider =
    StateNotifierProvider<CompanySetupController, CompanySetupState>((ref) {
  final repository = ref.watch(companyRepositoryProvider);
  return CompanySetupController(repository: repository, ref: ref);
});
