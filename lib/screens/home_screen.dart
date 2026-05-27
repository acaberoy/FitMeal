import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/user_provider.dart';
import 'workout_detail_screen.dart';
import 'chatbot_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Reset to home tab every time HomeScreen is created
    _selectedIndex = 0;
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Log Out', style: TextStyle(color: AppTheme.textPrimaryColor)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: AppTheme.textSecondaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showAchievementDialog(BuildContext context, List<String> achievements) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withOpacity(0.1),
              ),
              child: const Icon(Icons.emoji_events, color: Colors.amber, size: 56),
            ),
            const SizedBox(height: 16),
            const Text('Achievement Unlocked!', style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...achievements.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(a, style: const TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 8),
            const Text('Keep going! You\'re doing amazing!', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Awesome!', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _checkAchievements(BuildContext context, UserProvider userProvider) {
    final newAchievements = userProvider.checkAndAwardAchievements();
    if (newAchievements.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showAchievementDialog(context, newAchievements);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            return _buildBody(userProvider);
          },
        ),
      ),
      floatingActionButton: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isPremium) {
            return FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen()));
              },
              backgroundColor: AppTheme.accentColor,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('AI Coach', style: TextStyle(fontWeight: FontWeight.bold)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.cardColor,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Meals'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_gymnastics), label: 'Workout'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
        ],
      ),
    );
  }

  Widget _buildBody(UserProvider userProvider) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab(userProvider);
      case 1:
        return _buildMealsTab(userProvider);
      case 2:
        return _buildWorkoutTab(userProvider);
      case 3:
        return _buildProgressTab(userProvider);
      default:
        return _buildHomeTab(userProvider);
    }
  }

  Widget _buildProgressTab(UserProvider userProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            child: Text(
              'Your Progress',
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          const SizedBox(height: 16),
          // View Full Report button
          FadeInUp(
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                },
                icon: const Icon(Icons.analytics, color: AppTheme.accentColor),
                label: const Text('View Full Report & Analytics', style: TextStyle(color: AppTheme.accentColor)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.accentColor), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildProgressCard(context, userProvider),
          const SizedBox(height: 32),
          Text('Today\'s Completed Meals', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (userProvider.completedMeals.isEmpty)
            const Text('No meals completed yet today.', style: TextStyle(color: AppTheme.textSecondaryColor))
          else
            ...userProvider.completedMeals.map((meal) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(meal['name'] ?? '', style: const TextStyle(color: AppTheme.textPrimaryColor))),
                      Text(meal['calories'] ?? '', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 32),
          Text('Completed Workouts', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (userProvider.completedWorkouts.isEmpty)
            const Text('No workouts completed yet.', style: TextStyle(color: AppTheme.textSecondaryColor))
          else
            ...userProvider.completedWorkouts.map((workout) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(workout['name'] ?? '', style: const TextStyle(color: AppTheme.textPrimaryColor))),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMealsTab(UserProvider userProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: userProvider.meals.length,
      itemBuilder: (context, index) {
        final meal = userProvider.meals[index];
        IconData icon = Icons.restaurant;
        if (meal['type'] == 'Breakfast') icon = Icons.breakfast_dining;
        if (meal['type'] == 'Lunch') icon = Icons.lunch_dining;
        if (meal['type'] == 'Dinner') icon = Icons.dinner_dining;
        final isCompleted = userProvider.completedMeals.any((m) => m['name'] == meal['name']);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMealCard(meal['type']!, meal['name']!, meal['calories']!, icon, macros: meal['macros'], benefit: meal['benefit'], isCompleted: isCompleted, onComplete: () {
            if (!isCompleted) {
              userProvider.completeMeal(meal);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${meal['name']} marked as completed!')));
              _checkAchievements(context, userProvider);
            }
          }),
        );
      },
    );
  }

  Widget _buildWorkoutTab(UserProvider userProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: userProvider.workouts.length,
      itemBuilder: (context, index) {
        final workout = userProvider.workouts[index];
        final isCompleted = userProvider.completedWorkouts.any((w) => w['name'] == workout['name']);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildWorkoutCard(workout, Icons.fitness_center, isCompleted: isCompleted, onComplete: () {
            if (!isCompleted) {
              userProvider.completeWorkout(workout);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${workout['name']} marked as completed!')));
              _checkAchievements(context, userProvider);
            }
          }),
        );
      },
    );
  }

  Widget _buildHomeTab(UserProvider userProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FadeInLeft(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${userProvider.name}!',
                        style: Theme.of(context).textTheme.displayMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'Your ${userProvider.primaryGoal} plan is ready.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
              FadeInRight(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      },
                      child: const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.cardColor,
                        child: Icon(Icons.person, color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showLogoutDialog(context),
                      child: const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.cardColor,
                        child: Icon(Icons.logout, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: _buildProgressCard(context, userProvider),
          ),
          const SizedBox(height: 32),
          if (userProvider.aiAdvice.isNotEmpty)
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: userProvider.isPremium ? AppTheme.accentColor.withOpacity(0.1) : AppTheme.cardColor,
                  border: userProvider.isPremium ? Border.all(color: AppTheme.accentColor, width: 1) : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(userProvider.isPremium ? Icons.diamond : Icons.info_outline, 
                             color: userProvider.isPremium ? AppTheme.accentColor : AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(userProvider.isPremium ? 'Premium AI Analysis' : 'Basic AI Analysis',
                             style: TextStyle(color: userProvider.isPremium ? AppTheme.accentColor : AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userProvider.aiAdvice,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                    if (!userProvider.isPremium) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentColor,
                            side: const BorderSide(color: AppTheme.accentColor),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/premium');
                          },
                          child: const Text('Upgrade to PRO for Advanced AI'),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: Text(
              'Your Daily Meal Plan',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          if (userProvider.meals.isNotEmpty)
            ...userProvider.meals.map((meal) {
              IconData icon = Icons.restaurant;
              if (meal['type'] == 'Breakfast') icon = Icons.breakfast_dining;
              if (meal['type'] == 'Lunch') icon = Icons.lunch_dining;
              if (meal['type'] == 'Dinner') icon = Icons.dinner_dining;
              final isCompleted = userProvider.completedMeals.any((m) => m['name'] == meal['name']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: _buildMealCard(meal['type']!, meal['name']!, meal['calories']!, icon, macros: meal['macros'], benefit: meal['benefit'], isCompleted: isCompleted, onComplete: () {
                    if (!isCompleted) {
                      userProvider.completeMeal(meal);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${meal['name']} marked as completed!')));
                      _checkAchievements(context, userProvider);
                    }
                  }),
                ),
              );
            }),
          const SizedBox(height: 32),
          FadeInUp(
            delay: const Duration(milliseconds: 700),
            child: Text(
              'Workout Plan',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          if (userProvider.workouts.isNotEmpty) 
            Builder(
              builder: (context) {
                final workout = userProvider.workouts.first;
                final isCompleted = userProvider.completedWorkouts.any((w) => w['name'] == workout['name']);
                return FadeInUp(
                  delay: const Duration(milliseconds: 800),
                  child: _buildWorkoutCard(
                      workout, Icons.fitness_center, isCompleted: isCompleted, onComplete: () {
                        if (!isCompleted) {
                          userProvider.completeWorkout(workout);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${workout['name']} marked as completed!')));
                          _checkAchievements(context, userProvider);
                        }
                      }),
                );
              }
            ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, UserProvider userProvider) {
    int totalWorkouts = 5;
    double progress = userProvider.workoutsCompleted / totalWorkouts;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Goal Progress',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.stars, color: AppTheme.accentColor),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Calories', '1,200', ' / 2,000'),
              _buildStatItem('Workouts', '${userProvider.workoutsCompleted}', ' / $totalWorkouts days'),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppTheme.backgroundColor,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(color: AppTheme.textPrimaryColor, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: total,
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(String type, String name, String calories, IconData icon, {String? macros, String? benefit, bool isCompleted = false, VoidCallback? onComplete}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? AppTheme.cardColor.withOpacity(0.5) : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: macros != null ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.grey.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isCompleted ? Colors.grey : AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                const SizedBox(height: 4),
                Text(name, style: TextStyle(color: isCompleted ? AppTheme.textSecondaryColor : AppTheme.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold, decoration: isCompleted ? TextDecoration.lineThrough : null)),
                if (macros != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.grey.withOpacity(0.1) : AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(macros, style: TextStyle(color: isCompleted ? Colors.grey : AppTheme.accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
                if (benefit != null) ...[
                  const SizedBox(height: 6),
                  Text(benefit, style: TextStyle(color: isCompleted ? Colors.grey : AppTheme.primaryColor.withOpacity(0.8), fontSize: 12, fontStyle: FontStyle.italic)),
                ]
              ],
            ),
          ),
          if (isCompleted)
            const Icon(Icons.check_circle, color: AppTheme.primaryColor)
          else
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: AppTheme.textSecondaryColor),
              onPressed: onComplete,
            ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Map<String, String> workout, IconData icon, {bool isCompleted = false, VoidCallback? onComplete}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: workout))).then((_) {
          setState(() {}); // refresh if marked complete in detail screen
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted ? AppTheme.cardColor.withOpacity(0.5) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.grey.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isCompleted ? Colors.grey : AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workout['name'] ?? '', style: TextStyle(color: isCompleted ? AppTheme.textSecondaryColor : AppTheme.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold, decoration: isCompleted ? TextDecoration.lineThrough : null)),
                  const SizedBox(height: 4),
                  Text(workout['details'] ?? '', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                ],
              ),
            ),
            if (isCompleted)
              const Icon(Icons.check_circle, color: AppTheme.primaryColor)
            else
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: AppTheme.textSecondaryColor),
                onPressed: onComplete,
              ),
          ],
        ),
      ),
    );
  }
}
