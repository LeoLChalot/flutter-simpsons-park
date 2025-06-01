// widgets/forms/form_register_widget.dart
import 'package:amazon_cognito_identity_dart_2/src/cognito_user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simpsons_park/services/auth_service.dart'; // Your AuthService

class FormRegisterWidget extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  final Function(String email)? onRegistrationSuccessNeedsConfirmation;

  const FormRegisterWidget({
    super.key,
    required this.onSwitchToLogin,
    this.onRegistrationSuccessNeedsConfirmation,
  });

  @override
  State<FormRegisterWidget> createState() => _FormRegisterWidgetState();
}

class _FormRegisterWidgetState extends State<FormRegisterWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // For 'name' attribute
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );

      if (success) {
        // Use the new getter from AuthService
        if (!authService.isSignedUpUserConfirmed &&
            widget.onRegistrationSuccessNeedsConfirmation != null) {
          widget.onRegistrationSuccessNeedsConfirmation!(
            _emailController.text.trim(),
          );
        } else if (authService.isSignedUpUserConfirmed) {
          // This case means the user was already confirmed (e.g., re-verified, or auto-confirmed by Cognito setting)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration successful! Please login."),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSwitchToLogin(); // Switch to login form
        }
        // If !success, error message is already handled by listening to authService.errorMessage below
      } else if (mounted) {
        // This 'else' implies signUp returned false
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authService.errorMessage ??
                  "Registration failed. Please try again.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Register',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            // Display error message from AuthService if any
            if (authService.errorMessage != null &&
                !authService.isLoading &&
                authService.cognitoUser ==
                    null /* Only show general errors here */ )
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  authService.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            if (authService.cognitoUser != null &&
                !authService.isSignedUpUserConfirmed &&
                widget.onRegistrationSuccessNeedsConfirmation == null &&
                !authService.isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  "Registration successful! Please check your email (${_emailController.text.trim()}) to confirm your account.",
                  style: const TextStyle(color: Colors.orange, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

            // Specific message for confirmation needed (if not navigating away)
            if (authService.errorMessage != null &&
                authService.errorMessage!.contains('confirm your account'))
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  authService.errorMessage!,
                  style: const TextStyle(color: Colors.orange, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: authService.isLoading ? null : _registerUser,
              child: authService.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Register'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: widget.onSwitchToLogin,
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
