// lib/features/profile/view/profile_screen.dart
//
// Profile / Auth feature is temporarily disabled — only Live Score
// features are active right now. This screen keeps the same class
// name (ProfileScreen) so AppShell doesn't need to change, but shows
// a "Coming Soon" placeholder instead of the real profile/auth UI.
// ══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:football_live_score/shared/widgets/coming_soon_view.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonView(
      topBarTitle: 'PROFILE',
      icon: Icons.person_rounded,
      title: 'Profile Coming Soon',
      subtitle: 'Account, sign-in & settings are on the way',
    );
  }
}
