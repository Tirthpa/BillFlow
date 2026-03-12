import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../models/business_model.dart';

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final businessProfileProvider = StreamProvider<BusinessModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists ? BusinessModel.fromMap(doc.data()!) : null);
    },
    loading: () => const Stream.empty(),
    error: (e, st) => Stream.error(e, st),
  );
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUp({
    required String email,
    required String password,
    required String businessName,
    required String phone,
    required String address,
    required String gstNumber,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw 'Auth Timeout: Firebase is taking too long to respond.';
            },
          );

      BusinessModel business = BusinessModel(
        uid: userCredential.user!.uid,
        businessName: businessName,
        email: email,
        phone: phone,
        address: address,
        gstNumber: gstNumber,
      );

      await _firestore
          .collection('users')
          .doc(business.uid)
          .set(business.toMap())
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw 'Database Timeout: Account created, but profile could not be saved. Check if Firestore is enabled.';
            },
          );
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      if (e.code == 'network-request-failed' || e.code == 'unknown') {
        throw 'Connection Error: If you are on Web, your App ID in firebase_options.dart must be correct.';
      }
      throw 'Auth Error (${e.code}): ${e.message ?? 'Unknown error'}';
    } catch (e, stack) {
      debugPrint('General Error during signup: $e');
      debugPrint('Stack trace: $stack');
      throw 'System Error: $e';
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw 'Login Timeout: Check your internet connection.';
            },
          );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed' || e.code == 'unknown') {
        throw 'Network/Config Error: Please check your internet and if YOUR-API-KEY in firebase_options.dart is correct.';
      }
      throw e.message ?? 'Login failed (${e.code})';
    } catch (e) {
      throw 'Safety Error: $e';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<BusinessModel?> getCurrentBusiness() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return BusinessModel.fromMap(doc.data()!);
      }
    }
    return null;
  }

  Future<void> updateBusiness(BusinessModel business) async {
    await _firestore
        .collection('users')
        .doc(business.uid)
        .set(business.toMap(), SetOptions(merge: true));
  }
}
