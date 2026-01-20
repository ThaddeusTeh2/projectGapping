// FirebaseAuth-backed AuthRepository implementation.

import 'package:firebase_auth/firebase_auth.dart';

import '../repositories/auth_repository.dart';

class FirestoreAuthRepository implements AuthRepository {
  FirestoreAuthRepository({required FirebaseAuth auth}) : _auth = auth;

  final FirebaseAuth _auth;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? currentUser() => _auth.currentUser;

  @override
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
