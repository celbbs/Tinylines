import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiny_lines/auth/sign_in_screen.dart';
import 'package:tiny_lines/services/auth_service.dart';

/// Fake success auth service
class FakeAuthServiceSuccess implements AuthService {
  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> createAccount({
    required String email,
    required String password,
  }) async {}
}

/// Fake failure auth service
class FakeAuthServiceFailure implements AuthService {
  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    throw Exception('Invalid credentials');
  }

  @override
  Future<void> createAccount({
    required String email,
    required String password,
  }) async {
    throw Exception('Account creation failed');
  }
}

void main() {
  group('TinyLines SignInScreen widget tests', () {
    testWidgets('SignInScreen renders title and auth fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TinyLines'), findsOneWidget);
      expect(find.byKey(const Key('auth_email_field')), findsOneWidget);
      expect(find.byKey(const Key('auth_password_field')), findsOneWidget);
      expect(find.byKey(const Key('auth_sign_in_button')), findsOneWidget);
    });

    testWidgets('User can type email/password',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('auth_email_field')),
        'test@example.com',
      );

      await tester.enterText(
        find.byKey(const Key('auth_password_field')),
        'password123',
      );

      await tester.pumpAndSettle();

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('Submitting empty fields shows validation error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('auth_sign_in_button')));
      await tester.pumpAndSettle();

      expect(find.text('Email and password are required.'),
          findsOneWidget);
    });

    testWidgets('User can toggle between sign in and create account',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Need an account? Sign up'), findsOneWidget);

      await tester.tap(find.text('Need an account? Sign up'));
      await tester.pumpAndSettle();

      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Already have an account? Sign in'),
          findsOneWidget);

      await tester.tap(find.text('Already have an account? Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('Successful authentication does NOT show error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SignInScreen(
            authService: FakeAuthServiceSuccess(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('auth_email_field')),
          'test@example.com');
      await tester.enterText(
          find.byKey(const Key('auth_password_field')),
          'password123');

      await tester.tap(find.byKey(const Key('auth_sign_in_button')));
      await tester.pumpAndSettle();

      expect(find.text('Authentication failed.'), findsNothing);
    });

    testWidgets('Failed authentication shows error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SignInScreen(
            authService: FakeAuthServiceFailure(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('auth_email_field')),
          'test@example.com');
      await tester.enterText(
          find.byKey(const Key('auth_password_field')),
          'wrongpass');

      await tester.tap(find.byKey(const Key('auth_sign_in_button')));
      await tester.pumpAndSettle();

      expect(find.text('Authentication failed.'),
          findsOneWidget);
    });
  });
}
