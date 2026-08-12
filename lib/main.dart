// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_live_score/config/app_colors.dart';
import 'package:football_live_score/core/routes/app_router.dart';
import 'package:football_live_score/core/routes/app_routes.dart';
import 'package:football_live_score/features/home/cubit/home_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => HomeCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'Football Live Score',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        initialRoute: AppRoutes.shell,
        onGenerateRoute: AppRouter.onGenerateRoute,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Barlow',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.live,
        surface: AppColors.surface,
        background: AppColors.bg,
      ),
      textTheme: const TextTheme(bodyMedium: TextStyle(color: AppColors.textPrimary)),
      useMaterial3: true,
    );
  }
}

// flutter build apk --build-name=1.0 --build-number=1
// flutter build apk --release
// flutter build appbundle --release
