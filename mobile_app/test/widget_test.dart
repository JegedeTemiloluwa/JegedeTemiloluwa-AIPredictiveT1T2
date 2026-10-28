// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diaguard_ai/main.dart';
import 'package:diaguard_ai/services/api_service.dart';
import 'package:diaguard_ai/services/storage_service.dart';
import 'package:diaguard_ai/services/auth_service.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = StorageService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>(create: (_) => ApiService()),
          Provider<StorageService>(create: (_) => storageService),
          Provider<AuthService>(create: (_) => AuthService(storageService)),
        ],
        child: const DiaGuardApp(),
      ),
    );

    // Verify that it pumps without error
    expect(find.byType(MaterialApp), findsOneWidget);

    // Advance time past the splash delay and let animations settle
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
