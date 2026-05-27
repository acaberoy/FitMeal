import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Map<String, Map<String, dynamic>> achievementInfo = {
    'first_meal': {'icon': Icons.restaurant, 'label': 'First Meal Logged', 'color': Colors.orange},
    'first_workout': {'icon': Icons.fitness_center, 'label': 'First Workout Done', 'color': Colors.blue},
    'nutrition_champion': {'icon': Icons.emoji_events, 'label': 'Daily Nutrition Champion', 'color': Colors.amber},
    'workout_warrior': {'icon': Icons.local_fire_department, 'label': 'Workout Warrior', 'color': Colors.redAccent},
    'premium_member': {'icon': Icons.diamond, 'label': 'Premium Member', 'color': Colors.purpleAccent},
    'profile_complete': {'icon': Icons.star, 'label': 'Profile Complete', 'color': Colors.tealAccent},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
            onPressed: () => Navigator.pushNamed(context, '/profile-setup'),
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, user, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar & Name
                FadeInDown(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.accentColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(user.name, style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.isPremium ? AppTheme.accentColor.withOpacity(0.2) : AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: user.isPremium ? Border.all(color: AppTheme.accentColor, width: 1) : null,
                        ),
                        child: Text(
                          user.isPremium ? '${user.subscriptionPlan.toUpperCase()} Member' : 'Free Plan',
                          style: TextStyle(
                            color: user.isPremium ? AppTheme.accentColor : AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Info Cards
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Row(
                    children: [
                      Expanded(child: _buildInfoCard('Age', '${user.age}', Icons.calendar_today)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoCard('Weight', '${user.weight} kg', Icons.monitor_weight)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoCard('Height', '${user.height} cm', Icons.height)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _buildDetailCard('Fitness Goal', user.primaryGoal, Icons.flag, AppTheme.primaryColor),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: _buildDetailCard(
                    'Dietary Restrictions',
                    user.dietaryRestrictions.isNotEmpty ? user.dietaryRestrictions : 'None specified',
                    Icons.restaurant_menu,
                    Colors.orangeAccent,
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: _buildDetailCard(
                    'Subscription Plan',
                    user.subscriptionPlan.toUpperCase(),
                    user.isPremium ? Icons.diamond : Icons.card_membership,
                    user.isPremium ? AppTheme.accentColor : AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 32),

                // Achievements Section
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text('Achievements', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${user.achievements.length} / ${achievementInfo.length}', style: const TextStyle(color: AppTheme.textSecondaryColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                    children: achievementInfo.entries.map((entry) {
                      final isEarned = user.achievements.contains(entry.key);
                      final info = entry.value;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isEarned ? (info['color'] as Color).withOpacity(0.1) : AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: isEarned ? Border.all(color: (info['color'] as Color).withOpacity(0.5)) : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              info['icon'] as IconData,
                              size: 32,
                              color: isEarned ? info['color'] as Color : AppTheme.textSecondaryColor.withOpacity(0.3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              info['label'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
                                color: isEarned ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),

                // Quick Stats
                FadeInUp(
                  delay: const Duration(milliseconds: 800),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickStat('Meals Done', '${user.completedMeals.length}', Icons.restaurant),
                        Container(width: 1, height: 40, color: AppTheme.backgroundColor),
                        _buildQuickStat('Workouts', '${user.completedWorkouts.length}', Icons.fitness_center),
                        Container(width: 1, height: 40, color: AppTheme.backgroundColor),
                        _buildQuickStat('Streak', '${user.workoutsCompleted}/5', Icons.local_fire_department),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Edit Profile Button
                FadeInUp(
                  delay: const Duration(milliseconds: 900),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/profile-setup'),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: AppTheme.textPrimaryColor, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: AppTheme.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: AppTheme.textPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11)),
      ],
    );
  }
}
