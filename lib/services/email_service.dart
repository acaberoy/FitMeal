import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Service class for Email Notifications via EmailJS REST API
/// Sends welcome emails on registration and plan summary emails
class EmailService {
  // ─── EmailJS Configuration ───
  // Get free account from: https://www.emailjs.com/
  // 1. Create an account → Add Email Service (Gmail, Outlook, etc.)
  // 2. Create an Email Template with variables: {{to_email}}, {{to_name}}, {{message}}
  // 3. Copy your Service ID, Template ID, and Public Key below
  static const String _serviceId = 'YOUR_SERVICE_ID';
  static const String _templateId = 'YOUR_TEMPLATE_ID';
  static const String _publicKey = 'YOUR_PUBLIC_KEY';
  static const String _apiUrl = 'https://api.emailjs.com/api/v1.6/email/send';

  /// Check if EmailJS credentials are configured
  bool get isConfigured =>
      _serviceId != 'YOUR_SERVICE_ID' &&
      _templateId != 'YOUR_TEMPLATE_ID' &&
      _publicKey != 'YOUR_PUBLIC_KEY';

  /// Send a welcome email when a new user registers
  /// Returns true on success, false on failure
  Future<bool> sendWelcomeEmail({
    required String toEmail,
    required String username,
  }) async {
    final message = '''
Welcome to FitMeal AI, $username! 🎉

Your account has been created successfully. Here's what you can do:

✅ Set up your fitness profile
✅ Get AI-generated meal & workout plans
✅ Track your daily progress
✅ Earn achievement badges

Log in now to start your personalized fitness journey!

— The FitMeal AI Team
''';

    return _sendEmail(
      toEmail: toEmail,
      toName: username,
      subject: 'Welcome to FitMeal AI! 🏋️',
      message: message,
    );
  }

  /// Send a plan summary email after AI plan generation
  /// Returns true on success, false on failure
  Future<bool> sendPlanSummaryEmail({
    required String toEmail,
    required String username,
    required String goal,
    required int mealCount,
    required int workoutCount,
    required String subscriptionPlan,
  }) async {
    final message = '''
Hi $username! Your personalized plan is ready! 📋

🎯 Goal: $goal
📊 Subscription: ${subscriptionPlan.toUpperCase()}
🍽️ Meals Generated: $mealCount meals/day
💪 Workouts Generated: $workoutCount routines

Your AI-powered fitness plan has been tailored to your profile.
Open the app to start tracking your progress today!

— The FitMeal AI Team
''';

    return _sendEmail(
      toEmail: toEmail,
      toName: username,
      subject: 'Your FitMeal AI Plan is Ready! 📋',
      message: message,
    );
  }

  /// Core method to send email via EmailJS REST API
  /// Uses POST request with JSON body
  Future<bool> _sendEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String message,
  }) async {
    // If credentials aren't configured, use mock response
    if (!isConfigured) {
      debugPrint('📧 [MOCK] Email notification:');
      debugPrint('   To: $toEmail ($toName)');
      debugPrint('   Subject: $subject');
      debugPrint('   Status: Simulated (configure EmailJS credentials for real delivery)');
      return true; // Return success for demo purposes
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost', // Required by EmailJS
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': toEmail,
            'to_name': toName,
            'subject': subject,
            'message': message,
          },
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        debugPrint('✅ Email sent successfully to $toEmail');
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('❌ Email failed: Invalid EmailJS credentials');
        return false;
      } else {
        debugPrint('❌ Email failed: HTTP ${response.statusCode} — ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Email failed: $e');
      return false;
    }
  }

  /// Get mock email log for testing/demo purposes
  /// Returns a list of simulated sent emails
  List<Map<String, String>> getMockEmailLog() {
    return [
      {
        'to': 'user@example.com',
        'subject': 'Welcome to FitMeal AI! 🏋️',
        'status': 'Delivered',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'to': 'user@example.com',
        'subject': 'Your FitMeal AI Plan is Ready! 📋',
        'status': 'Delivered',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      },
    ];
  }
}
