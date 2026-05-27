import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';
import '../services/email_service.dart';

class UserProvider extends ChangeNotifier {
  String role = 'user';
  String name = 'Alex';
  int age = 25;
  double weight = 70.0;
  double height = 170.0;
  String primaryGoal = 'Lose Weight';
  String dietaryRestrictions = '';
  String subscriptionPlan = 'free';
  bool get isPremium => subscriptionPlan != 'free';
  List<Map<String, dynamic>> completedMeals = [];
  List<Map<String, dynamic>> completedWorkouts = [];
  List<Map<String, dynamic>> meals = [];
  List<Map<String, String>> workouts = [];
  String aiAdvice = '';
  String currentUsername = '';
  int workoutsCompleted = 0;
  List<String> achievements = [];
  List<Map<String, dynamic>> globalActivityLog = [];

  // Firestore service instance for cloud sync
  final FirestoreService _firestoreService = FirestoreService();
  // Email notification service
  final EmailService _emailService = EmailService();
  String? _firestoreUserId; // tracks the Firestore document ID for current user

  List<Map<String, dynamic>> registeredUsers = [
    {'username': 'john_doe', 'password': 'John@123', 'subscriptionPlan': 'elite', 'goal': 'Build Muscle'},
    {'username': 'sarah_smith', 'password': 'Sarah@123', 'subscriptionPlan': 'free', 'goal': 'Lose Weight'},
    {'username': 'mike_fitness', 'password': 'Mike@123', 'subscriptionPlan': 'pro', 'goal': 'Maintain Health'},
    {'username': 'admin', 'password': 'Admin@123', 'subscriptionPlan': 'free', 'goal': 'Admin', 'role': 'admin'},
  ];

  // ─── Persistence ───

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('registeredUsers');
    if (usersJson != null) {
      registeredUsers = List<Map<String, dynamic>>.from(
        (jsonDecode(usersJson) as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }
    // Always ensure the admin account exists
    final hasAdmin = registeredUsers.any(
      (u) => u['username']?.toString().toLowerCase() == 'admin' && u['role'] == 'admin',
    );
    if (!hasAdmin) {
      registeredUsers.add({'username': 'admin', 'password': 'Admin@123', 'subscriptionPlan': 'free', 'goal': 'Admin', 'role': 'admin'});
    }
    await _loadGlobalActivityLog();
    // Sync: pull users from Firestore so phone + web share the same data
    await _loadUsersFromFirestore();
    // One-time sync: push all existing local users to Firestore
    await _syncAllUsersToFirestore();
  }

  /// Fetches all users from Firestore and merges them into local registeredUsers
  Future<void> _loadUsersFromFirestore() async {
    try {
      final firestoreUsers = await _firestoreService.getAllUsersIncludingAdmin();

      for (final fsUser in firestoreUsers) {
        final username = fsUser['username']?.toString().toLowerCase() ?? '';
        if (username.isEmpty) continue;

        // Check if user already exists locally
        final localIndex = registeredUsers.indexWhere(
          (u) => u['username']?.toString().toLowerCase() == username,
        );

        if (localIndex == -1) {
          // User only exists in Firestore — add to local list
          registeredUsers.add({
            'username': username,
            'password': fsUser['passwordHash'] ?? '',
            'subscriptionPlan': fsUser['subscriptionPlan'] ?? 'free',
            'goal': fsUser['primaryGoal'] ?? 'Pending Setup',
            'role': fsUser['role'] ?? 'user',
          });
        } else {
          // User exists locally — update subscription & goal from Firestore (cloud is truth)
          final fsPlan = fsUser['subscriptionPlan']?.toString();
          final fsGoal = fsUser['primaryGoal']?.toString();
          if (fsPlan != null && fsPlan != 'free') {
            registeredUsers[localIndex]['subscriptionPlan'] = fsPlan;
          }
          if (fsGoal != null && fsGoal != 'Pending Setup') {
            registeredUsers[localIndex]['goal'] = fsGoal;
          }
        }

        // Cache Firestore doc ID locally for future syncs
        final docId = fsUser['userId'] as String?;
        if (docId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('firestoreId_$username', docId);
        }
      }

      _saveUsers();
      debugPrint('✅ Merged ${firestoreUsers.length} Firestore users → local (total: ${registeredUsers.length})');
    } catch (e) {
      debugPrint('⚠️ Failed to load users from Firestore: $e');
    }
  }

  /// Pushes all locally registered users to Firestore
  Future<void> _syncAllUsersToFirestore() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      int syncedCount = 0;
      for (final user in registeredUsers) {
        final username = user['username']?.toString().toLowerCase() ?? '';
        if (username.isEmpty) continue;

        // Skip if this user already has a Firestore ID
        final existingId = prefs.getString('firestoreId_$username');
        if (existingId != null) {
          syncedCount++;
          continue;
        }

        try {
          // Check if user already exists in Firestore
          final existing = await _firestoreService.getUserByUsername(username);
          if (existing != null) {
            final docId = existing['userId'] as String?;
            if (docId != null) {
              await prefs.setString('firestoreId_$username', docId);
            }
            syncedCount++;
            continue;
          }

          // Create user in Firestore
          final docId = await _firestoreService.createUser(
            username: username,
            passwordHash: 'local_auth',
            role: 'user',
          );
          await prefs.setString('firestoreId_$username', docId);

          // Sync profile data if available
          final userData = await getUserData(username);
          if (userData != null) {
            await _firestoreService.updateUserProfile(
              userId: docId,
              name: userData['name'] as String? ?? username,
              age: userData['age'] as int? ?? 0,
              weight: (userData['weight'] as num?)?.toDouble() ?? 0.0,
              height: (userData['height'] as num?)?.toDouble() ?? 0.0,
              primaryGoal: userData['primaryGoal'] as String? ?? user['goal'] as String? ?? 'Pending Setup',
              dietaryRestrictions: userData['dietaryRestrictions'] as String? ?? '',
            );
          } else {
            await _firestoreService.updateUserProfile(
              userId: docId,
              primaryGoal: user['goal'] as String? ?? 'Pending Setup',
            );
          }

          // Sync subscription
          final plan = user['subscriptionPlan'] as String? ?? 'free';
          if (plan != 'free') {
            await _firestoreService.updateSubscription(userId: docId, plan: plan);
          }

          // Initialize achievements
          await _firestoreService.initializeAchievements(docId);

          syncedCount++;
          debugPrint('✅ Synced user "$username" to Firestore (ID: $docId)');
        } catch (e) {
          debugPrint('⚠️ Failed to sync user "$username": $e');
        }
      }

      debugPrint('✅ Firestore sync complete: $syncedCount/${registeredUsers.length} users');
    } catch (e) {
      debugPrint('⚠️ Firestore sync failed: $e');
    }
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('registeredUsers', jsonEncode(registeredUsers));
  }

  Future<void> _loadGlobalActivityLog() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('globalActivityLog');
    if (json != null) {
      globalActivityLog = List<Map<String, dynamic>>.from(
        (jsonDecode(json) as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }
  }

  Future<void> _saveGlobalActivityLog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('globalActivityLog', jsonEncode(globalActivityLog));
  }

  void logActivity(String action) {
    if (currentUsername.isEmpty) return;
    globalActivityLog.insert(0, {
      'username': currentUsername,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (globalActivityLog.length > 200) {
      globalActivityLog = globalActivityLog.sublist(0, 200);
    }
    _saveGlobalActivityLog();
  }

  List<String> checkAndAwardAchievements() {
    List<String> newlyEarned = [];
    if (completedMeals.isNotEmpty && !achievements.contains('first_meal')) {
      achievements.add('first_meal');
      newlyEarned.add('First Meal Logged');
    }
    if (completedWorkouts.isNotEmpty && !achievements.contains('first_workout')) {
      achievements.add('first_workout');
      newlyEarned.add('First Workout Done');
    }
    if (meals.isNotEmpty && completedMeals.length >= meals.length && !achievements.contains('nutrition_champion')) {
      achievements.add('nutrition_champion');
      newlyEarned.add('Daily Nutrition Champion');
    }
    if (workoutsCompleted >= 5 && !achievements.contains('workout_warrior')) {
      achievements.add('workout_warrior');
      newlyEarned.add('Workout Warrior');
    }
    if (isPremium && !achievements.contains('premium_member')) {
      achievements.add('premium_member');
      newlyEarned.add('Premium Member');
    }
    if (name.isNotEmpty && primaryGoal != 'Pending Setup' && !achievements.contains('profile_complete')) {
      achievements.add('profile_complete');
      newlyEarned.add('Profile Complete');
    }
    if (newlyEarned.isNotEmpty) {
      _saveUserData();
      notifyListeners();
    }
    return newlyEarned;
  }

  Future<void> _saveUserData() async {
    if (currentUsername.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'name': name, 'age': age, 'weight': weight, 'height': height,
      'primaryGoal': primaryGoal, 'dietaryRestrictions': dietaryRestrictions,
      'subscriptionPlan': subscriptionPlan,
      'completedMeals': completedMeals, 'completedWorkouts': completedWorkouts,
      'meals': meals, 'workouts': workouts, 'aiAdvice': aiAdvice,
      'workoutsCompleted': workoutsCompleted,
      'achievements': achievements,
    };
    await prefs.setString('userData_$currentUsername', jsonEncode(data));
  }

  Future<void> loadUserData(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('userData_$username');
    if (json != null) {
      final d = jsonDecode(json) as Map<String, dynamic>;
      name = d['name'] ?? name;
      age = d['age'] ?? age;
      weight = (d['weight'] ?? weight).toDouble();
      height = (d['height'] ?? height).toDouble();
      primaryGoal = d['primaryGoal'] ?? primaryGoal;
      dietaryRestrictions = d['dietaryRestrictions'] ?? '';
      subscriptionPlan = d['subscriptionPlan'] ?? 'free';
      aiAdvice = d['aiAdvice'] ?? '';
      workoutsCompleted = d['workoutsCompleted'] ?? 0;
      completedMeals = List<Map<String, dynamic>>.from(
        (d['completedMeals'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? [],
      );
      completedWorkouts = List<Map<String, dynamic>>.from(
        (d['completedWorkouts'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? [],
      );
      meals = List<Map<String, dynamic>>.from(
        (d['meals'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? [],
      );
      workouts = List<Map<String, String>>.from(
        (d['workouts'] as List?)?.map((e) => Map<String, String>.from(e)) ?? [],
      );
      achievements = List<String>.from(d['achievements'] ?? []);
    }
  }

  // ─── Auth ───

  /// Validates username and password against registered users.
  /// Returns null on success, or an error message on failure.
  String? validateLogin(String username, String password) {
    final lowerUsername = username.toLowerCase().trim();
    if (lowerUsername.isEmpty) return 'Please enter a username';
    if (password.isEmpty) return 'Please enter a password';

    final userIndex = registeredUsers.indexWhere(
      (u) => u['username']?.toString().toLowerCase() == lowerUsername,
    );
    if (userIndex == -1) return 'Account not found. Please register first.';

    final storedPassword = registeredUsers[userIndex]['password']?.toString() ?? '';
    if (storedPassword != password) return 'Incorrect password. Please try again.';

    return null; // success
  }

  void loginAs(String newRole, {String username = ''}) {
    role = newRole;
    currentUsername = username;
    name = username.isNotEmpty ? '${username[0].toUpperCase()}${username.substring(1)}' : 'User';
    final userIndex = registeredUsers.indexWhere((u) => u['username']?.toString().toLowerCase() == username.toLowerCase());
    if (userIndex != -1) {
      subscriptionPlan = registeredUsers[userIndex]['subscriptionPlan'] ?? 'free';
      primaryGoal = registeredUsers[userIndex]['goal'] ?? 'Lose Weight';
    }
    logActivity('Logged in');
    // Load Firestore ID and update last login
    _syncLoginToFirestore(username);
    notifyListeners();
  }

  Future<void> _syncLoginToFirestore(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _firestoreUserId = prefs.getString('firestoreId_${username.toLowerCase()}');
      if (_firestoreUserId != null) {
        await _firestoreService.updateLastLogin(_firestoreUserId!);
      }
    } catch (e) {
      debugPrint('Firestore sync (login) failed: $e');
    }
  }

  void registerUser(String username, {String password = '', String email = ''}) {
    final lowerUsername = username.toLowerCase();
    currentUsername = lowerUsername;
    role = 'user';
    name = lowerUsername.isNotEmpty ? '${lowerUsername[0].toUpperCase()}${lowerUsername.substring(1)}' : 'User';
    registeredUsers.add({
      'username': lowerUsername, 'password': password, 'subscriptionPlan': 'free', 'goal': 'Pending Setup', 'email': email,
    });
    _saveUsers();
    // Sync to Firestore
    _syncRegisterToFirestore(lowerUsername, password);
    // Send welcome email notification
    if (email.isNotEmpty) {
      _emailService.sendWelcomeEmail(toEmail: email, username: lowerUsername);
    }
    notifyListeners();
  }

  Future<void> _syncRegisterToFirestore(String username, [String password = '']) async {
    try {
      final docId = await _firestoreService.createUser(
        username: username,
        passwordHash: password.isNotEmpty ? password : 'local_auth',
        role: 'user',
      );
      _firestoreUserId = docId;
      // Save Firestore ID locally for future syncs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('firestoreId_$username', docId);
      await _firestoreService.initializeAchievements(docId);
    } catch (e) {
      debugPrint('Firestore sync (register) failed: $e');
    }
  }

  void updateProfile({required String newName, required int newAge, required double newWeight, double? newHeight, required String goal, required String restrictions}) {
    name = newName.isNotEmpty ? newName : name;
    age = newAge > 0 ? newAge : age;
    weight = newWeight > 0 ? newWeight : weight;
    if (newHeight != null && newHeight > 0) height = newHeight;
    primaryGoal = goal;
    dietaryRestrictions = restrictions;
    final userIndex = registeredUsers.indexWhere((u) => u['username'] == currentUsername);
    if (userIndex != -1) {
      registeredUsers[userIndex]['goal'] = goal;
    }
    _saveUsers();
    _saveUserData();
    // Sync profile to Firestore
    _syncProfileToFirestore();
    notifyListeners();
  }

  Future<void> _syncProfileToFirestore() async {
    if (_firestoreUserId == null) return;
    try {
      await _firestoreService.updateUserProfile(
        userId: _firestoreUserId!,
        name: name,
        age: age,
        weight: weight,
        height: height,
        primaryGoal: primaryGoal,
        dietaryRestrictions: dietaryRestrictions,
      );
    } catch (e) {
      debugPrint('Firestore sync (profile) failed: $e');
    }
  }

  void subscribeToPlan(String plan) {
    subscriptionPlan = plan;
    final userIndex = registeredUsers.indexWhere((u) => u['username'] == currentUsername);
    if (userIndex != -1) {
      registeredUsers[userIndex]['subscriptionPlan'] = plan;
    }
    generateAIPlans();
    logActivity('Subscribed to $plan plan');
    _saveUsers();
    _saveUserData();
    // Sync subscription to Firestore
    if (_firestoreUserId != null) {
      _firestoreService.updateSubscription(userId: _firestoreUserId!, plan: plan)
        .catchError((e) => debugPrint('Firestore sync (subscription) failed: $e'));
    }
    notifyListeners();
  }

  void completeWorkout(Map<String, String> workout) {
    completedWorkouts.add({...workout, 'completedAt': DateTime.now().toIso8601String()});
    if (workoutsCompleted < 5) workoutsCompleted++;
    logActivity('Completed workout: ${workout['name']}');
    _saveUserData();
    notifyListeners();
  }

  void completeMeal(Map<String, dynamic> meal) {
    completedMeals.add({...meal, 'completedAt': DateTime.now().toIso8601String()});
    logActivity('Completed meal: ${meal['name']}');
    _saveUserData();
    notifyListeners();
  }

  void logout() {
    _saveUserData();
    role = 'user';
    name = '';
    age = 25;
    weight = 70.0;
    height = 170.0;
    primaryGoal = 'Lose Weight';
    dietaryRestrictions = '';
    subscriptionPlan = 'free';
    meals = [];
    workouts = [];
    completedMeals = [];
    completedWorkouts = [];
    aiAdvice = '';
    currentUsername = '';
    workoutsCompleted = 0;
    achievements = [];
    notifyListeners();
  }

  // Admin helpers
  void deleteUser(int index) {
    registeredUsers.removeAt(index);
    _saveUsers();
    notifyListeners();
  }

  void updateUserSubscription(int index, String plan) {
    registeredUsers[index]['subscriptionPlan'] = plan;
    _saveUsers();
    notifyListeners();
  }

  void updateUserGoal(int index, String goal) {
    registeredUsers[index]['goal'] = goal;
    _saveUsers();
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getUserData(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('userData_$username');
    if (json != null) return jsonDecode(json) as Map<String, dynamic>;
    return null;
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    globalActivityLog = [];
    registeredUsers = [
      {'username': 'john_doe', 'password': 'John@123', 'subscriptionPlan': 'elite', 'goal': 'Build Muscle'},
      {'username': 'sarah_smith', 'password': 'Sarah@123', 'subscriptionPlan': 'free', 'goal': 'Lose Weight'},
      {'username': 'mike_fitness', 'password': 'Mike@123', 'subscriptionPlan': 'pro', 'goal': 'Maintain Health'},
      {'username': 'admin', 'password': 'Admin@123', 'subscriptionPlan': 'free', 'goal': 'Admin', 'role': 'admin'},
    ];
    notifyListeners();
  }

  // ─── AI Plan Generation (unchanged) ───

  void generateAIPlans() {
    workoutsCompleted = completedWorkouts.length;
    if (subscriptionPlan == 'pro' || subscriptionPlan == 'elite') {
      _generatePremiumPlans();
    } else if (subscriptionPlan == 'basic') {
      _generateBasicPlans();
    } else {
      _generateFreePlans();
    }
    _saveUserData();
    // Send plan summary email notification
    _sendPlanEmail();
    notifyListeners();
  }

  Future<void> _sendPlanEmail() async {
    final userIndex = registeredUsers.indexWhere((u) => u['username'] == currentUsername);
    final email = userIndex != -1 ? (registeredUsers[userIndex]['email'] ?? '') : '';
    if (email.toString().isNotEmpty) {
      await _emailService.sendPlanSummaryEmail(
        toEmail: email.toString(),
        username: currentUsername,
        goal: primaryGoal,
        mealCount: meals.length,
        workoutCount: workouts.length,
        subscriptionPlan: subscriptionPlan,
      );
    }
  }

  void _generatePremiumPlans() {
    if (primaryGoal == 'Lose Weight') {
      aiAdvice = 'Premium AI Analysis: To optimize fat loss while preserving muscle at $weight kg, maintain a 400 kcal deficit. Focus on high-volume, low-calorie dense foods to maximize satiety. Hydration is critical—aim for 3 liters of water daily.';
      meals = [
        {'type': 'Breakfast', 'name': 'Egg White & Spinach Frittata', 'calories': '280 kcal', 'macros': 'P: 30g | C: 10g | F: 12g', 'benefit': 'High protein helps retain muscle during a caloric deficit'},
        {'type': 'Morning Snack', 'name': 'Protein Shake & Apple', 'calories': '210 kcal', 'macros': 'P: 25g | C: 20g | F: 2g', 'benefit': 'Apples provide fiber for satiety and sustained energy'},
        {'type': 'Lunch', 'name': 'Grilled Chicken & Quinoa Salad', 'calories': '410 kcal', 'macros': 'P: 45g | C: 35g | F: 10g', 'benefit': 'Quinoa offers complex carbs for sustained fat-burning'},
        {'type': 'Afternoon Snack', 'name': 'Carrot Sticks & Hummus', 'calories': '150 kcal', 'macros': 'P: 5g | C: 15g | F: 8g', 'benefit': 'Low-calorie crunch to curb afternoon cravings'},
        {'type': 'Dinner', 'name': 'Baked Cod with Roasted Asparagus', 'calories': '350 kcal', 'macros': 'P: 40g | C: 15g | F: 12g', 'benefit': 'Lean fish supports fast metabolism and cellular repair'},
        if (subscriptionPlan == 'elite') ...[
          {'type': 'Evening Snack', 'name': 'Greek Yogurt & Almonds', 'calories': '180 kcal', 'macros': 'P: 15g | C: 8g | F: 10g', 'benefit': 'Slow-digesting protein prevents muscle breakdown overnight'},
          {'type': 'Recovery Drink', 'name': 'Chamomile Tea & Collagen', 'calories': '40 kcal', 'macros': 'P: 10g | C: 0g | F: 0g', 'benefit': 'Improves sleep quality and tissue recovery'},
        ],
      ];
      workouts = [
        {'name': 'Advanced HIIT Protocol', 'details': '40 mins • High Intensity', 'focus': 'Fat Oxidation & Cardiovascular Endurance', 'steps': '1. Warmup: 5 min light jog\n2. Sprint 30s, rest 30s (x10)\n3. Jump squats: 3x15\n4. Burpees: 3x10\n5. Cooldown: 5 mins'},
        {'name': 'Functional Core Circuit', 'details': '20 mins • Intermediate', 'focus': 'Abdominal Definition & Stability', 'steps': '1. Plank: 60s\n2. Russian Twists: 20 reps\n3. Leg Raises: 15 reps\n4. Repeat 4x'},
        {'name': 'Lower Body Power', 'details': '45 mins • Advanced', 'focus': 'Glutes & Quads', 'steps': '1. Dynamic stretching\n2. Goblet Squats: 4x15\n3. Lunges: 3x12/leg\n4. Box Jumps: 3x10'},
        {'name': 'Upper Body Sculpt', 'details': '40 mins • Intermediate', 'focus': 'Arms & Shoulders', 'steps': '1. Arm circles\n2. Pushups: 4x15\n3. Dumbbell Rows: 3x12\n4. Shoulder Press: 3x15'},
        if (subscriptionPlan == 'elite') ...[
          {'name': 'Active Recovery Swim', 'details': '30 mins • Low Impact', 'focus': 'Joint Mobility', 'steps': '1. Freestyle: 10 laps\n2. Breaststroke: 10 laps\n3. Water walking: 5 mins'},
          {'name': 'Deep Tissue Mobility', 'details': '20 mins • Recovery', 'focus': 'Fascia Release', 'steps': '1. Foam roll IT bands: 2 mins/leg\n2. Foam roll upper back: 3 mins\n3. Static stretching'},
        ],
      ];
    } else if (primaryGoal == 'Build Muscle') {
      aiAdvice = 'Premium AI Analysis: Hypertrophy requires a caloric surplus of 300 kcal. Prioritize protein intake (2g per kg body weight) and ensure progressive overload in compound lifts.';
      meals = [
        {'type': 'Breakfast', 'name': 'Protein Oatmeal with Peanut Butter', 'calories': '550 kcal', 'macros': 'P: 40g | C: 60g | F: 20g', 'benefit': 'Heavy carb load fuels intense morning workouts'},
        {'type': 'Pre-Workout', 'name': 'Rice Cakes & Almond Butter', 'calories': '220 kcal', 'macros': 'P: 6g | C: 30g | F: 8g', 'benefit': 'Quick digesting carbs for immediate energy'},
        {'type': 'Lunch', 'name': 'Lean Grass-Fed Steak & Brown Rice', 'calories': '750 kcal', 'macros': 'P: 55g | C: 70g | F: 25g', 'benefit': 'High calories and iron support massive muscle growth'},
        {'type': 'Post-Workout', 'name': 'Whey Isolate & Banana', 'calories': '250 kcal', 'macros': 'P: 30g | C: 30g | F: 2g', 'benefit': 'Rapid protein absorption stops catabolism'},
        {'type': 'Dinner', 'name': 'Grilled Chicken & Sweet Potato', 'calories': '680 kcal', 'macros': 'P: 50g | C: 80g | F: 15g', 'benefit': 'Replenishes glycogen for tomorrow\'s session'},
        if (subscriptionPlan == 'elite') ...[
          {'type': 'Before Bed', 'name': 'Casein Protein & Cottage Cheese', 'calories': '200 kcal', 'macros': 'P: 35g | C: 5g | F: 4g', 'benefit': 'Trickles protein during sleep'},
          {'type': 'Intra-Workout', 'name': 'BCAA & Electrolyte Formula', 'calories': '15 kcal', 'macros': 'P: 3g | C: 0g | F: 0g', 'benefit': 'Prevents fatigue mid-set'},
        ],
      ];
      workouts = [
        {'name': 'Day 1: Heavy Push', 'details': '60 mins • Advanced', 'focus': 'Chest, Shoulders, Triceps', 'steps': '1. Bench Press: 4x8-10\n2. Incline DB Press: 3x10-12\n3. OHP: 4x8\n4. Tricep Pushdowns: 3x15'},
        {'name': 'Day 2: Heavy Pull', 'details': '60 mins • Advanced', 'focus': 'Back, Biceps', 'steps': '1. Deadlifts: 4x5\n2. Pull-ups: 3x failure\n3. Barbell Rows: 4x8-10\n4. Bicep Curls: 3x12'},
        {'name': 'Day 3: Legs & Core', 'details': '75 mins • Advanced', 'focus': 'Quads, Hamstrings, Glutes', 'steps': '1. Back Squats: 4x8\n2. Romanian DLs: 4x10\n3. Leg Press: 3x12\n4. Calf Raises: 4x20'},
        {'name': 'Day 4: Upper Pump', 'details': '45 mins • Intermediate', 'focus': 'Overall Upper Body', 'steps': '1. DB Bench: 3x15\n2. Lat Pulldowns: 3x15\n3. Lateral Raises: 4x20\n4. Hammer Curls: 3x15'},
        if (subscriptionPlan == 'elite') ...[
          {'name': 'Day 5: Weak Points', 'details': '40 mins • Specific', 'focus': 'Calves, Forearms, Abs', 'steps': '1. Seated Calf Raises: 5x20\n2. Wrist Curls: 4x15\n3. Cable Crunches: 4x15'},
          {'name': 'Day 6: Mobility & Yoga', 'details': '30 mins • Recovery', 'focus': 'Flexibility', 'steps': '1. Cat-Cow: 2 mins\n2. Downward Dog: 2 mins\n3. Pigeon Pose: 2 mins/leg'},
        ],
      ];
    } else {
      aiAdvice = 'Premium AI Analysis: To maintain overall health, balance is key. Ensure a micronutrient-rich diet with diverse whole foods.';
      meals = [
        {'type': 'Breakfast', 'name': 'Avocado & Poached Egg Toast', 'calories': '380 kcal', 'macros': 'P: 18g | C: 35g | F: 22g', 'benefit': 'Healthy fats support brain function'},
        {'type': 'Lunch', 'name': 'Mediterranean Chickpea Bowl', 'calories': '520 kcal', 'macros': 'P: 20g | C: 65g | F: 25g', 'benefit': 'High fiber improves gut health'},
        {'type': 'Snack', 'name': 'Mixed Berries & Walnuts', 'calories': '190 kcal', 'macros': 'P: 4g | C: 12g | F: 15g', 'benefit': 'Antioxidants reduce inflammation'},
        {'type': 'Dinner', 'name': 'Tofu & Broccoli Stir Fry', 'calories': '450 kcal', 'macros': 'P: 25g | C: 40g | F: 20g', 'benefit': 'Plant proteins lower cholesterol'},
        if (subscriptionPlan == 'elite') ...[
          {'type': 'Smoothie', 'name': 'Green Detox Smoothie', 'calories': '150 kcal', 'macros': 'P: 5g | C: 25g | F: 2g', 'benefit': 'Micronutrient bomb for longevity'},
          {'type': 'Evening Snack', 'name': 'Dark Chocolate (85%)', 'calories': '120 kcal', 'macros': 'P: 2g | C: 8g | F: 9g', 'benefit': 'Promotes heart health'},
        ],
      ];
      workouts = [
        {'name': 'Vinyasa Yoga Flow', 'details': '45 mins • Recovery', 'focus': 'Mobility & Flexibility', 'steps': '1. Sun Salutations: 10 mins\n2. Warrior Poses: 15 mins\n3. Balancing poses: 10 mins\n4. Savasana: 10 mins'},
        {'name': 'Zone 2 Cardio', 'details': '40 mins • Steady State', 'focus': 'Aerobic Base', 'steps': '1. Warmup: 5 min walk\n2. Moderate jog at 130-140 BPM: 30 mins\n3. Cooldown: 5 min walk'},
        {'name': 'Full Body Kettlebell', 'details': '30 mins • Conditioning', 'focus': 'Functional Strength', 'steps': '1. KB Swings: 4x15\n2. Goblet Squats: 3x12\n3. Turkish Get-ups: 2x5/side'},
        if (subscriptionPlan == 'elite') ...[
          {'name': 'Pilates Core Focus', 'details': '35 mins • Low Impact', 'focus': 'Deep Core', 'steps': '1. The Hundred: 1 set\n2. Roll-ups: 10 reps\n3. Single Leg Stretch: 15/leg'},
          {'name': 'Breathwork & Meditation', 'details': '15 mins • Mental Health', 'focus': 'Stress Reduction', 'steps': '1. Box breathing: 5 mins\n2. Body scan: 5 mins\n3. Gratitude journal: 5 mins'},
        ],
      ];
    }
  }

  void _generateBasicPlans() {
    aiAdvice = 'Basic AI Analysis: Good foundation. Consider upgrading to Pro for macro tracking and personalized advice.';
    if (primaryGoal == 'Lose Weight') {
      meals = [
        {'type': 'Breakfast', 'name': 'Oatmeal & Berries', 'calories': '300 kcal', 'benefit': 'Sustained energy for fat loss'},
        {'type': 'Lunch', 'name': 'Grilled Chicken Salad', 'calories': '450 kcal', 'benefit': 'Lean protein keeps you full'},
        {'type': 'Dinner', 'name': 'Baked Salmon & Asparagus', 'calories': '500 kcal', 'benefit': 'Omega-3s support metabolism'},
      ];
      workouts = [
        {'name': 'HIIT Cardio', 'details': '30 mins • High Intensity', 'steps': '1. Jog: 2 mins\n2. Jumping Jacks: 3x20\n3. Burpees: 3x10'},
        {'name': 'Core & Abs', 'details': '15 mins • Beginner', 'steps': '1. Crunches: 3x20\n2. Plank: 3x30s'},
      ];
    } else if (primaryGoal == 'Build Muscle') {
      meals = [
        {'type': 'Breakfast', 'name': 'Protein Pancakes', 'calories': '500 kcal', 'benefit': 'Jumpstarts muscle protein synthesis'},
        {'type': 'Lunch', 'name': 'Steak & Sweet Potato', 'calories': '700 kcal', 'benefit': 'Dense calories fuel gains'},
        {'type': 'Dinner', 'name': 'Chicken Pasta', 'calories': '650 kcal', 'benefit': 'Restores muscle glycogen'},
      ];
      workouts = [
        {'name': 'Upper Body Strength', 'details': '60 mins • Heavy', 'steps': '1. Pushups: 3x15\n2. DB Press: 3x10\n3. DB Rows: 3x10'},
        {'name': 'Leg Day', 'details': '45 mins • Intense', 'steps': '1. Squats: 4x12\n2. Lunges: 3x10/leg\n3. Calf raises: 3x20'},
      ];
    } else {
      meals = [
        {'type': 'Breakfast', 'name': 'Avocado Toast', 'calories': '350 kcal', 'benefit': 'Healthy fats for daily energy'},
        {'type': 'Lunch', 'name': 'Quinoa Bowl', 'calories': '500 kcal', 'benefit': 'Plant-based fuel and fiber'},
        {'type': 'Dinner', 'name': 'Tofu Stir Fry', 'calories': '400 kcal', 'benefit': 'Light dinner for easy digestion'},
      ];
      workouts = [
        {'name': 'Yoga Flow', 'details': '45 mins • Recovery', 'steps': '1. Downward Dog: 2 mins\n2. Child\'s Pose: 2 mins\n3. Stretching: 15 mins'},
        {'name': 'Light Jogging', 'details': '30 mins • Cardio', 'steps': '1. Walk: 5 mins\n2. Jog: 20 mins\n3. Walk: 5 mins'},
      ];
    }
  }

  void _generateFreePlans() {
    aiAdvice = 'Free Plan: You get basic suggestions. Upgrade to Basic/Pro/Elite for detailed macro tracking and advanced routines.';
    if (primaryGoal == 'Lose Weight') {
      meals = [
        {'type': 'Breakfast', 'name': 'Oatmeal', 'calories': '??? kcal', 'benefit': 'Basic energy source'},
        {'type': 'Lunch', 'name': 'Salad', 'calories': '??? kcal', 'benefit': 'Basic nutrition'},
        {'type': 'Dinner', 'name': 'Chicken', 'calories': '??? kcal', 'benefit': 'Basic protein'},
      ];
      workouts = [{'name': 'Basic Cardio', 'details': '30 mins', 'steps': '1. Jog for 30 minutes'}];
    } else if (primaryGoal == 'Build Muscle') {
      meals = [
        {'type': 'Breakfast', 'name': 'Eggs', 'calories': '??? kcal', 'benefit': 'Basic energy source'},
        {'type': 'Lunch', 'name': 'Steak', 'calories': '??? kcal', 'benefit': 'Basic nutrition'},
        {'type': 'Dinner', 'name': 'Pasta', 'calories': '??? kcal', 'benefit': 'Basic carbs'},
      ];
      workouts = [{'name': 'Basic Strength', 'details': '45 mins', 'steps': '1. Pushups: 3x15\n2. Pullups: 3x5'}];
    } else {
      meals = [
        {'type': 'Breakfast', 'name': 'Toast', 'calories': '??? kcal', 'benefit': 'Basic energy source'},
        {'type': 'Lunch', 'name': 'Sandwich', 'calories': '??? kcal', 'benefit': 'Basic nutrition'},
        {'type': 'Dinner', 'name': 'Stir Fry', 'calories': '??? kcal', 'benefit': 'Basic veggies'},
      ];
      workouts = [{'name': 'Walking', 'details': '30 mins', 'steps': '1. Walk for 30 minutes'}];
    }
  }
}
