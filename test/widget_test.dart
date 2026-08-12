// test/widget_test.dart
//
// Basic smoke test — confirms the app boots and the bottom nav (with
// all 5 tabs) renders correctly.
//
// IMPORTANT: We only call `tester.pump()` once (NOT `pumpAndSettle()`).
// HomeCubit fires a real network call in its constructor — in CI we
// don't want the test waiting on (or depending on) a live network
// call, so we only check the very first frame (the loading state),
// which needs zero network access.
//
// Add more tests here later as the app grows — each test file goes
// under test/ and this workflow will pick it up automatically.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:football_space/features/home/cubit/home_cubit.dart';
import 'package:football_space/shared/shell/app_shell.dart';

void main() {
  testWidgets('AppShell renders bottom nav with all 5 tabs', (tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => HomeCubit()),
        ],
        child: const MaterialApp(
          home: AppShell(),
        ),
      ),
    );

    // Only pump one frame — do NOT wait for network calls to finish.
    await tester.pump();

    // Bottom nav labels should be visible immediately (static UI,
    // no network dependency).
    expect(find.text('Matches'), findsOneWidget);
    expect(find.text('Leagues'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Tapping a bottom nav tab switches screens', (tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => HomeCubit()),
        ],
        child: const MaterialApp(
          home: AppShell(),
        ),
      ),
    );
    await tester.pump();

    // Tap the "Quiz" tab — should show the Coming Soon screen.
    await tester.tap(find.text('Quiz'));
    await tester.pump();

    expect(find.text('Quiz Coming Soon'), findsOneWidget);
  });
}