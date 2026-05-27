import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../theme.dart';

class AIGenerationScreen extends StatefulWidget {
  const AIGenerationScreen({super.key});

  @override
  State<AIGenerationScreen> createState() => _AIGenerationScreenState();
}

class _AIGenerationScreenState extends State<AIGenerationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentStep = 0;
  final List<String> _loadingSteps = [
    'Analyzing your body profile...',
    'Evaluating dietary restrictions...',
    'Generating custom meal plan...',
    'Designing workout routine...',
    'Finalizing AI health plan...'
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _simulateAIGeneration();
  }

  void _simulateAIGeneration() async {
    for (int i = 0; i < _loadingSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          _currentStep = i;
        });
      }
    }
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                child: RotationTransition(
                  turns: _controller,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              FadeInUp(
                key: ValueKey<int>(_currentStep),
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _loadingSteps[_currentStep],
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 22,
                        color: AppTheme.textPrimaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: LinearProgressIndicator(
                  backgroundColor: AppTheme.cardColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                  borderRadius: BorderRadius.circular(8),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Powered by FitMeal',
                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
              )
            ],
          ),
        ),
      ),
    );
  }
}
