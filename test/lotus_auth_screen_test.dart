import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/auth/lotus_account_actions.dart';
import 'package:lotus/custom_code/auth/lotus_auth_screen.dart';
import 'package:lotus/custom_code/auth/lotus_auth_service.dart';

void main() {
  testWidgets('login submits validated credentials', (tester) async {
    final service = _FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(home: LotusAuthScreen(service: service)),
    );

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'user@lotus.pt',
    );
    await tester.enterText(find.byKey(const Key('auth-password')), 'secret12');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pump();

    expect(service.signInEmail, 'user@lotus.pt');
    expect(service.signInPassword, 'secret12');
  });

  testWidgets('registration collects name, email and password', (tester) async {
    final service = _FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(home: LotusAuthScreen(service: service)),
    );

    await tester.tap(find.text('Criar conta').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('auth-name')), 'Ana Lotus');
    await tester.enterText(find.byKey(const Key('auth-email')), 'ana@lotus.pt');
    await tester.enterText(find.byKey(const Key('auth-password')), 'secret12');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pump();

    expect(service.registerName, 'Ana Lotus');
    expect(service.registerEmail, 'ana@lotus.pt');
  });

  testWidgets('password recovery uses the entered email', (tester) async {
    final service = _FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(home: LotusAuthScreen(service: service)),
    );

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'user@lotus.pt',
    );
    await tester.tap(find.text('Recuperar palavra-passe'));
    await tester.pump();

    expect(service.resetEmail, 'user@lotus.pt');
  });

  testWidgets('account action confirms logout', (tester) async {
    final service = _FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LotusAccountActions(service: service)),
      ),
    );

    await tester.tap(find.byKey(const Key('account-sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Terminar sessão'));
    await tester.pumpAndSettle();

    expect(service.signOutCalls, 1);
  });

  testWidgets('account deletion requires password confirmation', (
    tester,
  ) async {
    final service = _FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LotusAccountActions(service: service)),
      ),
    );

    await tester.tap(find.byKey(const Key('account-delete')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('delete-account-password')),
      'secret12',
    );
    await tester.tap(find.byKey(const Key('confirm-delete-account')));
    await tester.pumpAndSettle();

    expect(service.deletedWithPassword, 'secret12');
  });
}

final class _FakeAuthService implements LotusAuthService {
  String? signInEmail;
  String? signInPassword;
  String? registerName;
  String? registerEmail;
  String? resetEmail;
  int signOutCalls = 0;
  String? deletedWithPassword;

  @override
  Future<void> deleteAccount({required String password}) async {
    deletedWithPassword = password;
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    registerName = name;
    registerEmail = email;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetEmail = email;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInEmail = email;
    signInPassword = password;
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }
}
