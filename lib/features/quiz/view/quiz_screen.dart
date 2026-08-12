// lib/features/quiz/view/quiz_home_screen.dart
//
// Quiz feature is temporarily disabled — only Live Score features are
// active right now. This screen keeps the same tab slot / class name
// (QuizHomeScreen) so AppShell and AppRouter don't need to change,
// but shows a "Coming Soon" placeholder instead of the real quiz UI.
// ══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:football_live_score/shared/widgets/coming_soon_view.dart';

class QuizHomeScreen extends StatelessWidget {
  const QuizHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonView(
      topBarTitle: 'QUIZ',
      icon: Icons.quiz_rounded,
      title: 'Quiz Coming Soon',
      subtitle: 'Test your football knowledge here very soon',
    );
  }
}
