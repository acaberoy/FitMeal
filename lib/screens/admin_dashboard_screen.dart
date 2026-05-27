import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/user_provider.dart';
import 'admin_mock_screens.dart';
import 'reports_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        title: const Text('Super Admin Dashboard', style: TextStyle(color: AppTheme.textPrimaryColor)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final totalUsers = userProvider.registeredUsers.length;
          final premiumCount = userProvider.registeredUsers.where((u) => u['subscriptionPlan'] != 'free').length;
          final goalMap = <String, int>{};
          for (final u in userProvider.registeredUsers) {
            final g = u['goal'] ?? 'Unknown';
            goalMap[g] = (goalMap[g] ?? 0) + 1;
          }
          final topGoal = goalMap.entries.isEmpty ? 'N/A' : goalMap.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInLeft(
                  child: Text('System Overview', style: Theme.of(context).textTheme.displayMedium),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: FadeInUp(delay: const Duration(milliseconds: 100), child: _buildStatCard('Total Users', '$totalUsers', Icons.people))),
                    const SizedBox(width: 12),
                    Expanded(child: FadeInUp(delay: const Duration(milliseconds: 200), child: _buildStatCard('Premium', '$premiumCount', Icons.diamond, color: AppTheme.accentColor))),
                    const SizedBox(width: 12),
                    Expanded(child: FadeInUp(delay: const Duration(milliseconds: 300), child: _buildStatCard('Top Goal', topGoal, Icons.flag, color: Colors.tealAccent))),
                  ],
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Text('Admin Actions', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                FadeInUp(delay: const Duration(milliseconds: 500), child: _buildActionTile('Manage Users', Icons.manage_accounts, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen())))),
                FadeInUp(delay: const Duration(milliseconds: 600), child: _buildActionTile('User Activity Logs', Icons.monitor_heart, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserActivityScreen())))),
                FadeInUp(delay: const Duration(milliseconds: 700), child: _buildActionTile('Analytics & Reports', Icons.analytics, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(isAdmin: true))))),
                FadeInUp(delay: const Duration(milliseconds: 800), child: _buildActionTile('System Settings', Icons.settings, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemSettingsScreen())))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {Color color = AppTheme.primaryColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimaryColor)),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondaryColor, size: 16),
        onTap: onTap,
      ),
    );
  }
}
