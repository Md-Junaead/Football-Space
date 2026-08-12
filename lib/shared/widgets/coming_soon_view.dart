// lib/shared/widgets/coming_soon_view.dart
//
// Shared "Coming Soon" placeholder — used by any tab/feature that is
// temporarily disabled (Quiz, Profile, etc.) while keeping the same
// visual language (AppColors, Barlow Condensed headers) as the rest
// of the app. Pure UI, no logic, no network calls.
// ══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:football_space/config/app_colors.dart';

class ComingSoonView extends StatelessWidget {
  /// Title shown in the top bar (e.g. "QUIZ", "PROFILE").
  final String topBarTitle;

  /// Large icon shown above the message.
  final IconData icon;

  /// Bold headline (e.g. "Quiz Coming Soon").
  final String title;

  /// Small supporting line under the headline.
  final String subtitle;

  const ComingSoonView({
    super.key,
    required this.topBarTitle,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top Bar ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Text(
                    topBarTitle,
                    style: const TextStyle(
                      fontFamily: 'Barlow Condensed',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Body ───
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 64, color: AppColors.border),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Barlow Condensed',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
