import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// CENTRAL COLOR SYSTEM — Single source of truth for all colors.
/// Change any color here and it reflects across the entire app.
/// ═══════════════════════════════════════════════════════════════
class AppColors {
  AppColors._(); // Prevent instantiation

  // ─── Backgrounds ───
  static const white = Color(0xFFF0F4F8);
  static const bg = Color(0xFF0A0E17);
  static const surface = Color(0xFF111827);
  static const surface2 = Color(0xFF1A2332);

  // ─── Borders ───
  static const border = Color(0xFF1E293B);
  static const border2 = Color(0xFF2A3544);

  // ─── Accent ───
  static const accent = Color(0xFF00D4FF);
  static const accentDark = Color(0xFF0099CC);

  // ─── Live ───
  static const live = Color(0xFFFF3D5A);

  // ─── Gold ───
  static const gold = Color(0xFFF5C842);

  // ─── Text ───
  static const textPrimary = Color(0xFFF0F4F8);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);
  static const textMuted2 = Color(0xFF4A5F75);

  // ─── Status Colors ───
  static const green = Color(0xFF00C875);
  static const yellow = Color(0xFFEAB308);
  static const purple = Color(0xFF8B5CF6);

  // ─── Gradients ───
  static const heroGradientStart = Color(0xFF0D1F3C);
  static const heroGradientMid = Color(0xFF0A2040);
  static const heroGradientEnd = Color(0xFF061428);

  // ─── Score Box ───
  static const scoreBoxBg = Color(0xFF0D1F3C);

  // ─── Pitch (Lineup) ───
  static const pitchGreen1 = Color(0xFF0A2A14);
  static const pitchGreen2 = Color(0xFF0D3018);

  // ─── Stat Bar Colors ───
  static const statHomeBar = accent;
  static const statAwayBar = Color(0xFFFF6B6B);
  static const statHomeBg = Color(0xFF0D2F3D);
  static const statAwayBg = Color(0xFF1A1A2E);
}