import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service class for Nutritionix API integration
/// Provides food search and detailed nutrition information
class NutritionService {
  static const String _baseUrl = 'https://trackapi.nutritionix.com/v2';
  
  // TODO: Replace with your actual API credentials
  // Get free API key from: https://www.nutritionix.com/business/api
  static const String _appId = 'YOUR_APP_ID';
  static const String _apiKey = 'YOUR_API_KEY';

  /// Search for food items by name
  /// Returns a list of matching foods with basic information
  Future<List<Map<String, dynamic>>> searchFood(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/instant?query=${Uri.encodeComponent(query)}'),
        headers: {
          'x-app-id': _appId,
          'x-app-key': _apiKey,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final common = List<Map<String, dynamic>>.from(data['common'] ?? []);
        final branded = List<Map<String, dynamic>>.from(data['branded'] ?? []);
        
        // Combine common and branded foods
        return [...common, ...branded];
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API credentials');
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to search food: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching food: $e');
      rethrow;
    }
  }

  /// Get detailed nutrition information for a specific food
  /// Query format: "1 chicken breast" or "100g rice"
  Future<Map<String, dynamic>?> getNutritionDetails(String foodQuery) async {
    if (foodQuery.isEmpty) {
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/natural/nutrients'),
        headers: {
          'x-app-id': _appId,
          'x-app-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': foodQuery,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['foods'] != null && (data['foods'] as List).isNotEmpty) {
          return data['foods'][0] as Map<String, dynamic>;
        }
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API credentials');
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get nutrition: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting nutrition details: $e');
      rethrow;
    }
    return null;
  }

  /// Get nutrition information for multiple foods at once
  Future<List<Map<String, dynamic>>> getBulkNutrition(List<String> foodQueries) async {
    if (foodQueries.isEmpty) {
      return [];
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/natural/nutrients'),
        headers: {
          'x-app-id': _appId,
          'x-app-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': foodQueries.join(', '),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['foods'] ?? []);
      } else {
        throw Exception('Failed to get bulk nutrition: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting bulk nutrition: $e');
      return [];
    }
  }

  /// Convert API response to app-friendly format
  Map<String, dynamic> formatNutritionData(Map<String, dynamic> apiData) {
    return {
      'name': _capitalize(apiData['food_name'] ?? 'Unknown'),
      'calories': (apiData['nf_calories'] as num?)?.toInt() ?? 0,
      'protein': (apiData['nf_protein'] as num?)?.toDouble() ?? 0.0,
      'carbs': (apiData['nf_total_carbohydrate'] as num?)?.toDouble() ?? 0.0,
      'fats': (apiData['nf_total_fat'] as num?)?.toDouble() ?? 0.0,
      'fiber': (apiData['nf_dietary_fiber'] as num?)?.toDouble() ?? 0.0,
      'sugar': (apiData['nf_sugars'] as num?)?.toDouble() ?? 0.0,
      'sodium': (apiData['nf_sodium'] as num?)?.toDouble() ?? 0.0,
      'cholesterol': (apiData['nf_cholesterol'] as num?)?.toDouble() ?? 0.0,
      'servingQty': apiData['serving_qty'] ?? 1,
      'servingUnit': apiData['serving_unit'] ?? 'serving',
      'servingWeight': (apiData['serving_weight_grams'] as num?)?.toDouble() ?? 0.0,
      'imageUrl': apiData['photo']?['thumb'] ?? '',
      'imageUrlHighRes': apiData['photo']?['highres'] ?? '',
      'brandName': apiData['brand_name'],
    };
  }

  /// Format nutrition data for meal card display
  Map<String, dynamic> formatForMealCard(Map<String, dynamic> nutritionData) {
    final formatted = formatNutritionData(nutritionData);
    
    return {
      'type': 'Custom',
      'name': formatted['name'],
      'calories': '${formatted['calories']} kcal',
      'macros': {
        'protein': formatted['protein'],
        'carbs': formatted['carbs'],
        'fats': formatted['fats'],
      },
      'benefit': _generateBenefit(formatted),
      'servingSize': '${formatted['servingQty']} ${formatted['servingUnit']}',
      'imageUrl': formatted['imageUrl'],
    };
  }

  /// Generate a benefit description based on nutrition data
  String _generateBenefit(Map<String, dynamic> nutrition) {
    final protein = nutrition['protein'] as double;
    final carbs = nutrition['carbs'] as double;
    final fats = nutrition['fats'] as double;
    final fiber = nutrition['fiber'] as double;

    if (protein > 20) {
      return 'High protein content supports muscle growth and repair';
    } else if (fiber > 5) {
      return 'Rich in fiber for digestive health and satiety';
    } else if (carbs > 30) {
      return 'Good source of energy for workouts and daily activities';
    } else if (fats > 15) {
      return 'Healthy fats support hormone production and nutrient absorption';
    } else {
      return 'Balanced nutrition for overall health';
    }
  }

  /// Capitalize first letter of each word
  String _capitalize(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Calculate macros percentage
  Map<String, double> calculateMacroPercentages(Map<String, dynamic> nutrition) {
    final protein = (nutrition['protein'] as num?)?.toDouble() ?? 0.0;
    final carbs = (nutrition['carbs'] as num?)?.toDouble() ?? 0.0;
    final fats = (nutrition['fats'] as num?)?.toDouble() ?? 0.0;

    // Calories from each macro (protein: 4 cal/g, carbs: 4 cal/g, fats: 9 cal/g)
    final proteinCal = protein * 4;
    final carbsCal = carbs * 4;
    final fatsCal = fats * 9;
    final totalCal = proteinCal + carbsCal + fatsCal;

    if (totalCal == 0) {
      return {'protein': 0, 'carbs': 0, 'fats': 0};
    }

    return {
      'protein': (proteinCal / totalCal * 100).roundToDouble(),
      'carbs': (carbsCal / totalCal * 100).roundToDouble(),
      'fats': (fatsCal / totalCal * 100).roundToDouble(),
    };
  }

  /// Check if API credentials are configured
  bool get isConfigured {
    return _appId != 'YOUR_APP_ID' && _apiKey != 'YOUR_API_KEY';
  }

  /// Get mock data for testing when API is not configured
  List<Map<String, dynamic>> getMockSearchResults(String query) {
    return [
      {
        'food_name': 'chicken breast',
        'serving_unit': 'breast',
        'serving_qty': 1,
        'photo': {
          'thumb': 'https://via.placeholder.com/150?text=Chicken',
        },
      },
      {
        'food_name': 'brown rice',
        'serving_unit': 'cup',
        'serving_qty': 1,
        'photo': {
          'thumb': 'https://via.placeholder.com/150?text=Rice',
        },
      },
      {
        'food_name': 'broccoli',
        'serving_unit': 'cup',
        'serving_qty': 1,
        'photo': {
          'thumb': 'https://via.placeholder.com/150?text=Broccoli',
        },
      },
    ];
  }

  /// Get mock nutrition details for testing
  Map<String, dynamic> getMockNutritionDetails(String foodName) {
    return {
      'food_name': foodName,
      'serving_qty': 1,
      'serving_unit': 'serving',
      'serving_weight_grams': 100,
      'nf_calories': 165,
      'nf_total_fat': 3.6,
      'nf_saturated_fat': 1.0,
      'nf_cholesterol': 85,
      'nf_sodium': 74,
      'nf_total_carbohydrate': 0,
      'nf_dietary_fiber': 0,
      'nf_sugars': 0,
      'nf_protein': 31,
      'photo': {
        'thumb': 'https://via.placeholder.com/150?text=$foodName',
        'highres': 'https://via.placeholder.com/400?text=$foodName',
      },
    };
  }
}
