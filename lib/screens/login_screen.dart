import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter a username';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    return null;
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text;

    // Small delay to show loading state
    await Future.delayed(const Duration(milliseconds: 500));

    // Validate credentials
    final error = userProvider.validateLogin(username, password);
    if (error != null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog(error);
      return;
    }

    // Check if this is the admin account
    final userIndex = userProvider.registeredUsers.indexWhere(
      (u) => u['username']?.toString().toLowerCase() == username,
    );
    final isAdmin = userIndex != -1 && userProvider.registeredUsers[userIndex]['role'] == 'admin';

    if (isAdmin) {
      userProvider.loginAs('admin', username: username);
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else {
      userProvider.loginAs('user', username: username);
      await userProvider.loadUserData(username);
      userProvider.generateAIPlans();
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _showErrorDialog(String message) {
    IconData icon;
    String title;
    if (message.contains('not found')) {
      icon = Icons.person_off;
      title = 'Account Not Found';
    } else if (message.contains('password') || message.contains('Incorrect')) {
      icon = Icons.lock;
      title = 'Wrong Password';
    } else {
      icon = Icons.error_outline;
      title = 'Login Error';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent.withOpacity(0.1)),
              child: Icon(icon, color: Colors.redAccent, size: 44),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: AppTheme.textPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Try Again', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 60),
                FadeInDown(
                  child: const Icon(Icons.fitness_center, size: 80, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 24),
                FadeInUp(
                  child: Text(
                    'Welcome to FitMeal',
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'Login to access your personalized health AI',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: TextFormField(
                    controller: _usernameController,
                    validator: _validateUsername,
                    style: const TextStyle(color: AppTheme.textPrimaryColor),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      labelStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                      hintStyle: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                      prefixIcon: const Icon(Icons.person, color: AppTheme.primaryColor),
                      filled: true,
                      fillColor: AppTheme.cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent)),
                      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: TextFormField(
                    controller: _passwordController,
                    validator: _validatePassword,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppTheme.textPrimaryColor),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                      prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryColor),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondaryColor),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: AppTheme.cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent)),
                      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent)),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                    child: const Text('Don\'t have an account? Register', style: TextStyle(color: AppTheme.primaryColor)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
