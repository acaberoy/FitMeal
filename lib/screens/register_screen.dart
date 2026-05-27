import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/user_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter a username';
    if (value.trim().length < 3) return 'Username must be at least 3 characters';
    if (value.contains(' ')) return 'Username cannot contain spaces';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Please enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Must contain at least one uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Must contain at least one number';
    if (!RegExp(r'[!@#\$%\^&\*]').hasMatch(value)) return 'Must contain at least one special character (!@#\$%^&*)';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Check if user already exists
    final existingUser = userProvider.registeredUsers.any(
      (u) => u['username']?.toString().toLowerCase() == username.toLowerCase(),
    );

    if (existingUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Account already exists. Please log in.'),
          ]),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    userProvider.registerUser(username, password: password, email: email);

    setState(() => _isLoading = false);

    // Show success confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
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
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
              child: const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 56),
            ),
            const SizedBox(height: 16),
            const Text('Account Created!', style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Welcome, $username! Let\'s set up your fitness profile.',
              style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '📧 Welcome email sent to $email',
                style: TextStyle(color: AppTheme.primaryColor.withOpacity(0.8), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, '/profile-setup');
              },
              child: const Text('Set Up Profile'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                FadeInDown(
                  child: const Icon(Icons.person_add, size: 80, color: AppTheme.accentColor),
                ),
                const SizedBox(height: 24),
                FadeInUp(
                  child: Text(
                    'Create an Account',
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'Join FitMeal to start your AI-powered journey',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 36),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _buildField(_usernameController, 'Choose a Username', Icons.person, validator: _validateUsername),
                ),
                const SizedBox(height: 14),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: _buildField(_emailController, 'Email Address', Icons.email, validator: _validateEmail, inputType: TextInputType.emailAddress),
                ),
                const SizedBox(height: 14),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: _buildField(_passwordController, 'Create a Password', Icons.lock, validator: _validatePassword, obscure: true),
                ),
                const SizedBox(height: 14),
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: _buildField(_confirmPasswordController, 'Confirm Password', Icons.lock_outline, validator: _validateConfirmPassword, obscure: true),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 650),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Password Requirements:', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('• At least 6 characters', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11)),
                        Text('• One uppercase letter (A-Z)', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11)),
                        Text('• One number (0-9)', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11)),
                        Text('• One special character (!@#\$%^&*)', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Register Now'),
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 800),
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Already have an account? Log in', style: TextStyle(color: AppTheme.primaryColor)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon,
      {String? Function(String?)? validator, bool obscure = false, TextInputType? inputType}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: inputType,
      validator: validator,
      style: const TextStyle(color: AppTheme.textPrimaryColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondaryColor),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        filled: true,
        fillColor: AppTheme.cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent)),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}
