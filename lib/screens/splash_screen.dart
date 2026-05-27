import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/onboarding');
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              const Color(0xFF0A1022),
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // Glowing icon with animated ring
            ZoomIn(
              duration: const Duration(milliseconds: 800),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final double glowOpacity =
                      0.15 + (_pulseController.value * 0.2);
                  final double ringScale =
                      1.0 + (_pulseController.value * 0.08);
                  return Transform.scale(
                    scale: ringScale,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(glowOpacity),
                            AppTheme.accentColor.withOpacity(glowOpacity * 0.3),
                            Colors.transparent,
                          ],
                          stops: const [0.3, 0.7, 1.0],
                          radius: 1.2,
                        ),
                        border: Border.all(
                          color:
                              AppTheme.primaryColor.withOpacity(glowOpacity + 0.1),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.primaryColor.withOpacity(glowOpacity * 0.8),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color:
                                AppTheme.accentColor.withOpacity(glowOpacity * 0.4),
                            blurRadius: 60,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
            // App name with gradient
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              duration: const Duration(milliseconds: 600),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    Color(0xFF5FFFCF),
                    AppTheme.accentColor,
                  ],
                ).createShader(bounds),
                child: const Text(
                  'FitMeal',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Tagline
            FadeInUp(
              delay: const Duration(milliseconds: 700),
              duration: const Duration(milliseconds: 600),
              child: Text(
                'Personalized Meal & Fitness Planning',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor.withOpacity(0.8),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const Spacer(flex: 2),
            // Loading indicator
            FadeIn(
              delay: const Duration(milliseconds: 1000),
              child: SizedBox(
                width: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    backgroundColor:
                        AppTheme.primaryColor.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                    minHeight: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeIn(
              delay: const Duration(milliseconds: 1200),
              child: Text(
                'Loading your journey...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor.withOpacity(0.5),
                  letterSpacing: 1,
                ),
              ),
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
