import 'package:flutter/material.dart';
import 'chooserole_screen.dart'; // Ensure correct import
import '../services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isSubmitted = false;

  Future<void> _register() async {
    setState(() => _isSubmitted = true);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response['success']) {
        // Registration successful, navigate to choose role screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChooseRoleScreen()),
        );
      } else {
        // Show error message from the server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Registration failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _isSubmitted ? AutovalidateMode.always : AutovalidateMode.disabled,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildTextField(
                        hint: 'Username or Email',
                        icon: Icons.person_outline,
                        controller: _emailController,
                        validator: (value) => (value == null || value.isEmpty) ? 'Please enter an email' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isPasswordVisible: _isPasswordVisible,
                        onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        controller: _passwordController,
                        validator: (value) => (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        hint: 'Confirm Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isPasswordVisible: _isConfirmPasswordVisible,
                        onVisibilityToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                        controller: _confirmPasswordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please confirm your password';
                          if (value != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                              : const Text('Register', style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildSocialLogin(),
                      const SizedBox(height: 30),
                      _buildLoginText(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      color: Color(0xFF98C9C5),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Updated Back Button (Matching StudentRegistrationScreen)
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: 10),
        const Text(
          'Create an\nAccount',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        const Text('Create your new account', style: TextStyle(fontSize: 16, color: Colors.black54)),
      ],
    ),
  );
}


  Widget _buildTextField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool? isPasswordVisible,
    VoidCallback? onVisibilityToggle,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !(isPasswordVisible ?? false),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ?? false ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[600],
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),  // Outline border color and width
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.blue, width: 2),  // Color of the border when the text field is focused
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),  // Color of the border when not focused
        ),
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        const Text('Or continue with', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(FontAwesomeIcons.facebook, Colors.blue),
            const SizedBox(width: 20),
            _buildSocialButton(FontAwesomeIcons.google, Colors.red),
            const SizedBox(width: 20),
            _buildSocialButton(FontAwesomeIcons.apple, Colors.black),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return CircleAvatar(
      backgroundColor: color,
      radius: 22,
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _buildLoginText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('I Already Have an Account '),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        ),
      ],
    );
  }
}
