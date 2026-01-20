// Auth repository interface.
// Responsibility: auth API contract (login/register/signout + auth state).

import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  User? currentUser();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  });
  Future<UserCredential> register({
    required String email,
    required String password,
  });
  Future<void> signOut();
}
