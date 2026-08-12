import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_space/config/app_colors.dart';
import 'package:football_space/core/routes/app_routes.dart';
import 'package:football_space/features/match_detail/cubit/match_detail_cubit.dart';
import 'package:football_space/features/match_detail/view/match_detail_screen.dart';
import 'package:football_space/shared/shell/app_shell.dart';
import 'package:football_space/models/fixture_model.dart';

// ═══════════════════════════════════════════════════════════════
// APP ROUTER — Single place where every route is defined.
//
// How it works:
//   MaterialApp(onGenerateRoute: AppRouter.onGenerateRoute)
//
// Push a named route:
//   Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: fixture)
//
// Never use Navigator.push(MaterialPageRoute(...)) directly in widgets.
//
// NOTE: Only Live Score related routes (shell, matchDetail) are wired
// up right now — other features are temporarily disabled.
// ═══════════════════════════════════════════════════════════════

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    debugPrint('[AppRouter] Navigating to: ${settings.name}');

    switch (settings.name) {

      // ─── Shell (Bottom Nav Host) ───────────────────────────────
      case AppRoutes.shell:
        return _buildRoute(settings, const AppShell());

      // ─── Match Detail ──────────────────────────────────────────
      case AppRoutes.matchDetail:
        // Arguments: FixtureModel (required)
        final fixture = settings.arguments as FixtureModel?;
        if (fixture == null) {
          debugPrint('[AppRouter] ⚠️ matchDetail called without a FixtureModel argument!');
          return _buildErrorRoute(settings, 'Match data missing. Please go back and try again.');
        }
        return _buildRoute(
          settings,
          BlocProvider(
            create: (_) => MatchDetailCubit()..init(fixture),
            child: const MatchDetailScreen(),
          ),
        );

      // ─── Unknown route — graceful fallback ────────────────────
      default:
        debugPrint('[AppRouter] ⚠️ Unknown route: ${settings.name}');
        return _buildErrorRoute(settings, 'Page not found: ${settings.name}');
    }
  }

  // ─── Route Builders ───────────────────────────────────────────

  /// Standard slide-up page transition.
  static MaterialPageRoute<T> _buildRoute<T>(RouteSettings settings, Widget page) {
    return MaterialPageRoute<T>(
      settings: settings,
      builder: (_) => page,
    );
  }

  /// Graceful error page — never crash, always show readable error.
  static MaterialPageRoute<void> _buildErrorRoute(RouteSettings settings, String message) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => _ErrorPage(message: message),
    );
  }
}

// ─── Error Page ───────────────────────────────────────────────
class _ErrorPage extends StatelessWidget {
  final String message;
  const _ErrorPage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: AppColors.live),
                const SizedBox(height: 16),
                const Text('Something went wrong',
                    style: TextStyle(
                        fontFamily: 'Barlow Condensed',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(message,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    textAlign: TextAlign.center),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.bg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
