import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/user_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedGoal;
  final List<String> goals = ['Lose Weight', 'Build Muscle', 'Maintain Health', 'Increase Endurance'];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _restrictionsController = TextEditingController();
  String? _goalError;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _restrictionsController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) return 'Age is required';
    final age = int.tryParse(value.trim());
    if (age == null) return 'Enter a valid number';
    if (age < 13 || age > 100) return 'Age must be between 13 and 100';
    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) return 'Weight is required';
    final weight = double.tryParse(value.trim());
    if (weight == null) return 'Enter a valid number';
    if (weight < 20 || weight > 300) return 'Weight must be between 20–300 kg';
    return null;
  }

  String? _validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) return 'Height is required';
    final height = double.tryParse(value.trim());
    if (height == null) return 'Enter a valid number';
    if (height < 100 || height > 250) return 'Height must be between 100–250 cm';
    return null;
  }

  void _handleSave() {
    final isFormValid = _formKey.currentState!.validate();
    final isGoalSelected = selectedGoal != null;

    setState(() {
      _goalError = isGoalSelected ? null : 'Please select a fitness goal';
    });

    if (!isFormValid || !isGoalSelected) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.updateProfile(
      newName: _nameController.text.trim(),
      newAge: int.tryParse(_ageController.text.trim()) ?? 25,
      newWeight: double.tryParse(_weightController.text.trim()) ?? 70.0,
      newHeight: double.tryParse(_heightController.text.trim()),
      goal: selectedGoal ?? 'Maintain Health',
      restrictions: _restrictionsController.text.trim(),
    );
    userProvider.generateAIPlans();

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
            const Text('Profile Saved!', style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Your ${selectedGoal} plan is being generated with AI...',
              style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, '/ai-generation');
              },
              child: const Text('View My Plan'),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Setup Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInLeft(
                child: Text(
                  'Personalize Your Plan',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
              const SizedBox(height: 8),
              FadeInLeft(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Tell us about yourself so our AI can craft the perfect meal and fitness plan for you.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 32),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: _buildFormField('Full Name', Icons.person, controller: _nameController, validator: _validateName),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: Row(
                  children: [
                    Expanded(child: _buildFormField('Age', Icons.calendar_today, isNumber: true, controller: _ageController, validator: _validateAge)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildFormField('Weight (kg)', Icons.monitor_weight, isNumber: true, controller: _weightController, validator: _validateWeight)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 550),
                child: _buildFormField('Height (cm)', Icons.height, isNumber: true, controller: _heightController, validator: _validateHeight),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Text('Primary Goal *', style: Theme.of(context).textTheme.bodyLarge),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: goals.map((goal) {
                        final isSelected = selectedGoal == goal;
                        return ChoiceChip(
                          label: Text(goal),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedGoal = selected ? goal : null;
                              _goalError = null;
                            });
                          },
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: AppTheme.cardColor,
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.backgroundColor : AppTheme.textPrimaryColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    if (_goalError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 12),
                        child: Text(_goalError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: _buildFormField('Dietary Restrictions', Icons.warning_amber, hint: 'e.g., Vegan, Gluten-free', controller: _restrictionsController),
              ),
              const SizedBox(height: 48),
              FadeInUp(
                delay: const Duration(milliseconds: 1000),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    child: const Text('Generate AI Plan'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String label, IconData icon,
      {bool isNumber = false, String? hint, TextEditingController? controller, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppTheme.textPrimaryColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppTheme.textSecondaryColor),
        hintStyle: const TextStyle(color: AppTheme.textSecondaryColor),
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
