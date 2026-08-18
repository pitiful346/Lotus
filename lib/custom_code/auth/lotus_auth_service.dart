import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '/backend/backend.dart';

abstract interface class LotusAuthService {
  Future<void> signIn({required String email, required String password});

  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();

  Future<void> deleteAccount({required String password});
}

final class FirebaseLotusAuthService implements LotusAuthService {
  FirebaseLotusAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  bool _persistencePrepared = false;

  Future<void> _preparePersistence() async {
    if (_persistencePrepared || !kIsWeb) return;
    await _auth.setPersistence(Persistence.LOCAL);
    _persistencePrepared = true;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _preparePersistence();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw LotusAuthFailure(_messageFor(error));
    }
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _preparePersistence();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const LotusAuthFailure('Não foi possível criar a conta.');
      }
      await user.updateDisplayName(name.trim());
      await user.reload();
      await maybeCreateUser(_auth.currentUser ?? user);
    } on FirebaseAuthException catch (error) {
      throw LotusAuthFailure(_messageFor(error));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw LotusAuthFailure(_messageFor(error));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw const LotusAuthFailure('A sessão expirou. Volta a entrar.');
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await user.delete();
    } on FirebaseAuthException catch (error) {
      throw LotusAuthFailure(_messageFor(error));
    }
  }
}

@immutable
final class LotusAuthFailure implements Exception {
  const LotusAuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

String _messageFor(FirebaseAuthException error) => switch (error.code) {
  'invalid-email' => 'Confirma o endereço de email.',
  'user-disabled' => 'Esta conta está desativada.',
  'user-not-found' ||
  'wrong-password' ||
  'invalid-credential' ||
  'INVALID_LOGIN_CREDENTIALS' => 'Email ou palavra-passe incorretos.',
  'email-already-in-use' => 'Já existe uma conta com este email.',
  'weak-password' => 'Escolhe uma palavra-passe com pelo menos 6 caracteres.',
  'too-many-requests' =>
    'Demasiadas tentativas. Aguarda um pouco e tenta novamente.',
  'network-request-failed' =>
    'Sem ligação. Verifica a internet e tenta novamente.',
  'requires-recent-login' =>
    'Por segurança, termina sessão, volta a entrar e tenta novamente.',
  _ => 'Não foi possível concluir a autenticação.',
};
