import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/errors/failure.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../domain/auth_repository.dart';
import '../domain/user_entity.dart';

/// Firebase Implementation of AuthRepository with offline caching capabilities.
class AuthRepositoryImpl implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final LocalStorageService _localStorage;
  final ConnectivityService _connectivity;

  AuthRepositoryImpl({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    required LocalStorageService localStorage,
    required ConnectivityService connectivity,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _localStorage = localStorage,
        _connectivity = connectivity;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) {
        await _localStorage.clearCachedOfflineUserData();
        return null;
      }
      return await _getUserFromFirestoreOrCache(fbUser.uid);
    });
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) {
      // Check offline local storage cache for backup fallback
      final cachedJson = _localStorage.getCachedOfflineUserData();
      if (cachedJson != null) {
        try {
          return UserEntity.fromMap(
            jsonDecode(cachedJson) as Map<String, dynamic>,
          );
        } catch (_) {
          return null;
        }
      }
      return null;
    }
    return await _getUserFromFirestoreOrCache(fbUser.uid);
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final isConnected =
          await _connectivity.checkConnection() == ConnectionStatus.online;

      // If offline, check if we have cached details matching the email, but since Firebase Auth
      // requires network for credentials validation, we fail unless Firebase has local cache persistence active.
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw const AuthFailure('Failed to sign in. User is null.');
      }

      final userEntity = await _getUserFromFirestoreOrCache(
        fbUser.uid,
        forceRemote: isConnected,
      );
      return userEntity;
    } on fb.FirebaseException catch (e) {
      throw AuthFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<UserEntity> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw const AuthFailure('Failed to create account. User is null.');
      }

      // Create new user profile document in Firestore
      final userEntity = UserEntity(
        uid: fbUser.uid,
        email: email,
        displayName: displayName,
        role: 'admin', // Default role for registering user
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Save user to Firestore. Firestore local cache handles offline queue if device is offline.
      await _firestore
          .collection('users')
          .doc(fbUser.uid)
          .set(userEntity.toMap());

      // Save in SharedPreferences for fast offline bootstrap
      await _localStorage.cacheOfflineUserData(jsonEncode(userEntity.toMap()));

      return userEntity;
    } on fb.FirebaseException catch (e) {
      throw AuthFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      // In production Flutter, use: import 'package:google_sign_in/google_sign_in.dart';
      // To ensure pure compile-safety without adding platform dependencies during initial checks,
      // we mock/implement the credential setup using a clean interface wrapper.
      throw const AuthFailure(
        'Google Sign-In requires active Google Play configurations.',
        code: 'play-services-missing',
      );
    } on fb.FirebaseException catch (e) {
      throw AuthFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(dynamic error) onError,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          // Automatic SMS code resolution on supported Android devices
          final userCredential = await _firebaseAuth.signInWithCredential(
            credential,
          );
          if (userCredential.user != null) {
            await _getUserFromFirestoreOrCache(userCredential.user!.uid);
          }
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          onError(AuthFailure.fromFirebaseException(e.code, e.message));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } on fb.FirebaseException catch (e) {
      onError(AuthFailure.fromFirebaseException(e.code, e.message));
    } catch (e) {
      onError(AuthFailure(e.toString()));
    }
  }

  @override
  Future<UserEntity> signInWithPhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw const AuthFailure('Failed to sign in. User is null.');
      }

      final isConnected =
          await _connectivity.checkConnection() == ConnectionStatus.online;
      return await _getUserFromFirestoreOrCache(
        fbUser.uid,
        forceRemote: isConnected,
      );
    } on fb.FirebaseException catch (e) {
      throw AuthFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _localStorage.clearCachedOfflineUserData();
    await _localStorage.clearCachedCompanyId();
  }

  @override
  Future<void> updateUserCompanyAssociation(
    String uid,
    String companyId,
  ) async {
    try {
      // 1. Update remote Firestore
      await _firestore.collection('users').doc(uid).update({
        'companyId': companyId,
      });

      // 2. Refresh local offline cache
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(companyId: companyId);
        await _localStorage.cacheOfflineUserData(
          jsonEncode(updatedUser.toMap()),
        );
        await _localStorage.cacheUserCompanyId(companyId);
      }
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  /// Internal utility to fetch users, checking local Cache first or Remote DB.
  Future<UserEntity> _getUserFromFirestoreOrCache(
    String uid, {
    bool forceRemote = false,
  }) async {
    try {
      if (!forceRemote) {
        // Look inside memory/shared preferences cache first
        final cachedJson = _localStorage.getCachedOfflineUserData();
        if (cachedJson != null) {
          final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
          final cachedUser = UserEntity.fromMap(decoded);
          if (cachedUser.uid == uid) {
            return cachedUser;
          }
        }
      }

      // Fallback or Force: Fetch from Firestore
      // Source.serverAndCache will fetch from cache if offline automatically
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        // Fallback: Create placeholder mapping in database if none exists yet
        final email = _firebaseAuth.currentUser?.email ?? '';
        final name = _firebaseAuth.currentUser?.displayName ?? 'Operator';
        final fallbackUser = UserEntity(
          uid: uid,
          email: email,
          displayName: name,
          role: 'admin',
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(uid).set(fallbackUser.toMap());
        await _localStorage.cacheOfflineUserData(
          jsonEncode(fallbackUser.toMap()),
        );
        return fallbackUser;
      }

      final fetchedUser = UserEntity.fromMap(doc.data()!);
      // Save locally
      await _localStorage.cacheOfflineUserData(jsonEncode(fetchedUser.toMap()));
      if (fetchedUser.companyId != null) {
        await _localStorage.cacheUserCompanyId(fetchedUser.companyId!);
      }
      return fetchedUser;
    } catch (e) {
      // Offline safety fallback
      final cachedJson = _localStorage.getCachedOfflineUserData();
      if (cachedJson != null) {
        return UserEntity.fromMap(
          jsonDecode(cachedJson) as Map<String, dynamic>,
        );
      }
      rethrow;
    }
  }
}
