import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/user_provider.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Map<String, String> workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    // Split steps by newline for easy rendering
    final steps = workout['steps']?.split('\n') ?? ['Follow the standard protocol.'];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Routine Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Icon(Icons.fitness_center, size: 80, color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeInUp(
                child: Text(
                  workout['name'] ?? 'Workout',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
              const SizedBox(height: 8),
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: AppTheme.accentColor),
                    const SizedBox(width: 8),
                    Text(
                      workout['details'] ?? '',
                      style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (workout['focus'] != null) ...[
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'Focus: ${workout['focus']}',
                    style: const TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: const Text(
                  'Daily Steps to Follow',
                  style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              ...steps.asMap().entries.map((entry) {
                int idx = entry.key;
                String stepText = entry.value;
                return FadeInUp(
                  delay: Duration(milliseconds: 400 + (idx * 100)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            stepText,
                            style: const TextStyle(color: AppTheme.textPrimaryColor, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 48),
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    onPressed: () {
                      Provider.of<UserProvider>(context, listen: false).completeWorkout(workout);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Awesome job! Progress recorded.'),
                          backgroundColor: AppTheme.accentColor,
                        ),
                      );
                    },
                    child: const Text('Mark as Completed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
