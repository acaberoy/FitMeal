import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../theme.dart';
import '../providers/user_provider.dart';

class ReportsScreen extends StatelessWidget {
  final bool isAdmin;
  const ReportsScreen({super.key, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        title: Text(isAdmin ? 'Platform Analytics' : 'Your Reports',
            style: const TextStyle(color: AppTheme.textPrimaryColor)),
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
      ),
      body: Consumer<UserProvider>(
        builder: (context, up, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: isAdmin ? _buildAdminReport(context, up) : _buildUserReport(context, up),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════
  // USER REPORT
  // ═══════════════════════════════════════

  List<Widget> _buildUserReport(BuildContext context, UserProvider up) {
    final totalMealsCal = _calcTotalCalories(up.completedMeals);
    final mealsDone = up.completedMeals.length;
    final workoutsDone = up.completedWorkouts.length;
    final totalMeals = up.meals.length;
    final totalWorkouts = up.workouts.length;
    final mealRate = totalMeals > 0 ? (mealsDone / totalMeals * 100).round() : 0;
    final workoutRate = totalWorkouts > 0 ? (workoutsDone / totalWorkouts * 100).round() : 0;

    return [
      FadeInDown(child: Text('Weekly Summary', style: Theme.of(context).textTheme.displayMedium)),
      const SizedBox(height: 24),

      // Summary cards row
      FadeInUp(
        delay: const Duration(milliseconds: 100),
        child: Row(children: [
          Expanded(child: _summaryCard('Meals Done', '$mealsDone / $totalMeals', Icons.restaurant, AppTheme.primaryColor)),
          const SizedBox(width: 12),
          Expanded(child: _summaryCard('Workouts', '$workoutsDone / $totalWorkouts', Icons.fitness_center, AppTheme.accentColor)),
          const SizedBox(width: 12),
          Expanded(child: _summaryCard('Calories', '$totalMealsCal', Icons.local_fire_department, Colors.orangeAccent)),
        ]),
      ),
      const SizedBox(height: 12),
      FadeInUp(
        delay: const Duration(milliseconds: 150),
        child: Row(children: [
          Expanded(child: _summaryCard('Meal Rate', '$mealRate%', Icons.check_circle, Colors.tealAccent)),
          const SizedBox(width: 12),
          Expanded(child: _summaryCard('Workout Rate', '$workoutRate%', Icons.speed, Colors.pinkAccent)),
          const SizedBox(width: 12),
          Expanded(child: _summaryCard('Badges', '${up.achievements.length}', Icons.emoji_events, Colors.amber)),
        ]),
      ),
      const SizedBox(height: 32),

      // Macro pie chart
      FadeInUp(
        delay: const Duration(milliseconds: 200),
        child: _sectionTitle(context, 'Macronutrient Distribution'),
      ),
      const SizedBox(height: 16),
      FadeInUp(
        delay: const Duration(milliseconds: 300),
        child: _buildMacroPieChart(up),
      ),
      const SizedBox(height: 32),

      // Completion bar chart
      FadeInUp(
        delay: const Duration(milliseconds: 400),
        child: _sectionTitle(context, 'Completion Overview'),
      ),
      const SizedBox(height: 16),
      FadeInUp(
        delay: const Duration(milliseconds: 500),
        child: _buildCompletionBarChart(mealsDone, workoutsDone, totalMeals, totalWorkouts),
      ),
      const SizedBox(height: 32),

      // Achievements list
      FadeInUp(
        delay: const Duration(milliseconds: 600),
        child: _sectionTitle(context, 'Achievements Earned'),
      ),
      const SizedBox(height: 16),
      if (up.achievements.isEmpty)
        const Text('No achievements yet. Complete meals and workouts to earn badges!',
            style: TextStyle(color: AppTheme.textSecondaryColor))
      else
        ...up.achievements.map((a) => _achievementTile(_formatAchievement(a))),
    ];
  }

  // ═══════════════════════════════════════
  // ADMIN REPORT
  // ═══════════════════════════════════════

  List<Widget> _buildAdminReport(BuildContext context, UserProvider up) {
    final users = up.registeredUsers.where((u) => u['role'] != 'admin').toList();
    final total = users.length;
    final planCounts = <String, int>{};
    final goalCounts = <String, int>{};
    for (final u in users) {
      final p = u['subscriptionPlan'] ?? 'free';
      final g = u['goal'] ?? 'Unknown';
      planCounts[p] = (planCounts[p] ?? 0) + 1;
      goalCounts[g] = (goalCounts[g] ?? 0) + 1;
    }

    return [
      FadeInDown(child: Text('Platform Analytics', style: Theme.of(context).textTheme.displayMedium)),
      const SizedBox(height: 8),
      Text('$total registered users', style: const TextStyle(color: AppTheme.textSecondaryColor)),
      const SizedBox(height: 24),

      // Subscription pie
      FadeInUp(delay: const Duration(milliseconds: 100), child: _sectionTitle(context, 'Users by Subscription')),
      const SizedBox(height: 16),
      FadeInUp(delay: const Duration(milliseconds: 200), child: _buildDistPieChart(planCounts, [AppTheme.primaryColor, Colors.orangeAccent, AppTheme.accentColor, Colors.pinkAccent])),
      const SizedBox(height: 32),

      // Goal bar
      FadeInUp(delay: const Duration(milliseconds: 300), child: _sectionTitle(context, 'Users by Fitness Goal')),
      const SizedBox(height: 16),
      FadeInUp(delay: const Duration(milliseconds: 400), child: _buildGoalBarChart(goalCounts)),
      const SizedBox(height: 32),

      // User table
      FadeInUp(delay: const Duration(milliseconds: 500), child: _sectionTitle(context, 'User Directory')),
      const SizedBox(height: 16),
      _buildUserTable(users),
    ];
  }

  // ═══════════════════════════════════════
  // CHART WIDGETS
  // ═══════════════════════════════════════

  Widget _buildMacroPieChart(UserProvider up) {
    double protein = 0, carbs = 0, fats = 0;
    for (final m in up.meals) {
      final macroStr = m['macros']?.toString() ?? '';
      protein += _extractMacro(macroStr, 'P');
      carbs += _extractMacro(macroStr, 'C');
      fats += _extractMacro(macroStr, 'F');
    }
    if (protein == 0 && carbs == 0 && fats == 0) {
      protein = 30; carbs = 45; fats = 25; // defaults
    }
    final total = protein + carbs + fats;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        SizedBox(
          height: 200,
          child: PieChart(PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 40,
            sections: [
              PieChartSectionData(value: protein, title: '${(protein / total * 100).round()}%', color: Colors.blueAccent, radius: 55, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              PieChartSectionData(value: carbs, title: '${(carbs / total * 100).round()}%', color: Colors.orangeAccent, radius: 55, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              PieChartSectionData(value: fats, title: '${(fats / total * 100).round()}%', color: Colors.redAccent, radius: 55, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          )),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _legendDot('Protein', Colors.blueAccent),
          _legendDot('Carbs', Colors.orangeAccent),
          _legendDot('Fats', Colors.redAccent),
        ]),
      ]),
    );
  }

  Widget _buildCompletionBarChart(int mealsDone, int workoutsDone, int totalMeals, int totalWorkouts) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20)),
      height: 220,
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (totalMeals > totalWorkouts ? totalMeals : totalWorkouts).toDouble().clamp(1, 100),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(v.toInt() == 0 ? 'Meals' : 'Workouts', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
            ),
          )),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(toY: totalMeals.toDouble(), color: AppTheme.primaryColor.withOpacity(0.3), width: 28, borderRadius: BorderRadius.circular(6)),
            BarChartRodData(toY: mealsDone.toDouble(), color: AppTheme.primaryColor, width: 28, borderRadius: BorderRadius.circular(6)),
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(toY: totalWorkouts.toDouble(), color: AppTheme.accentColor.withOpacity(0.3), width: 28, borderRadius: BorderRadius.circular(6)),
            BarChartRodData(toY: workoutsDone.toDouble(), color: AppTheme.accentColor, width: 28, borderRadius: BorderRadius.circular(6)),
          ]),
        ],
      )),
    );
  }

  Widget _buildDistPieChart(Map<String, int> data, List<Color> colors) {
    if (data.isEmpty) return const Text('No data', style: TextStyle(color: AppTheme.textSecondaryColor));
    final entries = data.entries.toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        SizedBox(
          height: 200,
          child: PieChart(PieChartData(
            sectionsSpace: 3, centerSpaceRadius: 40,
            sections: List.generate(entries.length, (i) => PieChartSectionData(
              value: entries[i].value.toDouble(),
              title: '${entries[i].value}',
              color: colors[i % colors.length],
              radius: 55,
              titleStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            )),
          )),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16, runSpacing: 8,
          children: List.generate(entries.length, (i) => _legendDot(entries[i].key, colors[i % colors.length])),
        ),
      ]),
    );
  }

  Widget _buildGoalBarChart(Map<String, int> goalCounts) {
    if (goalCounts.isEmpty) return const Text('No data', style: TextStyle(color: AppTheme.textSecondaryColor));
    final entries = goalCounts.entries.toList();
    final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();
    final barColors = [AppTheme.primaryColor, AppTheme.accentColor, Colors.orangeAccent, Colors.tealAccent, Colors.pinkAccent];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20)),
      height: 220,
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal + 1,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 40,
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              if (idx < 0 || idx >= entries.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(entries[idx].key.split(' ').first, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10)),
              );
            },
          )),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(entries.length, (i) => BarChartGroupData(x: i, barRods: [
          BarChartRodData(toY: entries[i].value.toDouble(), color: barColors[i % barColors.length], width: 24, borderRadius: BorderRadius.circular(6)),
        ])),
      )),
    );
  }

  Widget _buildUserTable(List<Map<String, dynamic>> users) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: users.map((u) => ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            child: Text((u['username'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
          title: Text(u['username'] ?? '', style: const TextStyle(color: AppTheme.textPrimaryColor)),
          subtitle: Text('${u['goal'] ?? 'No goal'} • ${u['subscriptionPlan'] ?? 'free'}', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
        )).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: AppTheme.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11)),
      ]),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _legendDot(String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
    ]);
  }

  Widget _achievementTile(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(name, style: const TextStyle(color: AppTheme.textPrimaryColor))),
        const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 18),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════

  int _calcTotalCalories(List<Map<String, dynamic>> meals) {
    int total = 0;
    for (final m in meals) {
      final calStr = (m['calories'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
      total += int.tryParse(calStr) ?? 0;
    }
    return total;
  }

  double _extractMacro(String macroStr, String key) {
    final regex = RegExp('$key:\\s*(\\d+)');
    final match = regex.firstMatch(macroStr);
    return match != null ? double.tryParse(match.group(1)!) ?? 0 : 0;
  }

  String _formatAchievement(String id) {
    switch (id) {
      case 'first_meal': return 'First Meal Logged 🍽️';
      case 'first_workout': return 'First Workout Done 💪';
      case 'nutrition_champion': return 'Daily Nutrition Champion 🏆';
      case 'workout_warrior': return 'Workout Warrior ⚔️';
      case 'premium_member': return 'Premium Member 💎';
      case 'profile_complete': return 'Profile Complete ✅';
      default: return id;
    }
  }
}
