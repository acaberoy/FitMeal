import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/user_provider.dart';

// ─── Manage Users Screen ───

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Manage Users'), backgroundColor: AppTheme.cardColor),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final users = userProvider.registeredUsers;
          if (users.isEmpty) {
            return const Center(child: Text('No users found.', style: TextStyle(color: Colors.white)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final plan = user['subscriptionPlan'] ?? 'free';
              final isPremium = plan != 'free';
              return FadeInUp(
                delay: Duration(milliseconds: index * 80),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isPremium ? AppTheme.accentColor : AppTheme.primaryColor,
                        child: Text(
                          (user['username'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['username'] ?? '', style: const TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPremium ? AppTheme.accentColor.withOpacity(0.2) : AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(plan.toUpperCase(), style: TextStyle(fontSize: 10, color: isPremium ? AppTheme.accentColor : AppTheme.textSecondaryColor, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Text('Goal: ${user['goal'] ?? 'N/A'}', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.dangerColor, size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppTheme.cardColor,
                              title: const Text('Delete User', style: TextStyle(color: AppTheme.textPrimaryColor)),
                              content: Text('Remove ${user['username']}?', style: const TextStyle(color: AppTheme.textSecondaryColor)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    userProvider.deleteUser(index);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Delete', style: TextStyle(color: AppTheme.dangerColor)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── User Activity Logs Screen ───

class UserActivityScreen extends StatelessWidget {
  const UserActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('User Activity Logs'),
        backgroundColor: AppTheme.cardColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: AppTheme.textSecondaryColor),
            tooltip: 'Clear Logs',
            onPressed: () {
              final provider = Provider.of<UserProvider>(context, listen: false);
              provider.globalActivityLog.clear();
              provider.notifyListeners();
            },
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final logs = userProvider.globalActivityLog;
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: AppTheme.textSecondaryColor.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('No activity logs yet', style: TextStyle(color: AppTheme.textSecondaryColor)),
                  const Text('User actions will appear here', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final timestamp = DateTime.tryParse(log['timestamp'] ?? '');
              final timeStr = timestamp != null
                  ? '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')} · ${timestamp.month}/${timestamp.day}/${timestamp.year}'
                  : 'Unknown';
              IconData icon = Icons.info_outline;
              Color iconColor = AppTheme.textSecondaryColor;
              final action = log['action'] ?? '';
              if (action.contains('meal')) {
                icon = Icons.restaurant;
                iconColor = Colors.orangeAccent;
              } else if (action.contains('workout')) {
                icon = Icons.fitness_center;
                iconColor = AppTheme.primaryColor;
              } else if (action.contains('Logged in')) {
                icon = Icons.login;
                iconColor = Colors.lightBlueAccent;
              } else if (action.contains('Subscribed')) {
                icon = Icons.diamond;
                iconColor = AppTheme.accentColor;
              }

              return FadeInLeft(
                delay: Duration(milliseconds: index * 40),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: iconColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log['username'] ?? '', style: const TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(action, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(timeStr, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Analytics & Reports Screen ───

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Analytics & Reports'), backgroundColor: AppTheme.cardColor),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final users = userProvider.registeredUsers;
          final total = users.length;
          final premiumCount = users.where((u) => u['subscriptionPlan'] != 'free').length;
          final freeCount = total - premiumCount;
          final goalMap = <String, int>{};
          final planMap = <String, int>{'free': 0, 'basic': 0, 'pro': 0, 'elite': 0};
          for (final u in users) {
            final g = u['goal'] ?? 'Unknown';
            goalMap[g] = (goalMap[g] ?? 0) + 1;
            final p = u['subscriptionPlan'] ?? 'free';
            planMap[p] = (planMap[p] ?? 0) + 1;
          }
          final totalActivities = userProvider.globalActivityLog.length;
          final mealActivities = userProvider.globalActivityLog.where((l) => (l['action'] ?? '').contains('meal')).length;
          final workoutActivities = userProvider.globalActivityLog.where((l) => (l['action'] ?? '').contains('workout')).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Stats
                FadeInDown(child: Text('Overview', style: Theme.of(context).textTheme.displayMedium)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: FadeInUp(delay: const Duration(milliseconds: 100), child: _buildStatCard('Total Users', '$total', Icons.people, AppTheme.primaryColor))),
                    const SizedBox(width: 12),
                    Expanded(child: FadeInUp(delay: const Duration(milliseconds: 200), child: _buildStatCard('Premium', '$premiumCount', Icons.diamond, AppTheme.accentColor))),
                    const SizedBox(width: 12),
                    Expanded(child: FadeInUp(delay: const Duration(milliseconds: 300), child: _buildStatCard('Free', '$freeCount', Icons.person_outline, AppTheme.textSecondaryColor))),
                  ],
                ),
                const SizedBox(height: 32),

                // Engagement
                FadeInUp(delay: const Duration(milliseconds: 400), child: Text('User Engagement', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _buildEngagementRow('Total Activities', '$totalActivities', Icons.timeline),
                        const Divider(color: AppTheme.backgroundColor, height: 24),
                        _buildEngagementRow('Meals Completed', '$mealActivities', Icons.restaurant),
                        const Divider(color: AppTheme.backgroundColor, height: 24),
                        _buildEngagementRow('Workouts Done', '$workoutActivities', Icons.fitness_center),
                        const Divider(color: AppTheme.backgroundColor, height: 24),
                        _buildEngagementRow('Conversion Rate', total > 0 ? '${(premiumCount / total * 100).toStringAsFixed(1)}%' : '0%', Icons.trending_up),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Goal Distribution
                FadeInUp(delay: const Duration(milliseconds: 600), child: Text('Goal Distribution', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                ...goalMap.entries.map((e) {
                  final pct = total > 0 ? e.value / total : 0.0;
                  return FadeInUp(
                    delay: const Duration(milliseconds: 700),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key, style: const TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
                              Text('${e.value} users (${(pct * 100).toStringAsFixed(0)}%)', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: AppTheme.backgroundColor,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 32),

                // Subscription Breakdown
                FadeInUp(delay: const Duration(milliseconds: 800), child: Text('Subscription Breakdown', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                ...planMap.entries.map((e) {
                  final pct = total > 0 ? e.value / total : 0.0;
                  Color barColor = AppTheme.textSecondaryColor;
                  if (e.key == 'basic') barColor = Colors.teal;
                  if (e.key == 'pro') barColor = Colors.blueAccent;
                  if (e.key == 'elite') barColor = AppTheme.accentColor;
                  return FadeInUp(
                    delay: const Duration(milliseconds: 900),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          SizedBox(width: 50, child: Text(e.key.toUpperCase(), style: TextStyle(color: barColor, fontWeight: FontWeight.bold, fontSize: 11))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: AppTheme.backgroundColor, valueColor: AlwaysStoppedAnimation<Color>(barColor)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('${e.value}', style: const TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildEngagementRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor))),
        Text(value, style: const TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

// ─── System Settings Screen ───

class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('System Settings'), backgroundColor: AppTheme.cardColor),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Info
                FadeInDown(child: Text('Application Info', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _buildInfoRow('App Name', 'FitMeal'),
                        const Divider(color: AppTheme.backgroundColor, height: 24),
                        _buildInfoRow('Version', '1.0.0'),
                        const Divider(color: AppTheme.backgroundColor, height: 24),
                        _buildInfoRow('Build', '1'),
                        const Divider(color: AppTheme.backgroundColor, height: 24),
                        _buildInfoRow('Framework', 'Flutter'),
                        const Divider(color: AppTheme.backgroundColor, height: 24),
                        _buildInfoRow('State Management', 'Provider'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Performance
                FadeInUp(delay: const Duration(milliseconds: 200), child: Text('Performance Metrics', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _buildInfoRow('Registered Users', '${userProvider.registeredUsers.length}'),
                        const Divider(color: AppTheme.backgroundColor, height: 24),
                        _buildInfoRow('Activity Log Entries', '${userProvider.globalActivityLog.length}'),
                        const Divider(color: AppTheme.backgroundColor, height: 24),
                        _buildInfoRow('Storage Backend', 'SharedPreferences'),
                        const Divider(color: AppTheme.backgroundColor, height: 24),
                        _buildInfoRow('Server Status', '● Online', valueColor: AppTheme.primaryColor),
                        const Divider(color: AppTheme.backgroundColor, height: 24),
                        _buildInfoRow('API Response', '< 200ms', valueColor: AppTheme.primaryColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Data Management
                FadeInUp(delay: const Duration(milliseconds: 400), child: Text('Data Management', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      _buildActionButton(
                        context,
                        'Clear Activity Logs',
                        Icons.delete_sweep,
                        Colors.orangeAccent,
                        () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppTheme.cardColor,
                              title: const Text('Clear Logs', style: TextStyle(color: AppTheme.textPrimaryColor)),
                              content: const Text('This will remove all activity logs.', style: TextStyle(color: AppTheme.textSecondaryColor)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    userProvider.globalActivityLog.clear();
                                    userProvider.notifyListeners();
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity logs cleared'), backgroundColor: AppTheme.primaryColor));
                                  },
                                  child: const Text('Clear', style: TextStyle(color: Colors.orangeAccent)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        context,
                        'Reset All Data',
                        Icons.restore,
                        AppTheme.dangerColor,
                        () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppTheme.cardColor,
                              title: const Text('Reset All Data', style: TextStyle(color: AppTheme.textPrimaryColor)),
                              content: const Text('This will reset all users, plans, and activity data. This cannot be undone.', style: TextStyle(color: AppTheme.textSecondaryColor)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    userProvider.clearAllData();
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data has been reset'), backgroundColor: AppTheme.dangerColor));
                                  },
                                  child: const Text('Reset', style: TextStyle(color: AppTheme.dangerColor)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // About
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.fitness_center, color: AppTheme.primaryColor, size: 32),
                        SizedBox(height: 8),
                        Text('FitMeal Admin Panel', style: TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('AI-Powered Meal & Fitness Planning', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                      ],
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

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor)),
        Text(value, style: TextStyle(color: valueColor ?? AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
