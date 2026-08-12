// ─── leagues_screen.dart ───────────────────────────────────────
// lib/features/leagues/view/leagues_screen.dart
//
// Stub — replace with real implementation when building Leagues feature.
// ══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:football_space/config/app_colors.dart';

class LeaguesScreen extends StatelessWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: const Row(
                children: [
                  Text('LEAGUES',
                      style: TextStyle(
                          fontFamily: 'Barlow Condensed',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events, size: 64, color: AppColors.border),
                    SizedBox(height: 16),
                    Text('Leagues Coming Soon',
                        style: TextStyle(
                            fontFamily: 'Barlow Condensed',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary)),
                    SizedBox(height: 8),
                    Text('Browse all leagues and tournaments',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
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