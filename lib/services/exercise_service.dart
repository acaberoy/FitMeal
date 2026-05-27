import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service class for ExerciseDB API integration (via RapidAPI)
/// Provides exercise search and workout suggestions
class ExerciseService {
  static const String _baseUrl = 'https://exercisedb.p.rapidapi.com';
  
  // TODO: Replace with your actual RapidAPI key
  // Get free API key from: https://rapidapi.com/justin-WFnsXH_t6/api/exercisedb
  static const String _apiKey = 'YOUR_RAPIDAPI_KEY';
  static const String _apiHost = 'exercisedb.p.rapidapi.com';

  /// Get all exercises with pagination
  Future<List<Map<String, dynamic>>> getAllExercises({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/exercises?limit=$limit&offset=$offset'),
        headers: {
          'X-RapidAPI-Key': _apiKey,
          'X-RapidAPI-Host': _apiHost,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Invalid API credentials');
      } else {
        throw Exception('Failed to fetch exercises: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching exercises: $e');
      rethrow;
    }
  }

  /// Get exercises by body part
  /// Valid body parts: back, cardio, chest, lower arms, lower legs, neck, shoulders, upper arms, upper legs, waist
  Future<List<Map<String, dynamic>>> getExercisesByBodyPart(String bodyPart) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/exercises/bodyPart/${bodyPart.toLowerCase()}'),
        headers: {
          'X-RapidAPI-Key': _apiKey,
          'X-RapidAPI-Host': _apiHost,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to fetch exercises: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching exercises by body part: $e');
      return [];
    }
  }

  /// Get exercises by target muscle
  /// Examples: abductors, abs, adductors, biceps, calves, cardiovascular system, delts, etc.
  Future<List<Map<String, dynamic>>> getExercisesByTarget(String target) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/exercises/target/${target.toLowerCase()}'),
        headers: {
          'X-RapidAPI-Key': _apiKey,
          'X-RapidAPI-Host': _apiHost,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to fetch exercises: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching exercises by target: $e');
      return [];
    }
  }

  /// Get exercises by equipment
  /// Examples: barbell, dumbbell, cable, body weight, machine, etc.
  Future<List<Map<String, dynamic>>> getExercisesByEquipment(String equipment) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/exercises/equipment/${equipment.toLowerCase()}'),
        headers: {
          'X-RapidAPI-Key': _apiKey,
          'X-RapidAPI-Host': _apiHost,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to fetch exercises: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching exercises by equipment: $e');
      return [];
    }
  }

  /// Get a specific exercise by ID
  Future<Map<String, dynamic>?> getExerciseById(String exerciseId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/exercises/exercise/$exerciseId'),
        headers: {
          'X-RapidAPI-Key': _apiKey,
          'X-RapidAPI-Host': _apiHost,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching exercise by ID: $e');
    }
    return null;
  }

  /// Get list of all available body parts
  Future<List<String>> getBodyPartList() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/exercises/bodyPartList'),
        headers: {
          'X-RapidAPI-Key': _apiKey,
          'X-RapidAPI-Host': _apiHost,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data);
      }
    } catch (e) {
      print('Error fetching body part list: $e');
    }
    return [];
  }

  /// Format exercise data for app use
  Map<String, dynamic> formatExerciseData(Map<String, dynamic> apiData) {
    return {
      'id': apiData['id'] ?? '',
      'name': _capitalize(apiData['name'] ?? 'Unknown Exercise'),
      'bodyPart': _capitalize(apiData['bodyPart'] ?? ''),
      'equipment': _capitalize(apiData['equipment'] ?? 'None'),
      'target': _capitalize(apiData['target'] ?? ''),
      'gifUrl': apiData['gifUrl'] ?? '',
      'instructions': List<String>.from(apiData['instructions'] ?? []),
      'secondaryMuscles': List<String>.from(apiData['secondaryMuscles'] ?? [])
          .map((m) => _capitalize(m))
          .toList(),
    };
  }

  /// Convert exercise data to workout format for FitMeal app
  Map<String, dynamic> convertToWorkoutFormat(Map<String, dynamic> exercise) {
    final formatted = formatExerciseData(exercise);
    
    return {
      'workoutId': formatted['id'],
      'name': formatted['name'],
      'duration': _estimateDuration(formatted['bodyPart']),
      'intensity': _determineIntensity(formatted['equipment']),
      'focus': '${formatted['bodyPart']} - ${formatted['target']}',
      'exercises': [
        {
          'exerciseId': formatted['id'],
          'name': formatted['name'],
          'sets': 3,
          'reps': 12,
          'restTime': 60,
          'instructions': formatted['instructions'].join('\n'),
          'videoUrl': formatted['gifUrl'],
        }
      ],
      'caloriesBurned': _estimateCalories(formatted['bodyPart']),
    };
  }

  /// Generate a workout plan based on goal
  Future<List<Map<String, dynamic>>> generateWorkoutPlan({
    required String goal,
    required String subscriptionTier,
  }) async {
    List<String> bodyParts = [];
    
    // Determine body parts based on goal
    if (goal == 'Build Muscle') {
      bodyParts = ['chest', 'back', 'upper legs', 'shoulders', 'upper arms'];
    } else if (goal == 'Lose Weight') {
      bodyParts = ['cardio', 'waist', 'upper legs', 'lower legs'];
    } else {
      bodyParts = ['cardio', 'chest', 'back', 'upper legs'];
    }

    List<Map<String, dynamic>> workouts = [];

    try {
      for (var bodyPart in bodyParts) {
        final exercises = await getExercisesByBodyPart(bodyPart);
        if (exercises.isNotEmpty) {
          // Take first exercise for each body part
          final exercise = exercises.first;
          workouts.add(convertToWorkoutFormat(exercise));
        }
        
        // Limit workouts based on subscription tier
        if (subscriptionTier == 'free' && workouts.length >= 2) break;
        if (subscriptionTier == 'basic' && workouts.length >= 3) break;
        if (subscriptionTier == 'pro' && workouts.length >= 5) break;
      }
    } catch (e) {
      print('Error generating workout plan: $e');
    }

    return workouts;
  }

  /// Estimate workout duration based on body part
  int _estimateDuration(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'cardio':
        return 30;
      case 'chest':
      case 'back':
        return 45;
      case 'upper legs':
      case 'lower legs':
        return 40;
      case 'shoulders':
      case 'upper arms':
        return 35;
      default:
        return 30;
    }
  }

  /// Determine intensity based on equipment
  String _determineIntensity(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'body weight':
        return 'Moderate';
      case 'barbell':
      case 'dumbbell':
        return 'High';
      case 'cable':
      case 'machine':
        return 'Moderate';
      default:
        return 'Low';
    }
  }

  /// Estimate calories burned
  int _estimateCalories(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'cardio':
        return 400;
      case 'upper legs':
      case 'lower legs':
        return 350;
      case 'chest':
      case 'back':
        return 300;
      default:
        return 250;
    }
  }

  /// Capitalize first letter of each word
  String _capitalize(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Check if API is configured
  bool get isConfigured {
    return _apiKey != 'YOUR_RAPIDAPI_KEY';
  }

  /// Get mock exercises for testing
  List<Map<String, dynamic>> getMockExercises(String bodyPart) {
    return [
      {
        'id': 'mock_001',
        'name': 'Push-ups',
        'bodyPart': 'chest',
        'equipment': 'body weight',
        'target': 'pectorals',
        'gifUrl': 'https://via.placeholder.com/400?text=Push-ups',
        'instructions': [
          'Start in a plank position',
          'Lower your body until chest nearly touches floor',
          'Push back up to starting position',
          'Repeat for desired reps'
        ],
        'secondaryMuscles': ['triceps', 'shoulders'],
      },
      {
        'id': 'mock_002',
        'name': 'Squats',
        'bodyPart': 'upper legs',
        'equipment': 'body weight',
        'target': 'quadriceps',
        'gifUrl': 'https://via.placeholder.com/400?text=Squats',
        'instructions': [
          'Stand with feet shoulder-width apart',
          'Lower your body by bending knees',
          'Keep chest up and back straight',
          'Push through heels to return to start'
        ],
        'secondaryMuscles': ['glutes', 'hamstrings'],
      },
    ];
  }
}
