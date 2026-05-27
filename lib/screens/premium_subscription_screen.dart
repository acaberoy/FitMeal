import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/user_provider.dart';

class PremiumSubscriptionScreen extends StatefulWidget {
  const PremiumSubscriptionScreen({super.key});

  @override
  State<PremiumSubscriptionScreen> createState() => _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends State<PremiumSubscriptionScreen> {
  String _selectedPlan = 'pro'; // default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            FadeInDown(
              child: const Icon(
                Icons.diamond,
                size: 80,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              child: Text(
                'Unlock FitMeal Premium',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.accentColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'Get the most advanced AI analysis, precise macro-nutrient tracking, and professional-grade workout routines tailored specifically to your body.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            _buildFeatureItem('Detailed Macro Breakdowns (Protein, Carbs, Fats)'),
            _buildFeatureItem('Advanced Professional AI Advice'),
            _buildFeatureItem('Targeted Workout Muscle Focus & Mechanics'),
            _buildFeatureItem('Unlimited Daily Plan Re-generations'),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 800),
              child: _buildPlanCard('basic', 'BASIC PLAN', '\$4.99', 'Better meal suggestions, calorie tracking'),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 900),
              child: _buildPlanCard('pro', 'PRO PLAN', '\$9.99', 'Full macros, advanced workouts, AI advice'),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 1000),
              child: _buildPlanCard('elite', 'ELITE PLAN', '\$14.99', 'Everything + recovery plans, snack plans, premium AI'),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 1100),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: () {
                    // Subscribe logic
                    Provider.of<UserProvider>(context, listen: false).subscribeToPlan(_selectedPlan);
                    Navigator.pop(context); // Go back home
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Welcome to ${_selectedPlan.toUpperCase()}! Your plans have been upgraded.'),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    );
                  },
                  child: const Text('Subscribe Now', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(String planId, String title, String price, String subtitle) {
    bool isSelected = _selectedPlan == planId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = planId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor.withOpacity(0.1) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.accentColor : AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor, letterSpacing: 1, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                ],
              ),
            ),
            Text(price, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return FadeInLeft(
      delay: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(text, style: const TextStyle(color: AppTheme.textPrimaryColor, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
