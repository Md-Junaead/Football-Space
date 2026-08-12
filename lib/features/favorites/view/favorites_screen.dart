// lib/features/favorites/view/favorites_screen.dart
//
// Stub — replace with real implementation when building Favorites feature.
// ══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:football_space/config/app_colors.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top Bar ───
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: const Row(
                children: [
                  Text(
                    'FAVORITES',
                    style: TextStyle(
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
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, size: 64, color: AppColors.border),
                    SizedBox(height: 16),
                    Text(
                      'Favorites Coming Soon',
                      style: TextStyle(
                        fontFamily: 'Barlow Condensed',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Save your favourite teams & matches here',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
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