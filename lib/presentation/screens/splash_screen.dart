import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.medication,
                size: 100,
                color: Colors.white,
              ).animate()
                .fade(duration: 500.ms)
                .scale(delay: 300.ms, duration: 500.ms),
              const SizedBox(height: 24),
              Text(
                'Dosifi',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ).animate()
                .fade(delay: 500.ms, duration: 500.ms)
                .slideY(begin: 0.3, end: 0, delay: 500.ms, duration: 500.ms),
              const SizedBox(height: 8),
              Text(
                'Your Personal Medication Manager',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
              ).animate()
                .fade(delay: 800.ms, duration: 500.ms),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ).animate()
                .fade(delay: 1.s, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
