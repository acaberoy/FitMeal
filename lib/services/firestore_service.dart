import 'package:cloud_firestore/cloud_firestore.dart';

/// Service class for all Firestore database operations
/// Handles CRUD operations for users, meal plans, workout plans, and progress tracking
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════
  // USER OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Create a new user document in Firestore
  Future<String> createUser({
    required String username,
    required String passwordHash,
    String role = 'user',
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc();
      
      await userDoc.set({
        'userId': userDoc.id,
        'username': username,
        'passwordHash': passwordHash,
        'role': role,
        'name': '',
        'age': 0,
        'weight': 0.0,
        'height': 0.0,
        'primaryGoal': 'Pending Setup',
        'dietaryRestrictions': '',
        'subscriptionPlan': 'free',
        'subscriptionStartDate': null,
        'subscriptionEndDate': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      return userDoc.id;
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Read user profile by user ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Read user by username (for login)
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user by username: $e');
    }
  }

  /// Update user profile information
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    int? age,
    double? weight,
    double? height,
    String? primaryGoal,
    String? dietaryRestrictions,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (age != null) updateData['age'] = age;
      if (weight != null) updateData['weight'] = weight;
      if (height != null) updateData['height'] = height;
      if (primaryGoal != null) updateData['primaryGoal'] = primaryGoal;
      if (dietaryRestrictions != null) updateData['dietaryRestrictions'] = dietaryRestrictions;

      await _firestore.collection('users').doc(userId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Update user subscription plan
  Future<void> updateSubscription({
    required String userId,
    required String plan,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'subscriptionPlan': plan,
        'subscriptionStartDate': FieldValue.serverTimestamp(),
        'subscriptionEndDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update subscription: $e');
    }
  }

  /// Update last login timestamp
  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to update last login: $e');
    }
  }

  /// Delete user and all associated data
  Future<void> deleteUser(String userId) async {
    try {
      // Delete user document
      await _firestore.collection('users').doc(userId).delete();

      // Delete meal plans
      await _firestore.collection('mealPlans').doc(userId).delete();

      // Delete workout plans
      await _firestore.collection('workoutPlans').doc(userId).delete();

      // Delete achievements
      await _firestore.collection('achievements').doc(userId).delete();

      // Delete progress entries
      final progressDocs = await _firestore
          .collection('userProgress')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in progressDocs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MEAL PLAN OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Create or update meal plan for a user
  Future<void> saveMealPlan({
    required String userId,
    required String goal,
    required String subscriptionTier,
    required List<Map<String, dynamic>> meals,
  }) async {
    try {
      // Calculate total daily calories and macros
      int totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFats = 0;

      for (var meal in meals) {
        totalCalories += (meal['calories'] as num?)?.toInt() ?? 0;
        final macros = meal['macros'] as Map<String, dynamic>?;
        if (macros != null) {
          totalProtein += (macros['protein'] as num?)?.toDouble() ?? 0;
          totalCarbs += (macros['carbs'] as num?)?.toDouble() ?? 0;
          totalFats += (macros['fats'] as num?)?.toDouble() ?? 0;
        }
      }

      await _firestore.collection('mealPlans').doc(userId).set({
        'userId': userId,
        'generatedAt': FieldValue.serverTimestamp(),
        'goal': goal,
        'subscriptionTier': subscriptionTier,
        'meals': meals,
        'totalDailyCalories': totalCalories,
        'totalDailyMacros': {
          'protein': totalProtein,
          'carbs': totalCarbs,
          'fats': totalFats,
        },
      });
    } catch (e) {
      throw Exception('Failed to save meal plan: $e');
    }
  }

  /// Get meal plan for a user
  Future<Map<String, dynamic>?> getMealPlan(String userId) async {
    try {
      final doc = await _firestore.collection('mealPlans').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Failed to get meal plan: $e');
    }
  }

  /// Add a custom meal to user's meal plan
  Future<void> addCustomMeal({
    required String userId,
    required Map<String, dynamic> meal,
  }) async {
    try {
      final doc = await _firestore.collection('mealPlans').doc(userId).get();
      
      if (doc.exists) {
        await doc.reference.update({
          'meals': FieldValue.arrayUnion([meal]),
        });
      } else {
        // Create new meal plan if doesn't exist
        await saveMealPlan(
          userId: userId,
          goal: 'Custom',
          subscriptionTier: 'free',
          meals: [meal],
        );
      }
    } catch (e) {
      throw Exception('Failed to add custom meal: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // WORKOUT PLAN OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Save workout plan for a user
  Future<void> saveWorkoutPlan({
    required String userId,
    required String goal,
    required String subscriptionTier,
    required List<Map<String, dynamic>> workouts,
  }) async {
    try {
      await _firestore.collection('workoutPlans').doc(userId).set({
        'userId': userId,
        'generatedAt': FieldValue.serverTimestamp(),
        'goal': goal,
        'subscriptionTier': subscriptionTier,
        'workouts': workouts,
      });
    } catch (e) {
      throw Exception('Failed to save workout plan: $e');
    }
  }

  /// Get workout plan for a user
  Future<Map<String, dynamic>?> getWorkoutPlan(String userId) async {
    try {
      final doc = await _firestore.collection('workoutPlans').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Failed to get workout plan: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PROGRESS TRACKING OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Log meal completion
  Future<void> completeMeal({
    required String userId,
    required String mealId,
    int? actualCalories,
  }) async {
    try {
      final date = DateTime.now();
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final docId = '${userId}_$dateStr';

      final mealData = {
        'mealId': mealId,
        'completedAt': FieldValue.serverTimestamp(),
        if (actualCalories != null) 'actualCalories': actualCalories,
      };

      final doc = await _firestore.collection('userProgress').doc(docId).get();

      if (doc.exists) {
        await doc.reference.update({
          'completedMeals': FieldValue.arrayUnion([mealData]),
        });
      } else {
        await _firestore.collection('userProgress').doc(docId).set({
          'userId': userId,
          'date': Timestamp.fromDate(date),
          'completedMeals': [mealData],
          'completedWorkouts': [],
          'dailyStats': {},
        });
      }
    } catch (e) {
      throw Exception('Failed to complete meal: $e');
    }
  }

  /// Log workout completion
  Future<void> completeWorkout({
    required String userId,
    required String workoutId,
    required int duration,
    int? caloriesBurned,
  }) async {
    try {
      final date = DateTime.now();
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final docId = '${userId}_$dateStr';

      final workoutData = {
        'workoutId': workoutId,
        'completedAt': FieldValue.serverTimestamp(),
        'duration': duration,
        if (caloriesBurned != null) 'caloriesBurned': caloriesBurned,
      };

      final doc = await _firestore.collection('userProgress').doc(docId).get();

      if (doc.exists) {
        await doc.reference.update({
          'completedWorkouts': FieldValue.arrayUnion([workoutData]),
        });
      } else {
        await _firestore.collection('userProgress').doc(docId).set({
          'userId': userId,
          'date': Timestamp.fromDate(date),
          'completedMeals': [],
          'completedWorkouts': [workoutData],
          'dailyStats': {},
        });
      }
    } catch (e) {
      throw Exception('Failed to complete workout: $e');
    }
  }

  /// Get progress history for a user
  Future<List<Map<String, dynamic>>> getProgressHistory({
    required String userId,
    int days = 7,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final querySnapshot = await _firestore
          .collection('userProgress')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get progress history: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ACHIEVEMENT OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Initialize achievements for a new user
  Future<void> initializeAchievements(String userId) async {
    try {
      await _firestore.collection('achievements').doc(userId).set({
        'userId': userId,
        'badges': [],
        'streaks': {
          'currentStreak': 0,
          'longestStreak': 0,
          'lastActivityDate': null,
        },
        'milestones': {
          'totalMealsCompleted': 0,
          'totalWorkoutsCompleted': 0,
          'totalWeightLost': 0.0,
          'daysActive': 0,
        },
      });
    } catch (e) {
      throw Exception('Failed to initialize achievements: $e');
    }
  }

  /// Add a new badge to user's achievements
  Future<void> addBadge({
    required String userId,
    required Map<String, dynamic> badge,
  }) async {
    try {
      await _firestore.collection('achievements').doc(userId).update({
        'badges': FieldValue.arrayUnion([badge]),
      });
    } catch (e) {
      throw Exception('Failed to add badge: $e');
    }
  }

  /// Get user achievements
  Future<Map<String, dynamic>?> getAchievements(String userId) async {
    try {
      final doc = await _firestore.collection('achievements').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Failed to get achievements: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ADMIN OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Get all users (admin only)
  Future<List<Map<String, dynamic>>> getAllUsers({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'user')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  /// Get all users including admin (for cross-platform sync)
  Future<List<Map<String, dynamic>>> getAllUsersIncludingAdmin() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to get all users including admin: $e');
    }
  }

  /// Log admin action
  Future<void> logAdminAction({
    required String adminId,
    required String action,
    String? targetUserId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _firestore.collection('adminLogs').add({
        'adminId': adminId,
        'action': action,
        'targetUserId': targetUserId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to log admin action: $e');
    }
  }

  /// Get admin logs
  Future<List<Map<String, dynamic>>> getAdminLogs({
    int limit = 100,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('adminLogs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get admin logs: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // REAL-TIME LISTENERS
  // ═══════════════════════════════════════════════════════════════

  /// Listen to user profile changes
  Stream<DocumentSnapshot> watchUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  /// Listen to meal plan changes
  Stream<DocumentSnapshot> watchMealPlan(String userId) {
    return _firestore.collection('mealPlans').doc(userId).snapshots();
  }

  /// Listen to workout plan changes
  Stream<DocumentSnapshot> watchWorkoutPlan(String userId) {
    return _firestore.collection('workoutPlans').doc(userId).snapshots();
  }
}
